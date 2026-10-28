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
  -Wall \
  -Wno-fatal \
  -Werror-UNOPTFLAT \
  --top-module core_smoke_tb \
  --Mdir sim/build/basic_smoke/obj_dir \
  -o core_basic_smoke \
  -f rtl/filelist.f \
  tb/core_basic_smoke_tb.sv
```

This shows the default build without tracing. Individual scripts use only the
options needed by that test. They load [`sim/trace.sh`](../../sim/trace.sh),
whose `run_verilator` function adds `--trace -DTRACE_VCD` when `TRACE=1`.

## Options Used

### `-sv`

Enables SystemVerilog parsing.

### `--timing`

Enables testbench timing constructs such as delays and clock generation.

### `--binary`

Builds a runnable simulation executable directly.

### `--trace`

Compiles waveform-recording support into the simulation executable. In this
project it is enabled only when the runner receives `TRACE=1`; the testbench
must also execute its dump calls to produce a VCD.

### `-D<name>`

Defines a SystemVerilog preprocessor macro. The tracing helper passes
`-DTRACE_VCD`, so the code between the testbench's `` `ifdef TRACE_VCD `` and
`` `endif `` is included in the build. Without this definition, that block is
omitted. `TRACE_VCD` is a project-chosen macro name, not a built-in Verilator
option.

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

Reads RTL source paths from a file such as `rtl/filelist.f`.

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

## Optional VCD Output

From the repository root:

```bash
TRACE=1 bash sim/run_basic_smoke.sh
gtkwave sim/build/basic_smoke/basic_smoke.vcd
```

The runner sources `sim/trace.sh`, which makes `run_verilator` and
`run_simulation` available in the current shell. The two functions connect
three separate settings:

1. The shell variable `TRACE=1` selects tracing in the helper. If unset, it
   defaults to `0`.
2. At compile time, `--trace` enables tracing support and `-DTRACE_VCD` includes
   the testbench's `waveform_dump` block.
3. At run time, `run_simulation` passes `+trace=<absolute-vcd-path>` to the
   executable. The testbench reads the string with
   `$value$plusargs("trace=%s", trace_file)`. On a successful match, it calls
   `$dumpfile(trace_file)` and `$dumpvars(0, <testbench-module>)` to record
   signals in the testbench hierarchy.

The shell variable, preprocessor macro, and simulation argument serve different
stages; the shared helper keeps them consistent. Runs without tracing leave
existing VCD files unchanged. See the
[waveform guide](../../sim/README.md#waveforms) for other runners and output
locations.

## Lint-Only Use

The project also uses Verilator without running a simulation:

```bash
verilator --lint-only --sv -f rtl/filelist.f
```

This checks parsing, elaboration, ports, widths, and common RTL issues. It does
not prove functional behavior.
