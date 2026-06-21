#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: bash software/scripts/build_riscv_lite_test.sh <input.S> [output.hex]" >&2
  exit 2
fi

ASM_FILE="$1"
HEX_FILE="${2:-sim/build/riscv_lite/hex/$(basename "${ASM_FILE%.S}").hex}"

if [[ ! -f "$ASM_FILE" ]]; then
  echo "ERROR: input assembly file not found: $ASM_FILE" >&2
  exit 1
fi

if ! command -v riscv64-elf-gcc >/dev/null 2>&1; then
  echo "ERROR: riscv64-elf-gcc not found in PATH" >&2
  exit 1
fi

if ! command -v riscv64-elf-objdump >/dev/null 2>&1; then
  echo "ERROR: riscv64-elf-objdump not found in PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/sim/build/riscv_lite"
ENV_DIR="$REPO_ROOT/software/tests/riscv_lite/env"
MACRO_DIR="$REPO_ROOT/tools/riscv-tests/isa/macros/scalar"

if [[ ! -d "$MACRO_DIR" ]]; then
  echo "ERROR: riscv-tests macros not found: $MACRO_DIR" >&2
  echo "Run: git clone --recurse-submodules https://github.com/riscv-software-src/riscv-tests.git tools/riscv-tests" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR" "$(dirname "$REPO_ROOT/$HEX_FILE")"

BASENAME="$(basename "${ASM_FILE%.S}")"
ELF_FILE="$BUILD_DIR/$BASENAME.elf"
DUMP_FILE="$BUILD_DIR/$BASENAME.dump"
HEX_PATH="$REPO_ROOT/$HEX_FILE"

cd "$REPO_ROOT"

riscv64-elf-gcc \
  -x assembler-with-cpp \
  -march=rv32i \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -I"$ENV_DIR" \
  -I"$MACRO_DIR" \
  -Wl,-Ttext=0 \
  -Wl,-e,_start \
  -Wl,--no-relax \
  -o "$ELF_FILE" \
  "$ASM_FILE"

riscv64-elf-objdump -d -M no-aliases,numeric "$ELF_FILE" > "$DUMP_FILE"

awk '/^[[:space:]]*[0-9a-f]+:/ { print $2 }' "$DUMP_FILE" > "$HEX_PATH"

echo "Wrote $HEX_PATH"
echo "Wrote $DUMP_FILE"
echo
sed -n '1,160p' "$DUMP_FILE"
