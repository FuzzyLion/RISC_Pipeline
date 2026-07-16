# GNU ld Notes

## Role in This Project

`ld` combines assembled object code into one ELF executable. It resolves
symbols such as `_start` and `trap_handler`, then assigns final addresses using
the project linker script.

The scripts normally invoke `ld` through GCC by using `-Wl,...` options rather
than calling `riscv64-elf-ld` directly.

## Options Used

### `-T <linker-script>`

```bash
-Wl,-T,"$LINKER_SCRIPT"
```

Loads [`software/linker/core.ld`](../../software/linker/core.ld). The script
places `.text` at `0x00000000` and packs `.trap` at the next four-byte-aligned
address after `.text`.

### `-e <entry>`

```bash
-Wl,-e,"$ENTRY_POINT"
```

Records the ELF entry address. `_start` is used when the source defines that
symbol; legacy smoke programs use address zero.

The ELF entry does not set the hardware PC. CPU reset logic remains responsible
for the first fetch address.

### `-Map <file>`

```bash
-Wl,-Map,"$MAP_FILE"
```

Writes a link map. The map is a report for inspection and is not loaded into
the processor. It shows:

- Output-section addresses and sizes.
- Input sections included in each output section.
- Final symbol addresses.
- Region usage and overlap problems.

Searching for `.text`, `.trap`, `_start`, or `trap_handler` is usually enough
for the current workflow.

### `--no-relax`

```bash
-Wl,--no-relax
```

Disables linker relaxation. This keeps instruction sequences predictable while
the processor and directed tests are still being developed.

## Input and Outputs

```text
Inputs:  assembled object code and core.ld
Output:  ELF executable
Report:  map file
```

The ELF retains section addresses and symbols. `objdump` reads this information
for inspection, while `objcopy` uses it to create the memory image.

## Related Note

See [`linker.md`](linker.md) for the syntax used inside `core.ld`.
