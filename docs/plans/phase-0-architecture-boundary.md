# 阶段 0：第一版架构边界

## 目标

在写大量 RTL 之前，先把第一版 CPU 的边界、模块划分和关键接口冻结下来，避免后续反复返工。

## 本阶段固定决策

1. 第一版 ISA 固定为 `RV32I`。
2. `branch` 和 `jump` 的最终跳转判定放在 `EX` 阶段。
3. 指令侧和数据侧接口采用极简握手式解耦接口。
4. 第一版只支持最小 Machine Mode 闭环，不在本阶段引入 `M`、`F`、Cache。

## 建议任务

1. 列出第一版必须支持的指令集合。
2. 固定顶层模块划分：
   `pc`、`if_stage`、`id_stage`、`ex_stage`、`mem_stage`、`wb_stage`、`regfile`、`alu`、`controller`、`hazard_unit`。
3. 梳理每级流水线寄存器需要携带的数据信号和控制信号。
4. 定义 `IF` 和 `MEM` 使用的极简存储接口信号。
5. 约定 stall、flush、redirect 的优先级。
6. 画出顶层架构图和关键控制流图。

## 推荐接口方向

建议第一版接口至少包含：

1. `req_valid`
2. `req_ready`
3. `req_addr`
4. `req_wdata`
5. `req_wstrb`
6. `resp_valid`
7. `resp_rdata`

## 阶段产出

1. 指令支持列表。
2. 模块划分说明。
3. 流水线寄存器信号表。
4. 极简总线接口说明。
5. `branch` 在 `EX` 阶段判定的控制策略说明。

## 退出条件

1. 第一版功能边界已经明确。
2. 模块接口和关键控制策略不再频繁变动。
3. 可以在不继续争论架构的情况下开始写 CPU 主体 RTL。
Viewed initial.md:1-75
Viewed requirements.md:1-252
Viewed implementation_steps.md:1-246

这份由三篇文档（`initial.md`, `requirements.md`, `implementation_steps.md`）组成的前置规划非常成熟且务实。从文档中可以看出，你已经深刻认识到了 CPU 开发中最大的陷阱——**“特性蔓延（Scope Creep）”**和**“验证后置”**，并做出了极佳的防范规划。

以下我从架构设计、工程化和验证三个维度提供一份 Review 和建议，希望能帮你把这份计划打磨得更加无懈可击：

### 🌟 整体评价：极佳的工程视角
1. **边界清晰**：明确把 Cache、FPU 等高级特性排除在 V1 之外，聚焦于最核心的流水线数据通路和控制逻辑，这能极大提高项目一次成功的概率。
2. **验证前置**：明确要求验证环境（testbench、回归测试）与实现同步推进，这是芯片设计的黄金法则。
3. **软硬件协同思维**：提到了通过编译器（riscv64-elf-gcc/binutils）和 RTOS bring-up 的规划，说明你在考虑系统级验证，而不仅仅是模块级波形。

---

### 💡 核心建议与潜在优化点

#### 1. 架构级：强烈建议规范化总线接口（哪怕是极简版）
在 `implementation_steps.md` 的**阶段 0**，你提到了“决定存储接口形式”。
* **建议**：在此阶段，哪怕你后端连接的是直接发出的 BRAM（Block RAM），在流水线的 `IF` (取指) 和 `MEM` (访存) 阶段与存储器之间，也**强烈建议采用带握手信号的标准接口（如极简版的 AXI4-Lite 或 Wishbone）**，即包含 `valid`, `ready`, `addr`, `wdata`, `rdata` 信号。
* **原因**：如果让流水线默认假设“访存总是 1 周期返回”，后续在**阶段 5 (SoC集成)** 时接入 UART（低速）、Timer，或者**未来**接入 Cache 时，你需要将整个流水的 stall 逻辑全部推翻重构。使用 `valid-ready` 握手，流水线天然就具备了挂起（stall_from_memory）的能力，后续的 SoC 扩展将如丝般顺滑。

