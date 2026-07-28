# Slang Language Server

This folder is reserved for project-level Slang configuration. It currently contains documentation only; there is no `server.json`, so this folder does not change the language server's behaviour by itself.

## Current Setup

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

If the project later needs an explicit Slang file index, build configuration, or top-level setting, add the appropriate project configuration here and document why it is needed. Keep Verilator lint enabled as well: it checks the project's actual RTL file list and remains the closer match to the simulation build.
