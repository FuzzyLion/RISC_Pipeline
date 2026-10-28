#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/trace.sh"
SIM_BUILD_DIR="$SCRIPT_DIR/build/basic_smoke"

cd "$REPO_ROOT"

mkdir -p "$SIM_BUILD_DIR"

bash "$SCRIPT_DIR/build_hex.sh" \
  programs/asm/smoke_basic.s \
  programs/hex/smoke_basic.hex

run_verilator -sv --timing --binary -Wall -Wno-fatal -Werror-UNOPTFLAT \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_basic_smoke \
  -f rtl/filelist.f \
  tb/core_basic_smoke_tb.sv

run_simulation "$SIM_BUILD_DIR/basic_smoke.vcd" \
  "$SIM_BUILD_DIR/obj_dir/core_basic_smoke"
