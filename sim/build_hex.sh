#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash sim/build_hex.sh <input.s> [output.hex] [extra-input.s ...]" >&2
  exit 2
fi

ASM_FILE="$1"
HEX_FILE="${2:-${ASM_FILE%.s}.hex}"
ASM_FILES=("$ASM_FILE")

if [[ $# -gt 2 ]]; then
  ASM_FILES+=("${@:3}")
fi

for source_file in "${ASM_FILES[@]}"; do
  if [[ ! -f "$source_file" ]]; then
    echo "ERROR: input assembly file not found: $source_file" >&2
    exit 1
  fi
done

if ! command -v riscv64-elf-gcc >/dev/null 2>&1; then
  echo "ERROR: riscv64-elf-gcc not found in PATH" >&2
  exit 1
fi

if ! command -v riscv64-elf-objdump >/dev/null 2>&1; then
  echo "ERROR: riscv64-elf-objdump not found in PATH" >&2
  exit 1
fi

if ! command -v riscv64-elf-objcopy >/dev/null 2>&1; then
  echo "ERROR: riscv64-elf-objcopy not found in PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/programs"
LINKER_SCRIPT="$REPO_ROOT/software/linker/core.ld"

if [[ ! -f "$LINKER_SCRIPT" ]]; then
  echo "ERROR: linker script not found: $LINKER_SCRIPT" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

BASENAME="$(basename "${ASM_FILE%.s}")"
ELF_FILE="$BUILD_DIR/$BASENAME.elf"
DUMP_FILE="$BUILD_DIR/$BASENAME.dump"
MAP_FILE="$BUILD_DIR/$BASENAME.map"
PREPROCESSED_FILES=()

cd "$REPO_ROOT"

mkdir -p "$(dirname "$HEX_FILE")"

for index in "${!ASM_FILES[@]}"; do
  source_file="${ASM_FILES[$index]}"
  source_basename="$(basename "${source_file%.*}")"
  preprocessed_file="$BUILD_DIR/${BASENAME}_${index}_${source_basename}.preprocessed.s"

  sed 's,//.*,,' "$source_file" > "$preprocessed_file"
  PREPROCESSED_FILES+=("$preprocessed_file")
done

ENTRY_POINT="0"
if grep -Eq '^[[:space:]]*_start[[:space:]]*:' "${PREPROCESSED_FILES[@]}"; then
  ENTRY_POINT="_start"
fi

riscv64-elf-gcc \
  -march=rv32i_zicsr \
  -mabi=ilp32 \
  -nostdlib \
  -nostartfiles \
  -Wl,-T,"$LINKER_SCRIPT" \
  -Wl,-e,"$ENTRY_POINT" \
  -Wl,-Map,"$MAP_FILE" \
  -Wl,--no-relax \
  -o "$ELF_FILE" \
  "${PREPROCESSED_FILES[@]}"

riscv64-elf-objdump -d -M no-aliases,numeric "$ELF_FILE" > "$DUMP_FILE"

riscv64-elf-objcopy \
  -O verilog \
  --verilog-data-width=4 \
  --only-section=.text \
  --only-section=.trap \
  "$ELF_FILE" \
  "$HEX_FILE"

echo "Wrote $HEX_FILE"
echo "Wrote $DUMP_FILE"
echo "Wrote $MAP_FILE"
echo
sed -n '1,120p' "$DUMP_FILE"
