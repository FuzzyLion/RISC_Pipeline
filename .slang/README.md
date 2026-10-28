# Slang Language Server

This folder contains project-level Slang configuration. [`server.json`](server.json) indexes the RTL and testbench directories and selects `rtl/filelist.f` as the build entry point.

The index explicitly includes `rtl/core/stages/`. Its five `.sv` files are
independent modules, each importing `core_types_pkg` and declaring its own
ports. They are ordinary sources in `rtl/filelist.f`, after the packages.
There are no stage `.svh` fragments or stage include paths to configure.

The flags set `--timescale=1ns/1ps` as the default for design elements without
an explicit time scale, matching the testbenches. This lets Slang analyze the
RTL together with the indexed testbenches without mixed/missing-time-scale
errors. It changes the editor's analysis configuration; simulation runners
and explicit testbench time scales are unchanged.

## Recorded Local Editor Setup

- VS Code extension: **Verilog-HDL/SystemVerilog** (`mshr-h.veriloghdl`) **1.28.4**
- Selected runtime: `bundled-wasm` in [`.vscode/settings.json`](../.vscode/settings.json)
- WASI support extension: `ms-vscode.wasm-wasi-core` **1.0.2**

## How the WASM Runtime Works

The Verilog extension ships a compiled `slang-server.wasm` file. When VS Code opens Verilog or SystemVerilog source, the extension starts that bundled Slang language server through VS Code's WASI runtime and exchanges Language Server Protocol messages with it.

In practice, this gives the editor syntax and semantic diagnostics, symbol lookup, and go-to-definition support without requiring a separately installed native `slang-server` executable. The workspace explicitly selects this bundled runtime, so the editor does not depend on a machine-specific Slang path.

## Why Use Slang Alongside Verilator Lint?

This is not a choice between static lint and dynamic checking: Slang and Verilator are both static-analysis tools. The difference is when and how they are used.

Slang runs inside the editor and reacts to the file you are currently changing, including unsaved edits. It is useful for fast feedback and navigation while writing RTL. Verilator lint runs the project file list as an external command, so it is better for checking the assembled design and catching project-wide elaboration issues.

Neither tool executes the processor over clock cycles. That is dynamic simulation, and it still belongs to the directed tests and regression scripts under `sim/`.

When source directories or the compilation entry point change, update `server.json` alongside `rtl/filelist.f` and document any additional configuration here. Keep Verilator lint enabled as well: it checks the project's actual RTL file list and remains the closer match to the simulation build.

If the editor retains diagnostics for removed stage `.svh` files after a
checkout or refactor, close those obsolete tabs and run **Verilog: Restart
slang-server** from the Command Palette. Open the replacement modules under
`rtl/core/stages/` and inspect Problems again. A successful Verilator run alone
does not confirm that the language server has refreshed its diagnostics.
