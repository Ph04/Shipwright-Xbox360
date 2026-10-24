#!/usr/bin/env bash
set -euo pipefail

# Apply the optional shader-dump patch to the exact libultraship gitlink used
# by this repository's Shipwright baseline.
EXPECTED_SHA="da6daf1a50a5e46d6641408d52227e31e85e46df"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/libultraship/0001-opt-in-fast3d-shader-trace.patch"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 /path/to/Shipwright/libultraship" >&2
  exit 2
fi
if [[ ! -e "$TARGET/.git" ]]; then
  echo "Not a Git checkout or submodule: $TARGET" >&2
  exit 2
fi

ACTUAL_SHA="$(git -C "$TARGET" rev-parse HEAD)"
if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
  echo "Refusing to patch unexpected libultraship revision." >&2
  echo "Expected: $EXPECTED_SHA" >&2
  echo "Actual:   $ACTUAL_SHA" >&2
  exit 3
fi

if grep -q "SOH-SHADER-TRACE" "$TARGET/src/fast/backends/gfx_opengl.cpp"; then
  echo "Shader trace patch is already present in $ACTUAL_SHA."
  exit 0
fi

git -C "$TARGET" apply --check "$PATCH"
git -C "$TARGET" apply "$PATCH"
echo "Shader trace patch applied to $ACTUAL_SHA."
echo "Rebuild libultraship/Shipwright with -DSOH_TRACE_SHADERS defined for the patched source."
echo "Run a representative desktop session from a writable working directory."
echo "Collect soh-shader-*.vert.glsl and soh-shader-*.frag.glsl files from that working directory."
