#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/trace.sh"
SIM_BUILD_DIR="$SCRIPT_DIR/build/data_mem"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

run_verilator -sv --timing --binary -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM \
  --top-module data_mem_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o data_mem_tb \
  rtl/core/core_types_pkg.sv \
  rtl/memory/data_mem.sv \
  tb/data_mem_tb.sv

run_simulation "$SIM_BUILD_DIR/data_mem_tb.vcd" \
  "$SIM_BUILD_DIR/obj_dir/data_mem_tb"
