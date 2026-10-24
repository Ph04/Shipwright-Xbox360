# Testing and evidence policy

Every test report should state:

- Repository commit SHA and toolchain revision.
- Exact command executed and relevant configuration.
- Whether it was a clean build.
- Exit code and a concise log excerpt.
- Target: host build, emulator, or physical Xbox 360.
- For hardware tests: console/model context and observed behavior.

## No unsupported claims

- Source added does not mean it compiles.
- A successful host build does not mean it builds for Xbox 360.
- A generated .xex does not prove it launches.
- An emulator result does not prove physical hardware compatibility.
- A clear-color demo does not prove Shipwright's renderer works.

Keep logs and artifacts free of ROMs, extracted game assets, credentials, or personal data.
