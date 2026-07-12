# objcopy Notes

## Role in This Project

`riscv64-elf-objcopy` converts the linked ELF into a Verilog hex file that can
be loaded by SystemVerilog `$readmemh`.

It is used for format conversion, not disassembly.

## Current Command

```bash
riscv64-elf-objcopy \
  -O verilog \
  --verilog-data-width=4 \
  --only-section=.text \
  --only-section=.trap \
  "$ELF_FILE" \
  "$HEX_FILE"
```

## Options Used

### `-O verilog`

Selects Verilog memory format as the output format. This format supports
`@address` markers understood by `$readmemh`.

### `--verilog-data-width=4`

Groups output data into four-byte words, matching the 32-bit entries in
`instr_mem`.

### `--only-section=<name>`

Includes only the executable sections required by the current instruction
memory image:

```text
.text
.trap
```

## Address Conversion

The CPU uses byte addresses, while the hex file addresses 32-bit words:

```text
CPU byte address 0x100 / 4 = hex word address 0x40
```

An ELF with `.trap` at byte address `0x100` therefore produces:

```text
@00000000
... .text words ...
@00000040
... .trap words ...
```

The address marker preserves the gap between `.text` and `.trap`.

## Input and Output

```text
Input:  linked ELF executable
Output: Verilog hex memory image
```

`objcopy` does not decide where sections belong. Their addresses have already
been assigned by the linker.
