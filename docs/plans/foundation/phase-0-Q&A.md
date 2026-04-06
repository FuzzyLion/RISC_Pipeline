# 阶段 0 Q&A 评审与建议

这份文档不是最终规范，而是对你当前回答的整理与评审。  
真正冻结的架构边界以 [phase-0-architecture-boundary.md](phase-0-architecture-boundary.md) 为准。

## 总体评价

你的大方向其实是对的：

1. 先把第一版范围收紧，而不是一上来追求“大而全”
2. 分支先放在 `EX` 判定，优先保证实现可控
3. Cache、CSR、FPU 先不要打乱主线节奏
4. 先把五级流水线、hazard、验证做扎实，再谈后续系统能力

当前最需要补强的不是“原理不懂”，而是以下三点：

1. 把“架构目标”和“最小 bring-up 子集”分开写清楚
2. 把 datapath 图落成真正的信号表和控制规则
3. 把 flush、redirect、exception、memory wait 看成一套统一控制问题

## 任务 1：ISA 与第一版边界

### 1.1 关于“第一版先支持哪些指令”

你现在列的 `add/sub/or/lw/sw/beq/jalr/jal` 作为最小 bring-up 子集是可以理解的，但我建议再补两个点：

1. 强烈建议把 `addi` 提前纳入第一批
2. 最好尽早补 `lui`，`auipc` 视软件需求尽早补

原因很直接：

1. 没有 `addi`，很多最简单的测试程序都会写得很难受
2. 没有 `lui/auipc`，地址和常量构造会很别扭
3. 这些指令不难实现，但能明显降低软件和测试侧摩擦

更稳妥的表达方式是：

1. phase 0 的架构目标固定为 `RV32I`
2. phase 1 的 bring-up 子集先收敛到一组最小可运行指令
3. 后续在 phase 1 到 phase 3 之间逐步补齐完整 `RV32I`

### 1.2 关于“衍生指令是不是和 `lw` 同理”

不是。

`lb/lh/lbu/lhu/sb/sh` 相比 `lw/sw` 真正新增的复杂度在于：

1. 地址低位参与 byte lane 选择
2. 读回数据要做符号扩展或零扩展
3. 写请求要生成不同的 `wstrb`
4. 后面还会碰到未对齐访问和异常语义

所以正确理解应该是：

1. `lw/sw` 可以先独立打通
2. byte/halfword 访存是后续一组明确新增的功能，不是“顺手就有”

### 1.3 关于 CSR

你现在“不急着实现 CSR，只先知道它后面要做”这个判断是合理的。

phase 0 不要求你已经读完 privileged spec，但你最好先知道三件事：

1. phase 4 之前不需要实现完整 CSR
2. phase 0 需要先在文档里冻结 trap/redirect 和 CSR 的边界关系
3. 真正进入 phase 4 前，再去集中读最相关的 privileged spec 章节就够了

换句话说，你现在不是“不会 CSR”，而是“还没到实现 CSR 的阶段”。

## 任务 2：模块划分

### 2.1 `if_stage/id_stage/ex_stage/...` 是不是流水线寄存器

不是。

更准确的区分应该是：

1. `if_stage/id_stage/ex_stage/mem_stage/wb_stage` 是各级逻辑功能
2. `if_id/id_ex/ex_mem/mem_wb` 才是阶段之间的流水线寄存器

这是一个很重要的概念边界。  
如果你把 stage 和 pipeline register 混在一起，后面 stall/flush 会很容易讲不清楚。

### 2.2 “最好预留接口占位”这件事该怎么做

方向是对的，但建议你预留的是“边界”，不是“空壳 RTL”。

更好的做法是：

1. 文档里先写清楚 CSR、Cache、FPU 以后从哪里接入
2. 明确哪些控制信号以后一定会出现
3. 早期 RTL 不必为了占位硬塞一堆空模块

这样既保留扩展性，也不会让第一版骨架变乱。

