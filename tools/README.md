# Tools Directory

This directory is for local third-party tool and test checkouts that the project
uses but does not vendor into git.

## riscv-tests

`tools/riscv-tests/` is an ignored upstream checkout used by the ISA-lite
runner. The project reads official `rv32ui` sources and scalar test macros from
that tree, while the local lightweight environment lives under
`software/tests/riscv_lite/`.

Set it up from the repository root with:

```bash
git clone --recurse-submodules https://github.com/riscv-software-src/riscv-tests.git tools/riscv-tests
```

Keep the checkout unchanged. If a test needs adaptation for this core, put the
adaptation in this repository's own `software/tests/riscv_lite/` files instead
of editing upstream files under `tools/riscv-tests/`.
