# 分阶段实施计划总览

本目录存放项目的详细阶段计划。  
这里不仅是阶段索引，也作为当前项目规划区的总入口。

## 这个项目要做成什么样，才适合拿去找实习

这个项目真正的价值，不在于“我做了一个 CPU”，而在于你最后能不能把它讲明白、验证明白、取舍讲明白。

如果你想把它作为实习主项目，建议把目标定到下面这个标准。

### 必须达到的硬标准

1. 你能用 3 到 5 分钟清楚讲完整体架构：
   `RV32I`、五级流水、`branch` 在 `EX` 判定、握手式存储接口、Hazard 处理主线。
2. 你能用自己的实现解释一条指令如何从 `IF` 走到 `WB`。
3. 你能说清楚 forwarding、stall、flush 分别解决什么问题。
4. 你有成体系的验证，不是只靠“看起来波形差不多”。
5. 你能讲出至少 2 个亲手定位过的真实 bug。
6. 你能解释为什么第一版不做乱序、rename、predictor，而是先把顺序流水线做扎实。

### 如果做到，会明显加分的项目亮点

1. 通过一批基础 `riscv-tests`
2. 做出最小 CSR、异常、中断闭环
3. 完成最小 SoC 集成
4. 在 NEXYS Artix-7 上板运行
5. 后续成功接入 Cache
6. 后续成功接入 FPU

### 不该追求的“假高含金量”

1. 堆很多高级名词，但讲不清控制和时序
2. 有代码，但没有测试和回归
3. 能跑几个 case，但不知道为什么能跑
4. 过早加入 predictor、rename、复杂总线，反而把主线做散

## 当前最推荐的主线

1. 先做稳 `phase 1` 到 `phase 3`
2. 再做 `phase 4` 到 `phase 6` 的系统闭环
3. 最后推进 Cache、FPU 和 RTOS

换句话说：

1. 五级流水线主体
2. Hazard Unit 与控制优先级
3. 验证闭环

这三块才是项目真正的“含金量地基”。

## 阶段列表

1. [阶段 0：第一版架构边界](phase-0-architecture-boundary.md)
2. [阶段 1：五级流水线 CPU 主体](phase-1-pipeline-core.md)
3. [阶段 2：Hazard Unit 与控制闭环](phase-2-hazard-control.md)
4. [阶段 3：系统化验证环境](phase-3-verification.md)
5. [阶段 4：CSR、异常与中断](phase-4-csr-exception-interrupt.md)
6. [阶段 5：SoC 集成与 FPGA 上板](phase-5-soc-fpga.md)
7. [阶段 6：系统级测试与软件基线](phase-6-system-validation.md)
8. [阶段 7：Cache 设计与集成](phase-7-cache.md)
9. [阶段 8：FPU 设计与集成](phase-8-fpu.md)
10. [阶段 9：RTOS 与最终系统联调](phase-9-rtos-final-integration.md)

## 当前全局原则

1. 第一版范围固定为 `RV32I`。
2. `branch` 第一版在 `EX` 阶段判定。
3. 存储接口采用极简握手式接口。
4. `riscv-tests` 在阶段 2 和阶段 3 就开始接入。
5. Cache 和 FPU 是明确必做项，但必须在主线稳定后分阶段推进。
6. 验证与实现必须同步推进。

## 每阶段统一产出

1. 本阶段目标
2. Time Limit
3. 已实现模块或已完成设计
4. 已运行测试
5. 遗留问题列表或风险点
6. 下一阶段入口条件

## 文档分工建议

当前项目里和规划相关的文档，大致可以这样分工：

1. [README.md](/Users/qi/Documents/RISC_Pipeline/docs/plans/README.md)
   作为规划区首页，负责总览、阶段入口、全局原则和项目目标清单。
2. [phase-0-architecture-boundary.md](/Users/qi/Documents/RISC_Pipeline/docs/plans/phase-0-architecture-boundary.md)
   负责第一版架构边界冻结。
3. 各阶段文档
   负责逐阶段执行计划、产出、验证点和退出条件。
4. [requirements.md](/Users/qi/Documents/RISC_Pipeline/requirements.md)
   更像“项目需求与验收标准”，仍然有保留价值。
5. [initial.md](/Users/qi/Documents/RISC_Pipeline/initial.md)
   目前大部分内容已经被阶段文档和本 README 吸收，重复度较高。
6. [implementation_steps.md](/Users/qi/Documents/RISC_Pipeline/implementation_steps.md)
   目前主要是阶段索引，和本 README 的重叠度也比较高。

## 对根目录那三份文档的建议

### `requirements.md`

建议保留。

原因是它承担的是：

1. 项目范围定义
2. 功能需求
3. 非功能需求
4. 验收标准

这类文档和阶段计划不是一回事。  
阶段文档告诉你“怎么推进”，需求文档告诉你“最终要做到什么程度”。

### `initial.md`

我觉得可以删，或者至少不再继续维护。

原因是：

1. 它的“项目目标、关键决策、主线规划”已经被 phase 文档体系覆盖
2. 它现在更像项目早期 brainstorming 的沉淀
3. 继续保留容易和后续正式文档发生重复

### `implementation_steps.md`

我也倾向于删，前提是你认可本 README 以后就是唯一阶段索引入口。

原因是：

1. 它本质上就是索引页
2. 现在 [README.md](/Users/qi/Documents/RISC_Pipeline/docs/plans/README.md) 已经能承担这个角色
3. 两个索引并存，后面很容易只更新一个

## 我的总体建议

如果你想让文档体系更干净，我建议最后收敛成：

1. 保留 [README.md](/Users/qi/Documents/RISC_Pipeline/docs/plans/README.md) 作为规划总入口
2. 保留各阶段文档作为执行主线
3. 保留 [requirements.md](/Users/qi/Documents/RISC_Pipeline/requirements.md) 作为需求与验收文档
4. 删除 [initial.md](/Users/qi/Documents/RISC_Pipeline/initial.md)
5. 删除 [implementation_steps.md](/Users/qi/Documents/RISC_Pipeline/implementation_steps.md)

这样结构最清晰，也最不容易后续重复维护。
