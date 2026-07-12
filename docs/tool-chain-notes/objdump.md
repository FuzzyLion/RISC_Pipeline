# objdump Notes

## Role in This Project

`riscv64-elf-objdump` creates a human-readable disassembly of the linked ELF.
It is used to inspect addresses, machine words, symbols, and decoded
instructions.

It does not create the instruction-memory image used by `$readmemh`.

## Current Command

```bash
riscv64-elf-objdump \
  -d \
  -M no-aliases,numeric \
  "$ELF_FILE" \
  > "$DUMP_FILE"
```

## Options Used

### `-d`

Disassembles executable sections in the ELF.

### `-M no-aliases,numeric`

- `no-aliases` shows canonical instructions instead of convenient
  pseudo-instruction names.
- `numeric` prints register numbers such as `x5` instead of ABI names such as
  `t0`.

This form makes the dump easier to compare with RTL register indices and exact
instruction behavior.

## Example Output

```text
00000000 <_start>:
   0: 00000297  auipc x5,0x0
   4: 10028293  addi  x5,x5,256
   8: 30529073  csrrw x0,mtvec,x5

00000100 <trap_handler>:
 100: 30200073  mret
```

This output can confirm that `_start` is at `0x0`, `trap_handler` is at
`0x100`, and `la` was expanded as expected.

## Input and Output

```text
Input:  linked ELF executable
Output: text disassembly stored in a .dump file
```

The old `objdump + awk` build path discarded addresses when extracting machine
words. The current trap-aware build uses `objcopy` for memory-image generation
and keeps `objdump` for inspection.
