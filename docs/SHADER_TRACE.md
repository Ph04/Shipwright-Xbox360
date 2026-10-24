# Fast3D shader trace procedure

**Purpose:** collect the actual GLSL generated for the pinned desktop OpenGL renderer, so a future offline shader compiler experiment is driven by observed keys instead of guessed permutations.

**Scope:** host-side diagnostic only. It does not add an Xbox renderer, compile SPIR-V or build Shipwright for Xbox 360.

## Source and pin safety

This helper targets the precise libultraship gitlink in [BASELINE.md](BASELINE.md): `da6daf1a50a5e46d6641408d52227e31e85e46df`. It refuses a different checkout and runs `git apply --check` before changing the source.

1. Check out the source revision recorded in [BASELINE.md](BASELINE.md) and initialize its submodules, following Shipwright's official build instructions.
2. Apply the opt-in instrumentation to the libultraship submodule:

   ```bash
   bash tools/apply-fast3d-shader-trace.sh /path/to/Shipwright/libultraship
   ```

3. Reconfigure the **desktop OpenGL reference build** so the libultraship C++ target is compiled with `SOH_TRACE_SHADERS` defined. With a GCC/Clang CMake build, the usual mechanism is `-DCMAKE_CXX_FLAGS=-DSOH_TRACE_SHADERS`; for a compiler with MSVC-style flags, use `/DSOH_TRACE_SHADERS`. Confirm in the compile command that the definition reaches libultraship. Do not use this trace flag for the eventual console build.
4. Run the reference application from a writable working directory and visit representative scenes/menus/gameplay. The trace writes shader files relative to the process working directory.
5. Preserve the application log and the generated files together. The source helper reports keys, byte counts and whether each dump was written successfully.

## Output format

Each previously unseen pair of Fast3D shader IDs produces a pair of plain source files:

- `soh-shader-<shader_id0>-<shader_id1>.vert.glsl`
- `soh-shader-<shader_id0>-<shader_id1>.frag.glsl`

The hexadecimal IDs in the filenames are zero-padded to 16 digits. Keep pairs together. If a file cannot be opened or written, the log reports `vertex_dump=false` or `fragment_dump=false`; don't count that key as captured.

The current OpenGL renderer caches programs by the two IDs, so this capture records each key when the renderer first creates its program during that process. Re-run different settings and scenes to improve coverage. A captured set is not proof that every possible game path or user configuration was exercised.

## Offline SPIR-V/Xenos compiler experiment

Once XSDK's host compiler has been built and the matching revision is available, run:

```bash
bash scripts/compile-fast3d-shader-dumps.sh /path/to/shader-dumps /path/to/pinned-xsdk /path/to/results
```

An optional fourth argument supplies the executable path to glslang. The helper validates that both stages exist for each key, renames them to the extensions expected by XSDK's official `tools/build_shaders.py`, then tests every vertex/fragment stage independently. Results include one log per stage, a header for every accepted stage and a TSV manifest with the two shader IDs, stage, status and exit code. It attempts the full set even if individual shaders are refused, then exits nonzero when any stage fails. The generated headers are test outputs, not yet integrated into Shipwright's runtime shader selection.

## Evidence to retain

Keep a simple run manifest containing: Shipwright commit, libultraship SHA, compiler/build configuration, scenes exercised, application log, number of unique shader keys, number of complete vertex/fragment pairs, and any write/compile failures. A later analysis can batch-compile the generated files to SPIR-V and pass them through the pinned xost compiler; that experiment must separately record accepted versus refused shaders and refusal messages.

Do not place ROMs, extracted game assets, save files or other user-specific data in this repository. The generated shader source is a local diagnostic output by default and should be kept outside source control unless explicitly reviewed.

## Limitations

- This trace covers the current desktop OpenGL Fast3D implementation only; it does not prove equivalence with an Xbox shader pipeline.
- The source patch is opt-in and is not part of upstream Shipwright.
- No full upstream checkout patch test, Shipwright compile, shader compile or Xbox runtime test has been claimed. The unified diff syntax/context was checked against a focused fixture, but the patch still needs to be applied and compiled in the pinned upstream build before its runtime output can be trusted.
