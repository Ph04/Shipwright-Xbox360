#!/usr/bin/env bash
set -eo pipefail

# Reproducible cross-compile smoke test against a fixed upstream xsdk revision.
# This builds xsdk's official samples only; it does not build Shipwright or run a console test.

if [ -z "$SMOKE_ROOT" ]; then
  echo "Set SMOKE_ROOT to a writable output directory." >&2
  exit 2
fi
if [ -z "$JOBS" ]; then JOBS=2; fi

XSDK_SHA="2c4599b31066efcf67be099673287fbec786ef14"
XSDK_URL="https://github.com/xenosworks/xsdk.git"
XSDK_SRC="$SMOKE_ROOT/xsdk"
PREFIX="$SMOKE_ROOT/xsdk-gcc"
TOOLCHAIN_WORK="$SMOKE_ROOT/toolchain-work"
LOG_DIR="$SMOKE_ROOT/logs"
mkdir -p "$SMOKE_ROOT" "$LOG_DIR" "$TOOLCHAIN_WORK"

exec > >(tee -a "$LOG_DIR/run.log") 2>&1

echo "== Shipwright Xbox 360: xsdk cross-compile smoke test"
echo "== xsdk revision: $XSDK_SHA"
echo "== host: $(uname -a)"
echo "== CMake: $(cmake --version | head -n 1)"
echo "== Python: $(python3 --version)"
echo "== parallel jobs: $JOBS"

for tool in git make cmake ninja python3 curl sha256sum; do
  command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 2; }
done
command -v glslangValidator >/dev/null || { echo "glslangValidator is required for the official GLSL sample." >&2; exit 2; }

mkdir -p "$(dirname "$XSDK_SRC")"
git init "$XSDK_SRC"
git -C "$XSDK_SRC" remote add origin "$XSDK_URL"
git -C "$XSDK_SRC" fetch --depth=1 origin "$XSDK_SHA"
git -C "$XSDK_SRC" checkout --detach FETCH_HEAD
ACTUAL_SHA="$(git -C "$XSDK_SRC" rev-parse HEAD)"
test "$ACTUAL_SHA" = "$XSDK_SHA" || { echo "Pinned xsdk SHA mismatch: $ACTUAL_SHA" >&2; exit 2; }
printf 'xsdk=%s\n' "$ACTUAL_SHA" > "$LOG_DIR/source-revisions.txt"

# xsdk's shader helper looks for a binary named "glslang"; on Ubuntu the GLSL-only
# Khronos executable is called glslangValidator. No HLSL shaders are built in this smoke test.
mkdir -p "$PREFIX/bin"
ln -sf "$(command -v glslangValidator)" "$PREFIX/bin/glslang"

(
  cd "$XSDK_SRC"
  PREFIX="$PREFIX" WORK="$TOOLCHAIN_WORK" JOBS="$JOBS" tools/toolchain/build.sh
) 2>&1 | tee "$LOG_DIR/toolchain-build.log"

"$PREFIX/bin/powerpc-xsdk-elf-gcc" --version | tee "$LOG_DIR/compiler-version.txt"

(
  cd "$XSDK_SRC"
  make -j"$JOBS" samples TOOLCHAIN="$PREFIX/bin/powerpc-xsdk-elf-"
) 2>&1 | tee "$LOG_DIR/samples-build.log"

for sample in hello triangle; do
  artifact="$XSDK_SRC/build/samples/$sample/$sample.xex"
  test -s "$artifact" || { echo "Expected XEX not found or empty: $artifact" >&2; exit 3; }
  sha256sum "$artifact" | tee -a "$LOG_DIR/xex-sha256.txt"
done

find "$XSDK_SRC/build/samples" -type f -name '*.xex' -print | sort | tee "$LOG_DIR/xex-files.txt"
echo "== PASS: official xsdk samples hello and triangle compiled to non-empty .xex files."
echo "== This is a compile-only result. No emulator or physical console was run, and Shipwright was not built."
