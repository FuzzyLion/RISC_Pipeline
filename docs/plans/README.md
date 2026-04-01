# 分阶段实施计划总览

本目录存放项目的详细阶段计划。根目录下的 [implementation_steps.md](../../implementation_steps.md) 只保留简洁索引，这里才是实际开发时逐阶段查看的主文档集合。

## 阶段列表

1. [阶段 0：第一版架构边界](phase-0-architecture-boundary.md)
2. [阶段 1：五级流水线 CPU 主体](phase-1-pipeline-core.md)
3. [阶段 2：Hazard Unit 与控制闭环](phase-2-hazard-control.md)
4. [阶段 3：系统化验证环境](phase-3-verification.md)
5. [阶段 4：CSR、异常与中断](phase-4-csr-exception-interrupt.md)
6. [阶段 5：SoC 集成与 FPGA 上板](phase-5-soc-fpga.md)
7. [阶段 6：标准测试、RTOS 与增强项](phase-6-system-tests-rtos.md)

## 当前全局原则

1. 第一版范围固定为 `RV32I`。
2. `branch` 第一版在 `EX` 阶段判定。
3. 存储接口采用极简握手式接口。
4. `riscv-tests` 在阶段 2 和阶段 3 就开始接入。
5. 验证与实现必须同步推进。

## 每阶段统一产出

1. 本阶段目标。
2. 已实现模块或已完成设计。
3. 已运行测试。
4. 遗留问题列表。
5. 下一阶段入口条件。
