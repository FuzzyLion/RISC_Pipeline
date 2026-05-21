# Phase 1 前准备整理稿

这份文档把当前关于 `Phase 1` 开工前准备的讨论整理成一版更干净的启动稿。

目标不是一次把所有设计完全定死，而是先冻结下面三样最关键的东西：

1. 最小指令子集名单
2. decode 控制信号词汇表与首版控制表
3. 四级流水线寄存器字段表

同时把一个很容易混淆的点单独拆开：

1. pipeline register 的字段
2. pipeline register 的控制动作

这两者不要混在一起写。

---

## 1. 最小 bring-up 指令子集

当前建议第一批冻结为：

1. `add`
2. `sub`
3. `addi`
4. `or`
5. `lw`
6. `sw`
7. `beq`
8. `jal`
9. `jalr`
10. `lui`

这样选的原因：

1. `add/sub/addi/or` 足够支撑最小算术与寄存器路径验证
2. `lw/sw` 足够打通最小数据存储访问
3. `beq/jal/jalr` 足够打通第一版控制流重定向
4. `lui` 能明显降低常量和地址构造的摩擦

暂不纳入第一批 bring-up 的内容：

1. `lb/lh/lbu/lhu/sb/sh`
2. `auipc`
3. CSR 相关指令
4. 乘除法、FPU、预测、rename

其中 `lb/lh/...` 不应被视为“顺手就有”的功能，它们会新增：

1. byte lane 选择
2. 符号扩展或零扩展
3. `wstrb` 生成

---

## 2. 指令语义速记

这一部分只是把第一批指令的行为写清楚，方便后面检查 decode 表和 datapath。

1. `add`
   `rd <- rs1 + rs2`
2. `sub`
   `rd <- rs1 - rs2`
3. `addi`
   `rd <- rs1 + imm`
4. `or`
   `rd <- rs1 | rs2`
5. `lw`
   `rd <- Mem[rs1 + imm]`
6. `sw`
   `Mem[rs1 + imm] <- rs2`
7. `beq`
   `if (rs1 == rs2) pc <- pc + imm`
8. `jal`
   `rd <- pc + 4, pc <- pc + imm`
9. `jalr`
   `rd <- pc + 4, pc <- (rs1 + imm) & ~1`
10. `lui`
    `rd <- imm << 12`

---

## 3. 首版 decode 控制信号词汇表

建议先固定一组“语义清楚、够用但不过度”的控制信号。

### 3.1 推荐的主控制信号

1. `reg_write`
2. `mem_read`
3. `mem_write`
4. `branch`
5. `jump`
6. `jalr`
7. `alu_src`
8. `result_sel`
9. `imm_type`
10. `alu_ctrl`

### 3.2 每个信号大致在表达什么

1. `reg_write`
   这条指令最后会不会写回寄存器堆
2. `mem_read`
   这条指令是否发起数据读
3. `mem_write`
   这条指令是否发起数据写
4. `branch`
   这条指令是否属于条件分支
5. `jump`
   这条指令是否属于无条件 redirect
6. `jalr`
   用来区分 `jalr` 和 `jal` 的目标地址生成差异
7. `alu_src`
   ALU 第二操作数来自寄存器还是立即数
8. `result_sel`
   写回数据来自 `ALU`、`MEM`、`PC+4` 还是 `U-imm`
9. `imm_type`
   立即数扩展类型，例如 `I/S/B/U/J`
10. `alu_ctrl`
    ALU 实际执行 `add/sub/or/...`

### 3.3 一个更稳的组织方式

推荐把控制器拆成两层：

1. Main Decoder
   主要看 `opcode`，生成大方向控制信号
2. ALU Decoder
   结合 `opcode/funct3/funct7` 生成 `alu_ctrl`

不要按整条 32-bit 指令字做“大 case 穷举”。

---

## 4. 首版 decode 控制表

下面这张表的目的不是追求编码唯一正确，而是先把“每条指令到底想驱动什么行为”冻结下来。

| Instr | reg_write | mem_read | mem_write | branch | jump | jalr | alu_src | result_sel | imm_type | alu_ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `add`  | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | add |
| `sub`  | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | sub |
| `addi` | 1 | 0 | 0 | 0 | 0 | 0 | imm | alu   | I    | add |
| `or`   | 1 | 0 | 0 | 0 | 0 | 0 | reg | alu   | none | or  |
| `lw`   | 1 | 1 | 0 | 0 | 0 | 0 | imm | mem   | I    | add |
| `sw`   | 0 | 0 | 1 | 0 | 0 | 0 | imm | none  | S    | add |
| `beq`  | 0 | 0 | 0 | 1 | 0 | 0 | reg | none  | B    | sub |
| `jal`  | 1 | 0 | 0 | 0 | 1 | 0 | imm | pc+4  | J    | add |
| `jalr` | 1 | 0 | 0 | 0 | 1 | 1 | imm | pc+4  | I    | add |
| `lui`  | 1 | 0 | 0 | 0 | 0 | 0 | imm | u_imm | U    | pass_b |

说明：

