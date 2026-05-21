# Data Memory 寻址笔记

## 核心混淆点

最重要的一点是：地址不是数据本身。地址只是一个编号，用来定位内存里的数据。

在 RISC-V 里，内存是按 byte 编址的，也就是 byte-addressed。意思是每一个地址值都指向一个 byte 大小的内存位置。一个 byte 是 8 bit，但“指向这个 byte 的地址编号”本身可以是 32 bit 宽，也可以是 64 bit 宽。

所以当我们说 “32-bit byte address” 时，其实是在说两个不同维度的概念：

```text
32-bit address -> 地址编号本身是 32 bit 宽
byte address   -> 每一个地址编号指向 1 byte
```

第一个概念描述“地址编号有多宽”。第二个概念描述“一个地址编号对应多大的内存单位”。它们不是同一件事。

## 一个现实类比

可以把内存想成一排很长的信箱。每个信箱只能放 1 byte，也就是 8 bit。信箱编号就是地址。

```text
Address 0  -> byte[0]
Address 1  -> byte[1]
Address 2  -> byte[2]
Address 3  -> byte[3]
Address 4  -> byte[4]
Address 5  -> byte[5]
Address 6  -> byte[6]
Address 7  -> byte[7]
```

地址只是信箱编号。32-bit address 的意思是“这个信箱编号用 32 bit 表示”，不是“这个信箱里面装了 32 bit”。在 RISC-V 里，每个地址对应的最小内存位置仍然是 1 byte。

## `lw` 实际做了什么

`lw` 的意思是 load word。在 RV32I 和 RV64I 里，一个 word 都是 32 bit，也就是 4 bytes。

如果 CPU 执行：

```asm
lw x5, 4(x0)
```

那么 effective address 是 `4`。因为 RISC-V 是 byte-addressed，所以地址 `4` 指向的是 `byte[4]`。但是 `lw` 并不是只读 1 byte。`lw` 这条指令本身规定要读一个 32-bit word，所以 memory system 会从地址 `4` 开始连续读 4 个 byte。

```text
lw from address 4 reads:

byte[4]
byte[5]
byte[6]
byte[7]
```

这 4 个 byte 会被组合成一个 32-bit value，然后写入目标寄存器。

举一个具体例子。假设内存内容是：

```text
Address 4: 0x78
Address 5: 0x56
Address 6: 0x34
Address 7: 0x12
```

RISC-V 是 little-endian，所以最低地址的 byte 会放到结果的最低 8 bit：

```text
result[7:0]   = memory[4] = 0x78
result[15:8]  = memory[5] = 0x56
result[23:16] = memory[6] = 0x34
result[31:24] = memory[7] = 0x12

loaded word = 32'h12345678
```

所以不是“地址变成了 word”。地址只是选中了起始 byte。真正决定要读 4 个 byte 并组合成 32-bit word 的，是 `lw` 这条指令。

## 为什么要 word alignment

一个 32-bit word 是 4 bytes。自然对齐的 word address，就是能被 4 整除的 byte address。

```text
Address 0  -> aligned word starts at byte[0]
Address 4  -> aligned word starts at byte[4]
Address 8  -> aligned word starts at byte[8]
Address 12 -> aligned word starts at byte[12]
```

在二进制里，能被 4 整除的地址最低两位一定是 0：

```text
0  = ...0000
4  = ...0100
8  = ...1000
12 = ...1100

addr[1:0] == 2'b00
```

对 `lw/sw` 来说，aligned access 意味着 `addr[1:0] == 2'b00`。如果 `addr[1:0]` 不是 0，这就是 misaligned word access。

例如：

```text
lw from address 4 -> reads byte[4..7], aligned
lw from address 5 -> reads byte[5..8], misaligned
```

完整的 RISC-V core 要么在硬件里支持 misaligned access，要么触发 load/store address-misaligned exception。这个项目目前还没做到 exception 阶段，所以早期的 Data Memory 可以先假设测试程序只发出 aligned `lw/sw`，后面到 CSR 和 exception 阶段再补齐异常处理。

## ISA 视角 vs Verilog Memory Model

从 ISA 视角看，内存是 byte-addressed：

```text
memory address 0 -> one byte
memory address 1 -> one byte
memory address 2 -> one byte
memory address 3 -> one byte
memory address 4 -> one byte
```

但是当前的 Verilog Data Memory 是一个 word array：

```systemverilog
logic [31:0] mem [0:255];
```

这表示每个 `mem` entry 已经存了一个 32-bit word，也就是 4 bytes。

```text
mem[0] contains byte addresses 0, 1, 2, 3
mem[1] contains byte addresses 4, 5, 6, 7
mem[2] contains byte addresses 8, 9, 10, 11
mem[3] contains byte addresses 12, 13, 14, 15
```

所以如果 CPU 给出 byte address `8`，对应的 word-array index 不是 `8`，而是 `2`。因为 byte address `8` 属于第三个 32-bit word entry：

```text
word index = byte address / 4
word index = 8 / 4
word index = 2
```

