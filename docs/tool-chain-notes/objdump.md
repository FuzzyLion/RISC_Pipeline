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

## Fixed-Address Example Output

```text
00000000 <_start>:
   0: 00000297  auipc x5,0x0
   4: 10028293  addi  x5,x5,256
   8: 30529073  csrrw x0,mtvec,x5

00000100 <trap_handler>:
 100: 30200073  mret
```

This historical fixed-address example shows how the dump verifies section and
symbol placement. The current linker script packs `.trap` immediately after
`.text`, so the actual `trap_handler` address depends on program size and must
be checked in the generated dump or map file.

## Input and Output

```text
Input:  linked ELF executable
Output: text disassembly stored in a .dump file
```

The old `objdump + awk` build path discarded addresses when extracting machine
words. The current trap-aware build uses `objcopy` for memory-image generation
and keeps `objdump` for inspection.