1. `beq` 用 `sub` 或专用比较逻辑都可以，当前表里先把它写成 `sub` 风格，便于统一理解
2. `jal` 的目标地址在实现上是 `pc + imm`
3. `jalr` 除了 `rs1 + imm`，还需要最低位清零
4. `lui` 的 `alu_ctrl=pass_b` 只是表达“结果主要来自 U 型立即数”，实现时也可以不用真的走 ALU

---

## 5. Pipeline Register 字段表

这里的“字段”指的是：某一级阶段间寄存器必须保存的信息。

不要把下面这些东西放进字段表：

1. `stallD`
2. `flushD`
3. `stallE`
4. `flushE`

这些是“如何更新寄存器”的控制输入，不是这条指令随流水线携带的内容。

### 5.1 `IF/ID`

建议首版至少带：

1. `valid`
2. `pc`
3. `instr`

可选：

1. `pc_plus4`

如果 `ID` 很容易本地算出 `pc + 4`，那 `IF/ID` 不一定必须带它。

### 5.2 `ID/EX`

建议首版至少带：

1. `valid`
2. `pc`
3. `pc_plus4`
4. `rs1_val`
5. `rs2_val`
6. `imm`
7. `rs1_idx`
8. `rs2_idx`
9. `rd_idx`
10. `control_bundle`

这里的 `control_bundle` 代表后面 `EX/MEM/WB` 仍然需要的控制信息。

### 5.3 `EX/MEM`

建议首版至少带：

1. `valid`
2. `alu_result`
3. `rs2_val`
4. `rd_idx`
5. `pc_plus4`
6. `control_bundle`

其中：

1. `rs2_val` 是给 `sw` 作为 store data
2. `pc_plus4` 是给 `jal/jalr` 最后写回用

### 5.4 `MEM/WB`

建议首版至少带：

1. `valid`
2. `alu_result`
3. `mem_rdata`
4. `rd_idx`
5. `pc_plus4`
6. `control_bundle`

---

## 6. Control Bundle 不要一包到底

`control_bundle` 的思路是对的，但不要默认四级都携带完全相同的一整包控制。

更自然的做法是：

1. `ID/EX`
   带 `EX`、`MEM`、`WB` 会用到的控制
2. `EX/MEM`
   只带 `MEM`、`WB` 还需要的控制
3. `MEM/WB`
   只带 `WB` 还需要的控制

一个参考拆法：

1. `EX controls`
   `alu_src, alu_ctrl, branch, jump, jalr`
2. `MEM controls`
   `mem_read, mem_write`
3. `WB controls`
   `reg_write, result_sel`

这样做的好处：

1. 语义更清楚
2. 后面做 hazard 和 flush 时更容易检查副作用
3. 不会把无用控制白白带过两三级

---

## 7. Pipeline Register 控制动作语义

这一节和字段表是并列关系，不要混写。

### 7.1 `hold`

当某一级被 `hold` 时：

1. 该阶段间寄存器的所有字段保持不变
2. 不生成新值，不覆盖旧值

例如：

1. `hold IF/ID`
   表示 `valid/pc/instr` 全部保持不变

### 7.2 `flush`

当某一级被 `flush` 时：

1. 下一拍该阶段间寄存器应表现为一个 bubble
2. 最稳妥的定义是：`valid <- 0`
3. 其余字段可以清零，也可以不关心，但实现上最好保持一致风格

### 7.3 `bubble`

建议统一定义为：

1. `valid = 0`
2. 并且下游保证不会因此产生任何架构副作用

也就是说，`valid=0` 时，下游不得：

1. 写寄存器堆
2. 写数据存储器
3. 提交 redirect
4. 提交任何未来 trap 相关副作用

---

## 8. 当前最需要避免的混乱点

1. 不要把 `stage` 和 `pipeline register` 混为一谈
   `if_stage/id_stage/ex_stage/...` 是逻辑级
   `if_id/id_ex/ex_mem/mem_wb` 才是阶段间寄存器
2. 不要把字段和控制动作写在同一张表里
3. 不要让 `control_bundle` 成为一个“名字很方便但内容越来越糊”的黑盒
4. 不要因为 datapath 图上没画 `valid`，就觉得实现里不需要

---

## 9. Phase 1 开工前的最后检查

如果下面几项你都能自己讲顺，Phase 1 就可以比较稳地开始：

1. 你能解释为什么 bring-up 第一批先选这 10 条指令
2. 你能解释每条指令的 `result_sel` 为什么这样选
3. 你能解释 `ID/EX` 为什么必须带 `rs1_val/rs2_val/imm/rd_idx/control`
4. 你能解释为什么 `stall/flush` 不该出现在字段表里
5. 你能解释 `valid=0` 为什么是 bubble 的统一语义

如果后面需要，可以在这份文档基础上继续补：

1. 最小测试程序列表
2. flush / stall / redirect / memory wait 优先级表
3. 具体的模块边界草图

---

## 10. 当前 RTL 命名版 datapath 约定

这一节记录当前手画 datapath 图和 RTL 字段名之间的约定，防止新线程重新讨论同一批细节。

### 10.1 `valid` 的来源与流动

