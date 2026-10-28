#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/trace.sh"
SIM_BUILD_DIR="$SCRIPT_DIR/build/alu_op"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

run_verilator -sv --timing --binary -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM \
  --top-module alu_op_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o alu_op_tb \
  rtl/core/core_types_pkg.sv \
  rtl/core/datapath/alu_op.sv \
  tb/alu_op_tb.sv

run_simulation "$SIM_BUILD_DIR/alu_op_tb.vcd" \
  "$SIM_BUILD_DIR/obj_dir/alu_op_tb"
