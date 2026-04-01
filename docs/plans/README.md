# 分阶段实施计划总览

本目录存放项目的详细阶段计划。根目录下的 [implementation_steps.md](../../implementation_steps.md) 只保留简洁索引，这里才是实际开发时逐阶段查看的主文档集合。

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

1. 本阶段目标。
2. Time Limit。
3. 已实现模块或已完成设计。
4. 已运行测试。
5. 遗留问题列表或风险点。
6. 下一阶段入口条件。