### 2.3 Cache 和 FPU 将来挂在哪

当前建议非常明确：

1. Cache 挂在 `if_stage` 和 `mem_stage` 对外的存储接口上
2. FPU 挂在 `EX` 附近，译码在 `ID`，写回仲裁在 `WB`

你现在只要先把这两个接入点记住，后面写主线 RTL 时就不会把接口做死。

## 任务 3：流水线寄存器与控制路径

### 3.1 和 3.2 “同如上图”为什么还不够

你的 datapath 图当然有价值，但图不能替代架构决策。

phase 0 真正需要落成文字的是：

1. `IF/ID` 必带哪些字段
2. `ID/EX` 必带哪些字段
3. `EX/MEM` 必带哪些字段
4. `MEM/WB` 必带哪些字段
5. 哪些是 essential，哪些是 derived

如果这些不写清楚，phase 1 很容易出现“信号好像能跑，但总感觉少带了什么”的情况。

### 3.3 关于 stall、flush、redirect、memory wait 的优先级

这里建议你先形成下面这个直觉：

1. trap/interrupt 也是 redirect，只是优先级更高
2. branch redirect 应该高于 load-use stall
3. 来自老指令的 `dmem_wait` 应该高于来自年轻级的普通 redirect
4. `imem_wait` 和 `dmem_wait` 最好不要混成一个模糊的总信号

当前建议优先级是：

1. `reset`
2. `trap_redirect` / `mret_redirect`
3. `dmem_wait`
4. `ex_redirect`
5. `load_use_stall`
6. `imem_wait`
7. 正常推进

这块你后面在 phase 2 还会重新打磨，但 phase 0 就应该先把原则定下来。

## 任务 4：存储接口

### 4.1 你让我补的极简接口

当前建议最少定义为：

1. `req_valid`
2. `req_ready`
3. `req_addr`
4. `req_wdata`
5. `req_wstrb`
6. `resp_valid`
7. `resp_rdata`

同时建议你从文档上先考虑两个可选扩展：

1. `req_size`
2. `resp_err`

接口语义上要写清楚：

1. `req_valid && req_ready` 才算请求被接受
2. 每个端口最多只有一个 outstanding request
3. 响应不乱序
4. `req_wstrb == 0` 表示读，非零表示写
5. 数据侧读写都建议用 `resp_valid` 作为完成确认

### 4.2 关于 branch predictor、register rename 放在哪个 phase

我的建议很直接：

1. branch predictor 不是当前主线必需项
2. 如果以后要做，放在 phase 6 之后作为性能优化支线更合适
3. register rename 不建议纳入当前项目主线

原因是：

1. branch predictor 是性能优化，不是第一版正确性闭环所必需
2. register rename 基本属于乱序或更激进的执行模型，不适合和当前这个“可解释、可验证”的五级顺序流水线主线混在一起

如果你的目标是做一个能讲清楚、能上板、能扩展 Cache/FPU 的项目，那 predictor 可以作为后续可选项，rename 基本可以直接排除。

### 4.3 关于“如何兼容慢速外设和未来 Cache”

核心思想只有一句：

上游 CPU 看到的接口语义不变，下游延迟怎么变化都由 `ready/valid` 去吸收。

也就是说：

1. 对慢速外设来说，只是 `req_ready` 或 `resp_valid` 更晚
2. 对 Cache miss 来说，本质也是“响应变晚了”
3. 只要 phase 0 把握手语义定清楚，phase 5 和 phase 7 就不用推翻 CPU 上层接口

## 任务 5：关键架构策略

### 5.1 你对 `branch` 在 `EX` 处理的理解

你的理解主线是对的，但可以再讲得更严谨一些。

更完整的说法应该是：

1. 在 `ID` 完成 branch/jump 类型译码
2. 在 `EX` 用 ALU 或比较逻辑完成条件判断和目标地址计算
3. `PCSrcE` 不是凭空来的，而是由“这是不是 branch/jump”以及“分支条件是否成立”共同决定
4. `jal` 是无条件 redirect，`jalr` 还要对目标地址最低位清零

