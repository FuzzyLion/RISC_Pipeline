#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/smoke_hazard"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

if [[ -f programs/asm/smoke_hazard.s ]]; then
  bash "$SCRIPT_DIR/build_hex.sh" programs/asm/smoke_hazard.s programs/hex/smoke_hazard.hex
fi

verilator -sv --timing --binary --trace -Wall -Wno-fatal -Werror-UNOPTFLAT \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_hazard_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_smoke_hazard \
  -f rtl/filelist.f \
  tb/core_smoke_hazard_tb.sv

"$SIM_BUILD_DIR/obj_dir/core_smoke_hazard"
