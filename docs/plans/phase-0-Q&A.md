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