也就是说，`ZeroE` 只是 `beq` 这一类分支判断里的一部分信息，不是所有 redirect 的统一解释。

### 5.2 为什么 flush 不只是给 branch 用

这是你现在最值得补上的一个概念点。

flush 的本质不是“branch 专用机制”，而是：

1. 有一条控制流重定向或精确状态修正事件发生时
2. 必须把更年轻、已经走在错误路径上的指令清掉

普通 branch/jump 会触发 flush。  
未来 exception/interrupt 也会触发 flush。

两者差别在于：

1. branch redirect 主要是修正 PC 和错误路径
2. trap redirect 除了修正 PC，还要写 CSR，并保证精确异常语义

所以你可以把它理解成：

1. branch flush 是“普通 redirect 的 flush”
2. trap flush 是“带架构状态副作用的高优先级 redirect”

### 5.3 “如图”为什么还需要写文字说明

图很有帮助，但你最后必须能不用图也说清楚：

1. 哪一级产生 redirect
2. 哪几级会被 flush
3. 哪个阶段的等待会冻结整个流水线
4. 哪些控制信号是跨级传递的

如果你能把这些用语言准确说出来，面试时就不会变成“必须指着图才能解释”。

## 我对你当前 phase 0 的建议总结

1. 不要急着扩充花哨特性，先把 `RV32I` 目标和最小 bring-up 子集分开写清楚。
2. phase 0 最应该补的是“信号表、接口语义、控制优先级”，不是更多原理复述。
3. branch predictor 可以晚很多再考虑，register rename 直接排除出当前主线。
4. 你现在已经够资格开始 phase 1，但前提是先把阶段边界文档写扎实，而不是边写 RTL 边猜控制规则。

---

## 我现在有几个问题想问你：

1. 什么是字段？我在我那张datapath中也没看到类似于 `valid` 等等信号啊？是不是这个字段的意思就是我们在写模块时所用的wire/reg名称？
2. 我想知道，虽然我还没有开始正式开始写，但是如果想让processor完成基础指令最小子集，是不是有一套标准的case语句让control unit去decode？
3. 我知道图上那个大的PipelineReg本质是几个不同的Reg组成的，为了绘画方便虚拟化的大Reg，在实际写的时候，我们的实现方法是按照一整个实现还是一点一点实现（几个Reg分开写）？
4. 我现在既然还不会CSR/Cache的实现，我现在是先读书还是先完成最基础的微架构呢？

## 对这四个问题的直接回答

### 问题 1：什么是“字段”？

这里的“字段”不是一个很神秘的新概念，你可以把它理解成：

1. 某一级流水线寄存器里需要保存的一项信息
2. 如果把一个流水线寄存器看成一个“打包的数据包”，字段就是这个包里的每一项内容

例如 `IF/ID` 流水线寄存器，如果我们说它有三个字段：

1. `valid`
2. `pc`
3. `instr`

那意思就是：`IF/ID` 这一级在时钟边沿更新时，要一起保存这三项东西。

所以你可以这样理解字段和信号的关系：

1. 在架构文档里，“字段”更偏概念层，强调“这一级必须携带哪些信息”
2. 在 RTL 里，它最终会落成具体的 `reg` / `logic` / `wire` 名称

比如你以后可能会这样写：

1. `if_id_valid`
2. `if_id_pc`
3. `if_id_instr`

这三个具体信号，就是 `IF/ID` 这个流水线寄存器的三个字段在 RTL 里的落地形式。

### 为什么 datapath 图里通常看不到 `valid`

因为教材里的 datapath 图往往是“理想化主路径图”，重点是帮助你理解：

1. 指令怎么流
2. ALU 怎么算
3. 寄存器和存储器怎么连

