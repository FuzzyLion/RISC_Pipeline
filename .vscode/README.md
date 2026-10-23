# VS Code Configuration

This directory contains the shared VS Code configuration for the project. The goal is simple: catch RTL issues early while editing, then run a quick and repeatable check after a change.

`settings.json` keeps two complementary checks enabled:

- The Slang language server provides fast SystemVerilog syntax and semantic diagnostics, symbol lookup, and go-to-definition while editing.
- Verilator lint checks the complete core compilation view through `rtl/filelist.f`. It is better at exposing cross-module port, width, package, and combinational-logic issues.

The two tools overlap, but they do not replace each other. Slang keeps the editor responsive; Verilator is closer to the project's actual RTL compilation and elaboration flow. Functional correctness still needs the directed tests or regression under `sim/`.

## Tasks

- `Verilator: lint core filelist` checks that the core RTL can be parsed and elaborated. It does not run a simulation.
- `Verilator: elaborate smoke` elaborates the core RTL together with the basic smoke testbench. It checks whether the testbench, top-level wrapper, and core connect correctly, but it does not execute the program.

To verify that a program actually runs, use its matching script. For example:

```bash
bash sim/run_basic_smoke.sh
```

This rebuilds the program image, compiles the simulator, runs the clocked simulation, and lets the testbench check the final results.

## Maintenance

When RTL files are added, removed, or moved, update `rtl/filelist.f` first, then review the Verilator arguments and tasks here. Do not add generated `sim/build/` paths to these settings; they should always be reproducible from source.