`valid` 是随指令一起穿过流水线的字段，用来表示当前级里是真实指令还是 bubble。它不是从 instruction bit 里解码出来的，也不是 control unit 产生的普通控制信号。

当前第一版取指存储器可以先把 `imem_resp_valid` 在 reset 结束后恒置为 1，然后 Fetch 级接成：

```systemverilog
assign valid_F = imem_resp_valid;
```

如果以后 instruction memory 改成握手式接口、同步 ROM、I-Cache 或总线访问，`valid_F` 应改为来自真实取指响应。必须保持一个不变量：`valid_F=1` 时，`pc_F` 和 `instr_F` 是同一次取指响应对应的一对字段。

当前 instruction memory 是 32-bit word array。`pc_F` 是 byte address，所以取指 index 使用 `pc_F[MEM_ADDR_WIDTH + 1:2]`。在 RV32I-only、未实现 compressed instruction 的阶段，合法取指地址应满足 `pc_F[1:0] == 2'b00`。`jal`/branch immediate 和 `jalr` 目标规则只能保证至少 2-byte aligned；若目标地址为 `...10`，后续异常阶段应将其作为 instruction address misaligned 处理，而不是让 IM 静默截断低两位。

`valid` 在 pipeline register 中按下面路径单独携带：

```text
valid_F -> IF/ID -> valid_D -> ID/EX -> valid_E -> EX/MEM -> valid_M -> MEM/WB -> valid_W
```

### 10.2 `reset` 和 `clk` 的画图规则

`reset` 和 `clk` 是全局时序基础设施，不是随指令流动的 datapath 字段。RTL 里 `PC`、`IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB` 都应接 reset；未来 CSR、Cache FSM、SoC 控制状态机也要接 reset。

在 datapath 主图里不需要把 reset 像普通数据线一样画满全图。推荐在图角落写全局说明：

```text
Global:
clk   -> all sequential modules
reset -> PC, IF/ID, ID/EX, EX/MEM, MEM/WB, future CSR/cache FSMs
```

这样图能保留重点：指令字段和控制字段如何跨级流动。

### 10.3 Pipeline register 当前字段名

当前 RTL 中阶段间寄存器采用以下命名风格：

1. `IF/ID`
   `valid_D, pc_D, instr_D, pc_plus4_D`
2. `ID/EX`
   `valid_E, pc_E, pc_plus4_E, rs1_idx_E, rs2_idx_E, rd_idx_E, rs1_val_E, rs2_val_E, imm_E`
   控制字段包括 `rf_write_E, result_src_E, mem_write_E, jump_E, branch_E, alu_ctrl_E, alu_src_E`
3. `EX/MEM`
   `valid_M, alu_result_M, write_data_M, rd_idx_M, pc_plus4_M`
   控制字段包括 `rf_write_M, result_src_M, mem_write_M`
4. `MEM/WB`
   `valid_W, alu_result_W, mem_rdata_W, rd_idx_W, pc_plus4_W`
   控制字段包括 `rf_write_W, result_src_W`

`imm_D/imm_E` 应是 Decode 阶段已经生成好的 32-bit sign-extended immediate，不是原始 instruction bitfield。`rs1_val/rs2_val` 是 32-bit 寄存器值；`rs1_idx/rs2_idx/rd_idx` 才是 5-bit 寄存器编号。

### 10.4 副作用必须由 `valid` 门控

Pipeline register 可以携带 `rf_write_*`、`mem_write_*` 等控制字段，但真正写寄存器或写数据存储器时，要在 stage 边界用 `valid` 做最终门控：

```systemverilog
assign rf_write_real_W  = valid_W && rf_write_W;
assign mem_write_real_M = valid_M && mem_write_M;
```

这类组合逻辑不要放进 pipeline register 模块里。Pipeline register 只负责保存、清空或保持字段；WB stage、MEM stage 或顶层 datapath 决定这些字段如何产生架构副作用。

### 10.5 WB result mux 编码

`result_src_[D/E/M/W]` 当前保留为 2-bit，第一版建议按下面语义固定：

1. `2'b00`: `alu_result`
2. `2'b01`: `mem_rdata`
3. `2'b10`: `pc_plus4`
4. `2'b11`: 暂时保留，未来可用于 CSR read data 或其他写回来源

Control unit 和 WB mux 必须使用同一套编码。不要只在脑子里记这个约定。

### 10.6 EX 阶段 operand 与 store data

Forwarding 应先得到真实的寄存器操作数，再由 `alu_src_E` 决定 ALU 的 B 输入来自 forwarded `rs2` 还是 `imm_E`。Store 的 `write_data_E` 应来自 forwarded `rs2`，不能来自 ALU 的 `src_B_E`，因为 store 写入内存的数据不应该被 `alu_src_E` 切换成 immediate。

### 10.7 PC redirect 约定

当前图中 `pc_src_E` 表示 EX 阶段决定下一拍 PC 是否 redirect。推荐语义是：

```systemverilog
assign pc_src_E = jump_E || (branch_E && branch_taken_E);
```

第一版如果只实现 `beq`，`branch_taken_E` 可以来自相等比较；后续支持更多 branch 类型时，不要把 `alu_zero_E` 误当成所有 branch 的统一条件。
