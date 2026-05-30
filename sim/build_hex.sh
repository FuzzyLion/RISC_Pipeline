#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: bash sim/build_hex.sh <input.s> [output.hex]" >&2
  exit 2
fi

ASM_FILE="$1"
HEX_FILE="${2:-${ASM_FILE%.s}.hex}"

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
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/programs"

mkdir -p "$BUILD_DIR"

BASENAME="$(basename "${ASM_FILE%.s}")"
ASM_BUILD_FILE="$BUILD_DIR/$BASENAME.preprocessed.s"
ELF_FILE="$BUILD_DIR/$BASENAME.elf"
DUMP_FILE="$BUILD_DIR/$BASENAME.dump"

cd "$REPO_ROOT"

sed 's,//.*,,' "$ASM_FILE" > "$ASM_BUILD_FILE"

riscv64-elf-gcc \
  -march=rv32i \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -Wl,-Ttext=0 \
  -Wl,-e,0 \
  -Wl,--no-relax \
  -o "$ELF_FILE" \
  "$ASM_BUILD_FILE"

riscv64-elf-objdump -d -M no-aliases,numeric "$ELF_FILE" > "$DUMP_FILE"

awk '/^[[:space:]]*[0-9a-f]+:/ { print $2 }' "$DUMP_FILE" > "$HEX_FILE"

echo "Wrote $HEX_FILE"
echo "Wrote $DUMP_FILE"
echo
sed -n '1,120p' "$DUMP_FILE"
