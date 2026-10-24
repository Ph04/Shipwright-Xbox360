#!/usr/bin/env bash
set -euo pipefail

# Compile every captured Fast3D shader independently through the pinned xsdk
# tool, producing a per-shader header and a manifest even when some shaders fail.

usage() {
  echo "Usage: $0 <shader-dump-directory> <pinned-xsdk-checkout> <output-directory> [glslang-executable]" >&2
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage
  exit 2
fi
DUMP_DIR="$(cd "$1" 2>/dev/null && pwd)" || { echo "Invalid dump directory: $1" >&2; exit 2; }
XSDK_ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "Invalid xsdk directory: $2" >&2; exit 2; }
mkdir -p "$3" || exit 2
OUT_DIR="$(cd "$3" && pwd)"
GLSLANG="${4:-}"

EXPECTED_XSDK_SHA="2c4599b31066efcf67be099673287fbec786ef14"
if [[ ! -f "$XSDK_ROOT/tools/build_shaders.py" || ! -f "$XSDK_ROOT/xenos-toolchain/xsc/native.py" ]]; then
  echo "Expected pinned xsdk checkout with tools/build_shaders.py and xenos-toolchain/xsc/native.py." >&2
  exit 3
fi
if [[ ! -f "$XSDK_ROOT/build/host/libxsc.so" ]]; then
  echo "Missing $XSDK_ROOT/build/host/libxsc.so; build the pinned xsdk host compiler first." >&2
  exit 3
fi
ACTUAL_XSDK_SHA="$(git -C "$XSDK_ROOT" rev-parse HEAD 2>/dev/null)" || {
  echo "xsdk directory is not a Git checkout." >&2; exit 3;
}
if [[ "$ACTUAL_XSDK_SHA" != "$EXPECTED_XSDK_SHA" ]]; then
  echo "Refusing an unpinned xsdk compiler. Expected $EXPECTED_XSDK_SHA; got $ACTUAL_XSDK_SHA." >&2
  exit 3
fi

if [[ -z "$GLSLANG" ]]; then
  if command -v glslang >/dev/null 2>&1; then
    GLSLANG="$(command -v glslang)"
  elif command -v glslangValidator >/dev/null 2>&1; then
    GLSLANG="$(command -v glslangValidator)"
  elif [[ -x "$XSDK_ROOT/xenos-toolchain/tools/glslang/bin/glslang.exe" ]]; then
    GLSLANG="$XSDK_ROOT/xenos-toolchain/tools/glslang/bin/glslang.exe"
  else
    echo "No glslang found. Supply the executable as argument 4." >&2
    exit 3
  fi
fi
if [[ ! -x "$GLSLANG" ]]; then
  echo "glslang is not executable: $GLSLANG" >&2
  exit 3
fi

shopt -s nullglob
vertices=("$DUMP_DIR"/soh-shader-*.vert.glsl)
fragments=("$DUMP_DIR"/soh-shader-*.frag.glsl)
if [[ ${#vertices[@]} -eq 0 || ${#fragments[@]} -eq 0 ]]; then
  echo "Expected both soh-shader-*.vert.glsl and soh-shader-*.frag.glsl dumps in $DUMP_DIR." >&2
  exit 4
fi

for file in "${vertices[@]}"; do
  stem="$(basename "$file" .vert.glsl)"
  [[ -f "$DUMP_DIR/$stem.frag.glsl" ]] || {
    echo "Missing fragment partner for $file" >&2; exit 4;
  }
done
for file in "${fragments[@]}"; do
  stem="$(basename "$file" .frag.glsl)"
  [[ -f "$DUMP_DIR/$stem.vert.glsl" ]] || {
    echo "Missing vertex partner for $file" >&2; exit 4;
  }
done

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
INPUT_DIR="$WORK_DIR/inputs"
mkdir -p "$INPUT_DIR"

for file in "${vertices[@]}"; do
  base="$(basename "$file" .glsl)"
  cp -- "$file" "$INPUT_DIR/$base"
done
for file in "${fragments[@]}"; do
  base="$(basename "$file" .glsl)"
  cp -- "$file" "$INPUT_DIR/$base"
done

MANIFEST="$OUT_DIR/fast3d-shader-compile.tsv"
printf 'shader_key_0\tshader_key_1\tstage\tinput_file\tstatus\texit_code\theader_file\tlog_file\n' > "$MANIFEST"
TOTAL=0
PASSED=0
FAILED=0
for input in "$INPUT_DIR"/*; do
  [[ -f "$input" ]] || continue
  name="$(basename "$input")"
  if [[ "$name" =~ ^soh-shader-([0-9a-f]{16})-([0-9a-f]{16})\.(vert|frag)$ ]]; then
    key0="${BASH_REMATCH[1]}"
    key1="${BASH_REMATCH[2]}"
    stage="${BASH_REMATCH[3]}"
  else
    echo "Unexpected normalized shader filename: $name" >&2
    exit 4
  fi
  header="$OUT_DIR/$name.h"
  log="$OUT_DIR/$name.log"
  rm -f "$header"
  TOTAL=$((TOTAL + 1))
  if python3 "$XSDK_ROOT/tools/build_shaders.py" --glslang "$GLSLANG" --output "$header" "$input" >"$log" 2>&1; then
    status="PASS"
    exit_code=0
    PASSED=$((PASSED + 1))
    echo "PASS $name"
  else
    status="FAIL"
    exit_code=1
    FAILED=$((FAILED + 1))
    echo "FAIL $name — see $log"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$key0" "$key1" "$stage" "$(basename "$input")" "$status" "$exit_code" "$(basename "$header")" "$(basename "$log")" >> "$MANIFEST"
done

echo "Compiled $TOTAL shader stages: $PASSED passed, $FAILED failed."
echo "Manifest: $MANIFEST"
echo "Per-shader logs and generated headers: $OUT_DIR"
if [[ $FAILED -ne 0 ]]; then
  exit 1
fi
