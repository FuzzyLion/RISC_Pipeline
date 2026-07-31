# Data Memory Addressing Notes

## The Main Source of Confusion

The key point is simple: an address is not the data itself. It is only a number that tells us where the data lives in memory.

RISC-V memory is byte-addressed. Every address points to one byte of memory. A byte contains 8 bits, but the address used to point to that byte may be 32 or 64 bits wide.

So “32-bit byte address” combines two separate ideas:

```text
32-bit address -> the address number itself is 32 bits wide
byte address   -> each address points to 1 byte
```

The first tells us how wide the address number is. The second tells us how much memory one address identifies. They are not the same thing.

## A Real-World Analogy

Think of memory as a long row of mailboxes. Each mailbox holds exactly 1 byte, or 8 bits. The mailbox number is the address.

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

The address is only the mailbox number. A 32-bit address means that the number is represented with 32 bits, not that the mailbox stores 32 bits. In RISC-V, the smallest memory location identified by one address is still 1 byte.

## What `lw` Actually Does

`lw` means load word. In both RV32I and RV64I, one word is 32 bits, or 4 bytes.

Suppose the CPU executes:

```asm
lw x5, 4(x0)
```

The effective address is `4`. Because RISC-V is byte-addressed, address `4` points to `byte[4]`. But `lw` does not read only 1 byte. The `lw` instruction itself requires a 32-bit word, so the memory system reads 4 consecutive bytes starting at address `4`.

```text
lw from address 4 reads:

byte[4]
byte[5]
byte[6]
byte[7]
```

These 4 bytes are combined into one 32-bit value and written to the destination register.

For example, assume memory contains:

```text
Address 4: 0x78
Address 5: 0x56
Address 6: 0x34
Address 7: 0x12
```

RISC-V is little-endian, so the byte at the lowest address goes into the lowest 8 bits of the result:

```text
result[7:0]   = memory[4] = 0x78
result[15:8]  = memory[5] = 0x56
result[23:16] = memory[6] = 0x34
result[31:24] = memory[7] = 0x12

loaded word = 32'h12345678
```

The address has not somehow become a word address. It only selects the first byte. The `lw` instruction is what tells the memory system to read 4 bytes and combine them into a 32-bit word.

## Why Word Alignment Matters

A 32-bit word is 4 bytes. A naturally aligned word address is therefore a byte address divisible by 4.

```text
Address 0  -> aligned word starts at byte[0]
Address 4  -> aligned word starts at byte[4]
Address 8  -> aligned word starts at byte[8]
Address 12 -> aligned word starts at byte[12]
```

In binary, any address divisible by 4 has its lowest two bits set to 0:

```text
0  = ...0000
4  = ...0100
8  = ...1000
12 = ...1100

addr[1:0] == 2'b00
```

For `lw/sw`, an aligned access means `addr[1:0] == 2'b00`. If `addr[1:0]` is not 0, the word access is misaligned.

For example:

```text
lw from address 4 -> reads byte[4..7], aligned
lw from address 5 -> reads byte[5..8], misaligned
```

A RISC-V core must either support misaligned accesses in hardware or raise the
corresponding address-misaligned exception. This project takes the second path.
The EX stage classifies misaligned halfword and word accesses, and the current
directed processor tests prove selected load- and store-address-misaligned trap
cases. The memory-formatting blocks still suppress invalid write strobes as a
local safety measure, but trap control owns the architectural response.

## ISA View vs. Verilog Memory Model

From the ISA's point of view, memory is byte-addressed:

```text
memory address 0 -> one byte
memory address 1 -> one byte
memory address 2 -> one byte
memory address 3 -> one byte
memory address 4 -> one byte
```

The current Verilog Data Memory, however, is a word array:

```systemverilog
logic [31:0] mem [0:255];
```

Each `mem` entry already stores one 32-bit word, or 4 bytes.

```text
mem[0] contains byte addresses 0, 1, 2, 3
mem[1] contains byte addresses 4, 5, 6, 7
mem[2] contains byte addresses 8, 9, 10, 11
mem[3] contains byte addresses 12, 13, 14, 15
```

If the CPU produces byte address `8`, the word-array index is not `8`; it is `2`. Byte address `8` belongs to the third 32-bit word entry:

```text
word index = byte address / 4
word index = 8 / 4
word index = 2
```

In binary hardware, dividing by 4 is the same as shifting right by 2 bits:

```text
word index = byte address >> 2
```

