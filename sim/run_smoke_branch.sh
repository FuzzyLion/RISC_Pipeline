#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/smoke_branch"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

if [[ -f programs/smoke_branch.s ]]; then
  bash "$SCRIPT_DIR/build_hex.sh" programs/smoke_branch.s programs/smoke_branch.hex
fi

verilator -sv --timing --binary --trace -Wall -Wno-fatal -Werror-UNOPTFLAT \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_branch_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_smoke_branch \
  -f rtl/core/filelist.f \
  tb/core_smoke_branch_tb.sv

"$SIM_BUILD_DIR/obj_dir/core_smoke_branch"
