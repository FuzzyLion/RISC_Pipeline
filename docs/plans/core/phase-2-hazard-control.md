# 阶段 2：Hazard Unit 与控制闭环

## Time Limit

建议用时：1 到 1.5 周  
硬上限：2 周

## 目标

让流水线在常见数据相关和控制相关场景下行为正确，并形成稳定的控制优先级规则。

## 关键决策

1. 分支在 `EX` 阶段判定，因此 flush 范围按这一策略设计。
2. 存储访问不是默认 1 周期完成，因此内存侧等待也要纳入 stall 设计。
3. 当前第一版 load-use hazard 按教材方案处理：冻结 Fetch 和 Decode，清空 Execute pipeline register，在 EX 插入一个 bubble。

## 详细任务

### 任务 1：完成数据相关处理

1. 实现 forwarding 路径。
2. 实现 load-use hazard 的 stall。

### 任务 2：完成控制相关处理

1. 实现 branch/jump 触发的 flush。
2. 与 `EX` 阶段 redirect 行为对齐 flush 规则。

### 任务 3：完成握手式访存带来的挂起控制

1. 引入内存等待导致的流水线挂起控制。
2. 区分数据相关 stall 和 memory wait stall。

### 任务 4：统一优先级规则

1. 明确 `stall`、`flush`、`redirect`、`memory_wait` 的优先级关系。
2. 将冒险控制集中为独立模块或清晰的控制单元。

## 当前控制语义约定

这一节记录当前 datapath 图和 pipeline register RTL 已经采用的约定。

### Load-use hazard

判定条件按第一版 RV32I load-use 规则：

```systemverilog
lw_stall = result_src_E_is_load &&
           ((rd_idx_E == rs1_idx_D) || (rd_idx_E == rs2_idx_D)) &&
           (rd_idx_E != 5'd0);
```

这里 `result_src_E_is_load` 可以用 `result_src_E == MEM_RESULT_ENCODING` 表达，也可以后续单独引入 `mem_read_E`。如果只用 `result_src_E`，必须保证编码稳定，不要让 hazard unit 和 control unit 对 load 的判断不一致。

当 `lw_stall=1` 时，动作是：

1. `stall_F = 1`
   PC 保持，不取下一条新指令。
2. `stall_D = 1`
   `IF/ID` 保持，让 dependent instruction 留在 Decode。
3. `flush_E = 1`
   `ID/EX` 清空，让 Execute 下一拍看到 bubble。

这不是把已经在 EX 的 load 清掉。load 会正常前进到 MEM；被清掉的是原本要从 Decode 进入 Execute 的 dependent instruction。

### Branch and jump redirect

Branch/jump 当前在 EX 阶段决定 redirect。推荐 PC 选择语义：

```systemverilog
pc_src_E = jump_E || (branch_E && branch_taken_E);
```

当 `pc_src_E=1` 时，应冲刷流水线中比 EX 更年轻的错误路径指令。按当前五级结构，通常至少需要：

1. `flush_D = 1`
   清掉 `IF/ID` 中的错误路径指令。
2. `flush_E = 1`
   清掉 `ID/EX` 中的错误路径指令。

当前阶段不要 flush `EX/MEM` 里的 branch/jump 本身，因为那是已经完成 redirect 判定的较老指令。

### Forwarding order and store data

Forwarding 目标是得到 EX 阶段真实的寄存器操作数。当前建议保留两路选择：

1. `forward_AE`
   选择 `rs1_val_E`、`alu_result_M` 或 `result_W`
2. `forward_BE`
   选择 `rs2_val_E`、`alu_result_M` 或 `result_W`

ALU B 输入的顺序应是：先 forwarding 得到真实 `rs2`，再由 `alu_src_E` 在 forwarded `rs2` 和 `imm_E` 之间选择。Store 写入数据 `write_data_E` 应来自 forwarded `rs2`，不能来自 `src_B_E`，否则 `sw` 会在 `alu_src_E=1` 时错误地把 immediate 当成 store data。

### Valid gating

Hazard unit 可以根据寄存器编号和控制字段产生 stall/flush，但真正架构副作用仍应由各级 `valid` 门控：

```systemverilog
mem_write_real_M = valid_M && mem_write_M;
rf_write_real_W  = valid_W && rf_write_W;
```

Bubble 的统一语义是 `valid=0`，下游不得因为 bubble 写寄存器、写数据存储器、提交 redirect 或提交未来 trap 副作用。

### Future memory wait

当前按教材先实现基础 load-use 和 branch/jump hazard，`EX/MEM`、`MEM/WB` 可以暂时不带 stall。后续接入 data memory handshake、Cache miss 或慢速外设时，memory wait 不能只冻结 Fetch/Decode；它可能需要冻结更深的 pipeline register，防止 MEM/WB 错位推进。

后续扩展时要重新定义：

1. memory wait 时哪些 pipeline register hold
2. memory wait 与 branch redirect 谁优先
3. memory wait 与 load-use stall 同时出现时谁负责插 bubble
4. 被 hold 的 store/load 如何避免重复提交或丢失响应

## 建议尽早接入的测试

1. 自写 RAW、load-use、branch 专项测试。
2. `riscv-tests` 中适合 `RV32I` 的基础指令测试。
3. 覆盖错误路径冲刷的分支场景。

## 阶段产出

1. Hazard Unit RTL。
2. 冒险控制规则表。
3. 专项测试集合。
4. 基础 `riscv-tests` 适配记录。
5. 优先级时序说明。

## 验证要求

1. Forwarding 选择正确。
2. 气泡插入与暂停行为正确。
3. 错误路径指令能被正确冲刷。
4. 存储侧握手等待时，流水线不会错误前进。

## 风险与注意点

1. 很多 bug 不在 forwarding 本身，而在优先级冲突。
2. `memory_wait` 一旦处理不干净，后续接 Cache 时会重复踩坑。
3. 本阶段就应该开始用 `riscv-tests` 替代一部分手写样例。

## 退出条件

1. 常见 hazard 场景已形成稳定闭环。
2. CPU 可以通过一批基础程序和部分 `riscv-tests`。
3. 可以进入系统化验证阶段。

--
### Attachment:

Situation                         stall_F  stall_D  flush_D  flush_E  forward_AE / forward_BE

No hazard                         0        0        0        0        normal
RAW from MEM ALU result           0        0        0        0        select MEM when rs matches
RAW from WB result                0        0        0        0        select WB when rs matches
Load-use: E load feeds D          1        1        0        1        normal this cycle
Taken branch or jump in EX        0        0        1        1        computed normally
