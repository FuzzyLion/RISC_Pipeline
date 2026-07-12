# Verilator Notes

## Role in This Project

Verilator compiles the SystemVerilog RTL and testbench into a native simulation
executable. It does not compile RISC-V assembly. Assembly programs reach the
simulation through the hex file loaded by `$readmemh`.

## Current Command Shape

```bash
verilator \
  -sv \
  --timing \
  --binary \
  --trace \
  -Wall \
  -Wno-fatal \
  -Werror-UNOPTFLAT \
  --top-module core_smoke_tb \
  --Mdir sim/build/basic_smoke/obj_dir \
  -o core_basic_smoke \
  -f rtl/core/filelist.f \
  tb/core_basic_smoke_tb.sv
```

Individual scripts use only the options needed by that test.

## Options Used

### `-sv`

Enables SystemVerilog parsing.

### `--timing`

Enables testbench timing constructs such as delays and clock generation.

### `--binary`

Builds a runnable simulation executable directly.

### `--trace`

Enables waveform tracing for tests that generate VCD output.

### `-Wall`

Enables a broad set of warnings.

### `-Wno-fatal`

Prevents ordinary warnings from stopping the build. Explicitly promoted warning
classes can still fail the build.

### `-Werror-UNOPTFLAT`

Treats `UNOPTFLAT` warnings as errors. This helps catch combinational structures
that Verilator cannot flatten safely or efficiently.

### `-Wno-<warning>`

Disables a warning class that is intentionally accepted by the current test.
Examples used in the scripts include `DECLFILENAME`, `TIMESCALEMOD`,
`UNUSEDSIGNAL`, and `UNUSEDPARAM`.

### `--top-module <name>`

Selects the testbench module that starts the simulation.

### `--Mdir <directory>`

Sets the directory for generated C++ files and build output.

### `-o <name>`

Sets the simulation executable name.

### `-f <filelist>`

Reads RTL source paths from a file such as `rtl/core/filelist.f`.

### `-G<parameter>=<value>`

Overrides a top-level parameter. The ISA-lite runner uses this to pass the hex
path and test name into the testbench.

## Build and Run

Verilator first builds the executable:

```text
RTL + testbench -> generated C++ -> native executable
```

The script then runs that executable as a separate command. A test failure
should call `$fatal(1, ...)`, which produces a nonzero process status. A
successful test should terminate with `$finish`.

## Lint-Only Use

The project also uses Verilator without running a simulation:

```bash
verilator --lint-only --sv -f rtl/core/filelist.f
```

This checks parsing, elaboration, ports, widths, and common RTL issues. It does
not prove functional behavior.