它通常会省略很多工程实现时非常关键、但会把图画得很乱的控制信息，比如：

1. `valid`
2. `stall`
3. `flush`
4. `ready/valid` 握手
5. 错误路径丢弃逻辑

所以不要把“图上没画”理解成“实现里不需要”。

### `valid` 为什么重要

`valid` 的核心作用是区分：

1. 这一拍这个流水级里真的有一条有效指令
2. 这一拍这个流水级里只是一个 bubble

这在以下场景里会非常重要：

1. branch flush 之后插入空泡
2. load-use stall 时冻结某些级，另一些级插 bubble
3. 后面 trap/interrupt 发生时清掉错误路径指令

如果没有 `valid`，你后面会很难把“空泡”和“一条真的指令”区分清楚。

### 问题 2：control unit 有没有“标准 case 语句”？

有“常见写法”，但没有唯一标准答案。

更准确地说：

1. 不存在一份所有人都完全一样照抄的官方 case 模板
2. 但存在一套非常常见、非常合理的 decode 组织方式

最常见的方式是把控制器拆成两层：

1. Main Decoder
   主要看 `opcode`，生成大方向控制信号，例如：
   `reg_write`、`mem_read`、`mem_write`、`branch`、`jump`、`alu_src`、`result_sel`
2. ALU Decoder
   再结合 `opcode`、`funct3`、`funct7`，决定具体 `alu_op`

你的 mental model 应该是：

1. 先根据指令类型判断“这是 R-type、load、store、branch、jal、jalr、lui 还是 addi”
2. 再决定这条指令需要哪些控制信号
3. 再决定 ALU 到底做 `add/sub/or/...`

所以 phase 1 里最好的做法不是追求“有没有标准答案”，而是自己先整理出一张 decode 表。

比如你至少应该先能写出这种表：

1. `add`
   `reg_write=1`，`alu_src=reg`，`result_sel=alu`，`alu_op=add`
2. `lw`
   `reg_write=1`，`mem_read=1`，`alu_src=imm`，`result_sel=mem`，`alu_op=add`
3. `sw`
   `mem_write=1`，`alu_src=imm`，`alu_op=add`
4. `beq`
   `branch=1`，`alu_src=reg`，比较逻辑启用
5. `jal`
   `jump=1`，`reg_write=1`，`result_sel=pc_plus4`

等这张表你自己能写清楚，case 语句只是把表翻译成 RTL。

### 一个很重要的提醒

不要一上来写成“按整条 32-bit 指令字逐个 case”。  
你应该按 RISC-V 编码字段解码：

1. `opcode`
2. `funct3`
3. `funct7`

这才是你后面扩展到完整 `RV32I` 时最自然的结构。

### 问题 3：PipelineReg 实际应该怎么写？

最推荐的实现方式是：

1. 以“阶段间寄存器”为单位组织
2. 在每个阶段间寄存器内部，再保存多个具体字段

也就是说，不建议：

1. 在顶层到处零散写很多互相分散的小寄存器
2. 也不建议一开始就把所有东西粗暴打包成一个看不懂的大位向量

更好的方式是：

1. 写 `if_id_reg`
2. 写 `id_ex_reg`
3. 写 `ex_mem_reg`
4. 写 `mem_wb_reg`

每个模块里有一个时序块，在这个块里统一更新本级所有字段。

你可以把它想成：

1. 架构上，它是“一个阶段间寄存器”
2. RTL 上，它内部包含多个具体字段

这就是“整体建模，字段分别保存”。

### 为什么不建议完全拆碎

因为 stall 和 flush 的语义是对“这一级整体”生效的。

例如：

1. `flush id_ex`
   本质上不是只清一个信号，而是要把 `ID/EX` 这一整拍当成 bubble
2. `hold if_id`
   本质上是整个 `IF/ID` 保持不变

所以从控制角度看，按阶段间寄存器分组最自然。

### 实际 RTL 心智模型

最适合你当前阶段的写法是：

