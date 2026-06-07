#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/basic_smoke"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

if [[ -f programs/smoke_basic.s ]]; then
  bash "$SCRIPT_DIR/build_hex.sh" programs/smoke_basic.s programs/smoke_basic.hex
fi

verilator -sv --timing --binary --trace -Wall -Wno-fatal -Werror-UNOPTFLAT \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_basic_smoke \
  -f rtl/core/filelist.f \
  tb/core_basic_smoke_tb.sv

"$SIM_BUILD_DIR/obj_dir/core_basic_smoke"
