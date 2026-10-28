#!/usr/bin/env bash
# Sourced by simulation runners. TRACE=1 enables both compilation and VCD output.

case "${TRACE:-0}" in
  0|1) ;;
  *)
    echo "ERROR: TRACE must be 0 or 1 (default: 0)." >&2
    exit 1
    ;;
esac

run_verilator() {
  if [[ "${TRACE:-0}" == 1 ]]; then
    verilator --trace -DTRACE_VCD "$@"
  else
    verilator "$@"
  fi
}

run_simulation() {
  local trace_file="$1"
  shift

  if [[ "${TRACE:-0}" == 1 ]]; then
    echo "VCD: $trace_file"
    "$@" "+trace=$trace_file"
  else
    "$@"
  fi
}
