# RISC-V 五级流水线处理器实现步骤索引

## 1. 文档目的

本文档只保留实施总览和阶段索引，方便开发时快速定位当前阶段。

详细阶段计划已经拆分到 `docs/plans/` 目录下，每次开发时只需要打开当前阶段对应的计划文件即可。

## 2. 当前已固定的关键决策

1. 第一版目标 ISA 为 `RV32I`。
2. 第一版 `branch` 在 `EX` 阶段判定。
3. 指令和数据存储接口采用极简握手式解耦接口，而不是写死 1 周期返回。
4. `riscv-tests` 会在阶段 2 和阶段 3 就逐步接入，而不是拖到项目最后。
5. 项目目录结构已固定，详细计划统一放在 `docs/plans/`。

## 3. 阶段索引

1. [阶段总览](docs/plans/README.md)
2. [阶段 0：第一版架构边界](docs/plans/phase-0-architecture-boundary.md)
3. [阶段 1：五级流水线 CPU 主体](docs/plans/phase-1-pipeline-core.md)
4. [阶段 2：Hazard Unit 与控制闭环](docs/plans/phase-2-hazard-control.md)
5. [阶段 3：系统化验证环境](docs/plans/phase-3-verification.md)
6. [阶段 4：CSR、异常与中断](docs/plans/phase-4-csr-exception-interrupt.md)
7. [阶段 5：SoC 集成与 FPGA 上板](docs/plans/phase-5-soc-fpga.md)
8. [阶段 6：标准测试、RTOS 与增强项](docs/plans/phase-6-system-tests-rtos.md)

## 4. 当前使用方式

建议工作流如下：

1. 先读当前阶段计划，明确本阶段目标、任务、产出和退出条件。
2. 本阶段未完成前，不提前并行推进下一个高复杂度阶段。
3. 每完成一个阶段，就补测试记录、问题记录和下一阶段入口条件。

## 5. 当前建议顺序

1. 先完成阶段 0 的架构边界与接口冻结。
2. 再实现阶段 1 的 CPU 主体。
3. 然后完成阶段 2 的 Hazard Unit。
4. 随后推进阶段 3 的验证环境和 `riscv-tests` 接入。
5. 再进入 CSR、SoC、上板和 RTOS。