1. 一个阶段间寄存器模块对应一个 `always_ff`
2. 里面有多个字段，例如 `valid/pc/instr/...`
3. `reset`、`flush`、`enable` 的处理放在这个模块里统一做

如果你用的是 SystemVerilog，后面甚至可以用 `struct packed` 来写。  
如果你先用普通 Verilog，也完全没问题，就老老实实写多个寄存器字段。

### 问题 4：现在先读书，还是先做基础微架构？

我的建议是：

1. 现在优先开始基础微架构
2. 对 CSR/Cache 只保持“知道它们将来接在哪、会影响哪些控制边界”的程度
3. 不要在 phase 1 之前把自己拖进 CSR 或 Cache 的实现细节里

原因很简单：

1. 你当前最需要的是把 phase 1 的 datapath 和 phase 2 的控制主线做扎实
2. 如果现在深入读 CSR/Cache 细节，你会很容易被大量还没到实施阶段的复杂度分散注意力
3. 你已经在 phase 0 文档里把它们的接入边界冻结下来了，这就够支撑你进入 phase 1

### 但也不是“完全不看”

更准确的策略是：

1. 微架构主线现在就开工
2. CSR 先只知道 trap 本质上是高优先级 redirect
3. Cache 先只知道 miss 会表现成 memory wait / ready-valid 延迟
4. 等进入对应 phase，再集中读对应资料

这是最符合你当前阶段的学习顺序。

换句话说，你现在最该做的不是“先把未来所有东西都学完”，而是：

1. 把当前阶段需要的东西做扎实
2. 同时保证未来接口没有被你现在写死

## Phase 1 开始前，我建议你再补这几样

如果只说“开始写 RTL”当然也能开始。  
但如果你想让 phase 1 写起来明显更顺，我建议你至少再补下面这些最小准备。

### 必补 1：最小指令子集最终冻结

不要再停留在“差不多这些指令”的状态。  
在正式开写前，把第一批指令明确写成一行最终名单。

我建议你第一批就冻结为：

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

这样你后面写 control unit 时不会来回改边界。

### 必补 2：先写一张 decode 控制表

在写 RTL 前，先手写一张表：

1. 指令名
2. `reg_write`
3. `mem_read`
4. `mem_write`
5. `branch`
6. `jump`
7. `alu_src`
8. `result_sel`
9. `alu_op`

这张表会直接决定你的 controller 怎么写。

### 必补 3：先写一张 pipeline register 字段表

把下面四级都写清楚：

1. `IF/ID`
2. `ID/EX`
3. `EX/MEM`
4. `MEM/WB`

你不一定一次写得非常完美，但要先有第一版。

### 必补 4：先写清楚 flush / stall 的动作语义

至少先回答下面几个问题：

1. `hold if_id` 时，哪些字段保持不变？
2. `flush id_ex` 时，是清零所有字段，还是只清 `valid` 和控制字段？
3. bubble 的定义是什么？
4. `valid=0` 时，下游是否保证不会产生副作用？

这几个问题一旦想清楚，后面 RTL 会顺很多。

### 必补 5：先准备 4 到 6 个最小测试程序

在 phase 1 之前就把最小测试想好，不然很容易写完 RTL 却不知道先怎么验。

我建议至少准备：

1. `addi/add/sub/or` 基础算术程序
2. `lw/sw` 基础访存程序
3. `beq` taken / not taken 程序
4. `jal` 跳转与链接程序
5. `jalr` 返回程序
6. `x0` 不可写测试

## 结论

如果只问“能不能开始 phase 1”，答案是：可以。

但最稳的启动方式不是立刻埋头写 RTL，而是先把下面三张纸补出来：

1. 最小指令子集名单
2. decode 控制表
3. 四级流水线寄存器字段表

你把这三样补完，phase 1 的难度会立刻下降很多。  
而且最重要的是，你会更清楚自己在写什么，而不是一边写一边猜。
