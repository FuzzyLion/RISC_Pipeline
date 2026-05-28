#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/smoke"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

verilator -sv --timing --binary --trace -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_smoke \
  -f rtl/core/filelist.f \
  tb/core_smoke_tb.sv

"$SIM_BUILD_DIR/obj_dir/core_smoke"
