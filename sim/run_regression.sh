#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]})")" && pwd)"

tests=(
  "run_control_unit.sh"
  "run_imm_ext.sh"
  "run_alu_op.sh"
  "run_reg_file.sh"
  "run_data_mem.sh"
  "run_hazard_unit.sh"
  "run_basic_smoke.sh"
  "run_smoke_branch.sh"
  "run_smoke_hazard.sh"
)

echo "Running regression tests..."

for test in "${tests[@]}"; do
    echo "====================================="
    echo "Running $test"
    echo "====================================="
    bash "$SCRIPT_DIR/$test"

    echo "$test PASSED"
done

echo "All regression tests passed!"
