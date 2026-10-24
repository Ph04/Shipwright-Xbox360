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

## No unsupported claims

- Source added does not mean it compiles.
- A successful host build does not mean it builds for Xbox 360.
- A generated .xex does not prove it launches.
- An emulator result does not prove physical hardware compatibility.
- A clear-color demo does not prove Shipwright's renderer works.

Keep logs and artifacts free of ROMs, extracted game assets, credentials, or personal data.
