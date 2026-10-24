# Shipwright for Xbox 360 (research port)

An independent, experimental effort to investigate porting [Ship of Harkinian / Shipwright](https://github.com/HarbourMasters/Shipwright) to Xbox 360 homebrew hardware.

> **Status: research / scaffolding only.** This repository does not yet contain a working port or a buildable game. No successful Xbox 360 Shipwright build is claimed.

## Goals

- Audit Shipwright's architecture, build system, platform abstractions, and dependencies.
- Evaluate [xsdk](https://github.com/xenosworks/xsdk) and its Xenos GPU layer as the initial Xbox 360 homebrew foundation.
- Establish a small platform bring-up test before integrating the game.
- Port incrementally, preserving upstream attribution and complying with each dependency's license.
- Require a legally obtained compatible Ocarina of Time ROM; this repository will not distribute ROMs or extracted copyrighted game assets.

## Current findings

The source audit identifies the graphics/backend selection and SDL platform boundary as the main early blockers. The inspected Shipwright application configuration uses SDL2 and enables OpenGL on its generic GNU/Clang path. The available SDL-xenon port is SDL3 and documents only dummy/offscreen video drivers; rendering must use xsdk's GPU layer or a backend such as Vulkan4Xenon. This means a real renderer/platform adaptation is required rather than a simple cross-compile.

Vulkan4Xenon is a candidate, not a drop-in guarantee. The next proof is to build the stock xsdk samples and then a small, instrumented renderer/platform probe. The source baseline is now pinned in [BASELINE.md](docs/BASELINE.md): Shipwright `2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41`, libultraship `da6daf1a50a5e46d6641408d52227e31e85e46df`, and Torch `2ab12fe9660aec04e02ee89fe81baed304a1a1d6`. No target build has been completed in this repository.

## Repository map

- [docs/BASELINE.md](docs/BASELINE.md) — immutable source revisions and license-review status.
- [docs/PORTING_PLAN.md](docs/PORTING_PLAN.md) — staged engineering plan and gates.
- [docs/DEPENDENCY_AUDIT.md](docs/DEPENDENCY_AUDIT.md) — source evidence and current blockers.
- [docs/DEPENDENCY_MATRIX.md](docs/DEPENDENCY_MATRIX.md) — subsystem-by-subsystem portability work and priority.
- [docs/RENDERER_FEASIBILITY.md](docs/RENDERER_FEASIBILITY.md) — graphics, SDL, audio, asset-pipeline findings and test gates.
- [docs/TESTING.md](docs/TESTING.md) — validation and evidence policy.

## Upstream projects

- Shipwright: https://github.com/HarbourMasters/Shipwright
- Xbox 360 xsdk: https://github.com/xenosworks/xsdk
- SDL-xenon: https://github.com/xenosworks/SDL-xenon
- Dusklight-Xenon: https://github.com/xenosworks/dusklight-xenon
- Vulkan4Xenon: https://github.com/xenosworks/vulkan4xenon

## Development principles

1. Keep this project separate from unrelated repositories.
2. Never report a compile, emulator run, or hardware test as successful without an actual result.
3. Keep early hardware probes small and reproducible.
4. Avoid copying upstream source until the needed files and their licenses have been reviewed.
5. Treat Vulkan compatibility as an option to evaluate, not proof that Shipwright's renderer will work unchanged.
