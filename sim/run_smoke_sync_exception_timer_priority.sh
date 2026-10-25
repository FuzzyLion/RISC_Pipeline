#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BUILD_DIR="$SCRIPT_DIR/build/smoke_sync_exception_timer_priority"

cd "$REPO_ROOT"
mkdir -p "$SIM_BUILD_DIR"

bash "$SCRIPT_DIR/build_hex.sh" \
  programs/asm/smoke_sync_exception_timer_priority.s \
  programs/hex/smoke_sync_exception_timer_priority.hex \
  software/runtime/trap_handler.s

verilator -sv --timing --binary -Wall -Wno-fatal -Werror-UNOPTFLAT \
  -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
  --top-module core_smoke_sync_exception_timer_priority_tb \
  --Mdir "$SIM_BUILD_DIR/obj_dir" \
  -o core_smoke_sync_exception_timer_priority \
  -f rtl/filelist.f \
  tb/core_smoke_sync_exception_timer_priority_tb.sv

"$SIM_BUILD_DIR/obj_dir/core_smoke_sync_exception_timer_priority"
