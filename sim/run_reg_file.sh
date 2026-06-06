#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/reg_file"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

verilator -sv --timing --binary --trace -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM \
  --top-module reg_file_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o reg_file_tb \
  rtl/core/core_types_pkg.sv \
  rtl/core/reg_file.sv \
  tb/reg_file_tb.sv

"$SIM_BUILD_DIR/obj_dir/reg_file_tb"
