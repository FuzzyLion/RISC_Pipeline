#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

default_tests=(
  addi
  slti
  lui
  beq
  jal
  ori
  andi
  xori
  slli
  srli
  srai
  bne
  blt
  bge
  bltu
  bgeu
  jalr
  auipc
  sltiu
)

if [[ $# -gt 0 ]]; then
  tests=("$@")
else
  tests=("${default_tests[@]}")
fi

cd "$REPO_ROOT"

echo "Running riscv_lite ISA tests..."

for test_name in "${tests[@]}"; do
  asm_file="tools/riscv-tests/isa/rv32ui/${test_name}.S"
  hex_file="sim/build/riscv_lite/hex/rv32ui_${test_name}.hex"
  sim_build_dir="$SCRIPT_DIR/build/riscv_lite/verilator/${test_name}"
  isa_test_name="rv32ui_${test_name}"

  if [[ ! -f "$asm_file" ]]; then
    echo "ERROR: ISA test not found: $asm_file" >&2
    exit 1
  fi

  echo "====================================="
  echo "Running $isa_test_name"
  echo "====================================="

  mkdir -p "$sim_build_dir"

  bash software/scripts/build_riscv_lite_test.sh "$asm_file" "$hex_file"

  instr_count="$(wc -l < "$hex_file" | tr -d '[:space:]')"
  if (( instr_count > 256 )); then
    echo "ERROR: $isa_test_name produced $instr_count instructions, but instr_mem currently holds 256 words." >&2
    echo "Skip this case for now, reduce the test, or increase instr_mem capacity intentionally." >&2
    exit 1
  fi

  verilator -sv --timing --binary -Wall -Wno-fatal -Werror-UNOPTFLAT \
    -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL \
    -GIMEM_INIT_FILE="\"$hex_file\"" \
    -GISA_TEST_NAME="\"$isa_test_name\"" \
    --top-module core_isa_lite_tb \
    --Mdir "$sim_build_dir/obj_dir" \
    -o "core_isa_lite_${test_name}" \
    -f rtl/filelist.f \
    tb/core_isa_lite_tb.sv

  "$sim_build_dir/obj_dir/core_isa_lite_${test_name}"

  echo "$isa_test_name PASSED"
done

echo "All riscv_lite ISA tests passed!"