在二进制硬件里，除以 4 等价于右移 2 位：

```text
word index = byte address >> 2
```

这就是为什么 Data Memory 要用 `alu_result_M` 的一部分作为 `word_idx`。

## 为什么是 `alu_result_M[MEM_ADDR_WIDTH+1:2]`

假设：

```systemverilog
parameter int MEM_WORDS = 256;
localparam int MEM_ADDR_WIDTH = $clog2(MEM_WORDS);
```

因为 `MEM_WORDS = 256`，所以这个 memory 有 256 个 word entry。索引 256 个 entry 需要 8 bit：

```text
MEM_ADDR_WIDTH = log2(256) = 8
```

ALU 算出来的 effective address 仍然是 byte address：

```systemverilog
input logic [31:0] alu_result_M;
```

对 `lw/sw` 来说，最低两位表示这个 byte address 在一个 32-bit word 里面的 byte offset：

```text
alu_result_M[1:0] = byte offset inside the word
```

如果是 aligned `lw/sw`，这两位应该是 `00`。接下来的 8 位用来选择 256 个 word entry 里面的一个：

```text
alu_result_M[9:2] = word index
```

可以这样看这个地址：

```text
alu_result_M[31:10]  alu_result_M[9:2]  alu_result_M[1:0]
unused in this model word index         byte offset
```

通用写法是：

```systemverilog
assign word_idx = alu_result_M[MEM_ADDR_WIDTH + 1:2];
```

当 `MEM_ADDR_WIDTH = 8` 时，这句话等价于：

```systemverilog
assign word_idx = alu_result_M[9:2];
```

这句代码同时做了两件事。第一，丢掉最低两位，因为当前的 `mem` 数组每个 entry 已经存了 4 bytes。第二，只保留足够索引当前 memory 大小的位数，也就是 256 entries 需要 8 位 index。

## 为什么不是 `addr * 4`

这个方向很容易反过来。

CPU 给出的是 byte address。Verilog array 需要的是 word index。4 个 byte 合成 1 个 word，所以 word index 比 byte address 更小：

```text
byte address 0  -> word index 0
byte address 4  -> word index 1
byte address 8  -> word index 2
byte address 12 -> word index 3
```

所以转换方向是：

```text
word index = byte address / 4
```

不是：

```text
word index = byte address * 4
```

乘以 4 是反方向。如果你已经有了一个 word index，想知道这个 word 的第一个 byte address，才会乘以 4：

```text
byte address = word index * 4
```

例如，`mem[2]` 的起始 byte address 是 `8`。

## RV64 里是不是 `lw/sw` 读写 8 bytes

不是。RV64 不代表 `lw/sw` 变成 8-byte 操作。RV64 的意思是通用寄存器宽度是 64 bit。一次 memory access 读写多少 byte，是由具体 load/store 指令决定的。

常见 RV64 memory access size 是：

```text
lb / sb -> 1 byte
lh / sh -> 2 bytes
lw / sw -> 4 bytes
ld / sd -> 8 bytes
```

在 RV64 里，`lw` 读 4 bytes，然后把 32-bit 结果 sign-extend 到 64 bit，再写入目标寄存器。`lwu` 也是读 4 bytes，但会 zero-extend 到 64 bit。真正读 8 bytes 的是 `ld`，真正写 8 bytes 的是 `sd`。

alignment 取决于 access size：

```text
lb / sb -> any byte address
lh / sh -> addr[0] == 0
lw / sw -> addr[1:0] == 2'b00
ld / sd -> addr[2:0] == 3'b000
```

所以 register width 和 memory access size 有关系，但不是同一件事。

## 和 Instruction Memory 的关系

Instruction Memory 也是类似的地址逻辑。PC 也是 byte address。普通 RV32I 指令是 32 bit，也就是 4 bytes，所以如果 instruction memory 也建成 word-array，那么取指通常也会写成：

```systemverilog
instr = imem[pc[IMEM_ADDR_WIDTH + 1:2]];
```

原因一样：ISA 视角下地址是 byte address，但简单 Verilog 模型可能是一个 entry 存一条 32-bit instruction。

branch 和 jump immediate 也和 alignment 有关，但不是 Data Memory indexing 的同一件事。RISC-V 的 branch/jump offset 隐含最低 bit 为 0，因为控制流目标至少是 2-byte aligned。`imm_ext` 的工作是从指令编码里还原这个 offset。它和 Data Memory 的 `word_idx` 计算不一样，但背后的共同点是：低地址位经常用来表示 alignment，或者表示一个更大单位内部的位置。

## 当前项目里的规则

对当前这个简单的 `data_mem.sv`，你应该这样记：

```text
RISC-V address from ALU:
32-bit byte address

Current data memory array:
256 entries, each entry is one 32-bit word

Index conversion:
word_idx = alu_result_M[9:2]
```

当前设计假设 `lw/sw` 都是 aligned access。后面加入 CSR 和 exception 后，misaligned load/store 应该成为架构异常，而不是被静默忽略。