#### 2. 架构级：提早敲定分支跳转（Branch）的判定阶段
在 `requirements.md` 的 Hazard 处理和 `implementation_steps.md` 这块：
* **建议**：在**阶段 0** 的架构草图中，明确约定 `Branch` 指令在 **ID (译码) 阶段** 还是 **EX (执行) 阶段** 进行条件判定和跳转。
* **原因**：
  * **在 ID 判定**：分支惩罚小（1周期），但会带来时序瓶颈（增加比较器的组合逻辑延迟），且需要额外的一条直接由 WB 旁路到 ID 阶段比较器的 Forwarding 路径。
  * **在 EX 判定**：时序好，但分支惩罚大（2周期）。
  * 提前做决定，可以直接指导你的 Hazard Unit 如何编写冲刷（Flush）逻辑。通常建议初版在一期为了追求时序和简单，放在 **EX阶段** 判定即可。

#### 3. 验证级：考虑引入现代化验证框架 (如 Cocotb)
在 `requirements.md` 第 8 节环境要求提到了 `verilator`。
* **建议**：在**阶段 3 (建立验证环境)** 时，建议采用 **[Cocotb](https://github.com/cocotb/cocotb)** + Icarus Verilog/Verilator 的组合。
* **原因**：用纯 Verilog 写复杂的 Testbench（如解析二进制指令文件、自动化对比寄存器状态、提取 PC 覆盖率）非常枯燥且容易出错。Cocotb 允许你用 Python 写测试激励，你可以直接用 Python 的强大生态库去自动生成由 `riscv-elf-gcc` 编译出的验证向量，开发效率至少提升一倍。

#### 4. 验证级：“官方测试集”可以更早介入
* **规划中写道**：在**阶段 6** 才接入更完整的 RISC-V 标准测试集。
* **建议**：RISC-V 官方维护了 [riscv-tests](https://github.com/riscv-software-src/riscv-tests) 的汇编测试集合（专门包含 `rv32ui-p-*` 等子集，按单条指令如 `add`、`bge` 进行边缘情况测试）。这些测试非常标准化。可以在**阶段 2 / 3** 验证基本流水和 Hazard 时，直接利用工具链将其编译为 `.hex` 文件输入你的 `iram` 进行模块级验证。这比你自己手写汇编程序的覆盖率高得多，且容易排雷。

#### 5. 工程级：提前规范目录结构规范
虽然文档里没有体现物理目录，但在落地写第一行代码前（即现在的当务之急），建议明确目录结构。比如：
```text
RISC_Pipeline/
├── docs/      # 文档 (你现在的md文件)
├── rtl/       # CPU 核心硬件代码
│   ├── core/  # IF, ID, EX, MEM, WB 等流水线模块代码
│   └── soc/   # 后续引入的 UART, Timer, 顶层集成
├── sim/       # 仿真相关的 Makefile / 脚本
├── tb/        # 所有的 Testbenches
├── software/  # 包含所有的测试 C/Assembly 程序及编译脚本
└── fpga/      # 给 Vivado (Nexys Artix-7) 的板级工程及约束文件 (.xdc)
```
清晰的工程目录能让文件不会马上随着迭代变得臃肿混乱，并为之后接入 CI 铺平道路。

---

### 🚀 下一步可执行的 Action

根据你的 `implementation_steps.md`，目前的**阶段 0**是最关键的一步。由于环境已经配好，我们接下来的实质性工作应该是：

1. **确立目录结构**：创建上面建议的工程文件夹。
2. **输出架构草图和接口文档**：定义出流水线五个关键 `.v` 文件及其顶层的端口 (Ports)，输出类似于 `pipeline_interface.md` 的规范。特别是流水线寄存器 (Pipeline Registers) 穿行的具体信号包含什么。
3. **完成最基础工程骨架的搭建**：哪怕文件里全是空的 `module ... endmodule`。

你希望我们从哪个部分开始落地编写？是先**建立目录及其骨架文件**，还是先**详细梳理 Stage 0 要求的各层级确切接口信号定义**？我们随时可以开工！