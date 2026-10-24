# Testing and evidence policy

Every test report should state:

- Repository commit SHA and toolchain revision.
- Exact command executed and relevant configuration.
- Whether it was a clean build.
- Exit code and a concise log excerpt.
- Target: host build, emulator, or physical Xbox 360.
- For hardware tests: console/model context and observed behavior.

## CI smoke gate

The workflow in [`.github/workflows/xsdk-smoke.yml`](../.github/workflows/xsdk-smoke.yml) builds a pinned xsdk toolchain and its official `hello`/`triangle` samples, then uploads compiler logs and generated `.xex` files. The script records the exact xsdk revision and artifact hashes. A workflow run is considered successful only if both expected `.xex` files are present and non-empty.

That workflow is compile-only. It does not build Shipwright, run an emulator, or run the title on hardware. Only report it as passed after checking the actual GitHub Actions run result and logs.

## Shader trace patch gate

The [Fast3D shader trace patch workflow](../.github/workflows/shader-trace-patch.yml) checks the shell helper syntax and applies the opt-in patch to the exact pinned libultraship source, then runs `git diff --check`. This is a patch applicability check only; it does not compile Shipwright or the patched C++ source.

The helper [compile-fast3d-shader-dumps.sh](../scripts/compile-fast3d-shader-dumps.sh) uses the pinned xsdk host compiler and glslang to test captured shaders one stage at a time. Its output is not evidence until the script is run and its TSV/logs are reviewed.

## No unsupported claims

- Source added does not mean it compiles.
- A successful host build does not mean it builds for Xbox 360.
- A generated .xex does not prove it launches.
- An emulator result does not prove physical hardware compatibility.
- A clear-color demo does not prove Shipwright's renderer works.

Keep logs and artifacts free of ROMs, extracted game assets, credentials, or personal data.
