#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/control_unit"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

verilator -sv --timing --binary -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM \
  --top-module control_unit_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o control_unit_tb \
  rtl/core/core_types_pkg.sv \
  rtl/core/control_unit.sv \
  tb/control_unit_tb.sv

"$SIM_BUILD_DIR/obj_dir/control_unit_tb"