This is why Data Memory uses part of `alu_result_M` as `word_idx`.

## Why We Use `alu_result_M[MEM_ADDR_WIDTH+1:2]`

Assume:

```systemverilog
parameter int MEM_WORDS = 256;
localparam int MEM_ADDR_WIDTH = $clog2(MEM_WORDS);
```

With `MEM_WORDS = 256`, the memory contains 256 word entries. Selecting one of 256 entries requires an 8-bit index:

```text
MEM_ADDR_WIDTH = log2(256) = 8
```

The effective address produced by the ALU is still a byte address:

```systemverilog
input logic [31:0] alu_result_M;
```

For `lw/sw`, the lowest two bits identify the byte offset inside a 32-bit word:

```text
alu_result_M[1:0] = byte offset inside the word
```

For an aligned `lw/sw`, those bits should be `00`. The next 8 bits select one of the 256 word entries:

```text
alu_result_M[9:2] = word index
```

The address can be read like this:

```text
alu_result_M[31:10]  alu_result_M[9:2]  alu_result_M[1:0]
unused in this model word index         byte offset
```

The general form is:

```systemverilog
assign word_idx = alu_result_M[MEM_ADDR_WIDTH + 1:2];
```

When `MEM_ADDR_WIDTH = 8`, this is equivalent to:

```systemverilog
assign word_idx = alu_result_M[9:2];
```

This line does two things. First, it drops the lowest two address bits because every `mem` entry already stores 4 bytes. Second, it keeps only enough bits to index the current memory: 256 entries require an 8-bit index.

## Why It Is Not `addr * 4`

This conversion is easy to reverse by accident.

The CPU produces a byte address, while the Verilog array needs a word index. 4 bytes make 1 word, so the word index is smaller than the byte address:

```text
byte address 0  -> word index 0
byte address 4  -> word index 1
byte address 8  -> word index 2
byte address 12 -> word index 3
```

The correct direction is:

```text
word index = byte address / 4
```

Not:

```text
word index = byte address * 4
```

Multiplying by 4 is the reverse conversion. If you already have a word index and want the address of that word's first byte, then you multiply by 4:

```text
byte address = word index * 4
```

For example, `mem[2]` begins at byte address `8`.

## Do `lw/sw` Access 8 Bytes in RV64?

No. RV64 does not turn `lw/sw` into 8-byte operations. RV64 means that the general-purpose registers are 64 bits wide. The specific load or store instruction still decides how many bytes one memory access transfers.

Common RV64 access sizes are:

```text
lb / sb -> 1 byte
lh / sh -> 2 bytes
lw / sw -> 4 bytes
ld / sd -> 8 bytes
```

In RV64, `lw` reads 4 bytes, sign-extends the 32-bit result to 64 bits, and writes it to the destination register. `lwu` also reads 4 bytes, but zero-extends the result to 64 bits. `ld` is the instruction that reads 8 bytes, and `sd` writes 8 bytes.

Alignment depends on the access size:

```text
lb / sb -> any byte address
lh / sh -> addr[0] == 0
lw / sw -> addr[1:0] == 2'b00
ld / sd -> addr[2:0] == 3'b000
```

Register width and memory-access size are related, but they are not the same thing.

## How This Relates to Instruction Memory

Instruction Memory follows the same addressing idea. The PC is also a byte address. A normal RV32I instruction is 32 bits, or 4 bytes, so an instruction memory modeled as a word array is usually indexed like this:

```systemverilog
instr = imem[pc[IMEM_ADDR_WIDTH + 1:2]];
```

The reason is the same: the ISA uses byte addresses, while the simple Verilog model stores one complete 32-bit instruction in each entry.

Branch and jump immediates also involve alignment, but they are separate from Data Memory indexing. RISC-V branch and jump offsets implicitly keep the lowest bit at 0 because control-flow targets are at least 2-byte aligned. `imm_ext` reconstructs that offset from the instruction encoding. This is not the same calculation as Data Memory's `word_idx`, although both rely on low address bits to express alignment or a position inside a larger unit.

## The Rule for This Project

For the current simple `data_mem.sv`, remember it like this:

```text
RISC-V address from ALU:
32-bit byte address

Current data memory array:
256 entries, each entry is one 32-bit word

Index conversion:
word_idx = alu_result_M[9:2]
```

For a valid access, the current memory path uses the same byte-address to
word-index conversion described above. A misaligned halfword or word access is
classified in EX and enters the precise trap path before the faulting
instruction can commit a register or memory side effect.
