# Shipwright for Xbox 360 (research port)

An independent, experimental effort to investigate porting [Ship of Harkinian / Shipwright](https://github.com/HarbourMasters/Shipwright) to Xbox 360 homebrew hardware.

> **Status: research / scaffolding only.** This repository does not yet contain a working port or a buildable game. No successful Xbox 360 build is claimed.

## Goals

- Audit Shipwright's architecture, build system, platform abstractions, and dependencies.
- Evaluate [xsdk](https://github.com/xenosworks/xsdk) and its Xenos GPU layer as the initial Xbox 360 homebrew foundation.
- Establish a small platform bring-up test before integrating the game.
- Port incrementally, preserving upstream attribution and complying with each dependency's license.
- Require a legally obtained compatible Ocarina of Time ROM; this repository will not distribute ROMs or extracted copyrighted game assets.

## Current direction

Shipwright currently documents OpenGL, Direct3D 11, and Metal graphics paths. Xbox 360 has a different GPU and platform environment, so this is not a simple recompile. The main early risk is the graphics and platform layer: input, window/event loop, audio, filesystem, threading, networking, and dependency availability must also be audited.

The first technical milestone is **not** to compile all of Shipwright. It is to build and run a minimal xsdk/Xenos test on target hardware, then document what is proven and what remains.

## Repository map

- docs/PORTING_PLAN.md — staged engineering plan and acceptance criteria.
- docs/DEPENDENCY_AUDIT.md — initial evidence-based dependency and platform audit.
- docs/TESTING.md — validation and evidence policy.

## Upstream projects

- Shipwright: https://github.com/HarbourMasters/Shipwright
- Xbox 360 xsdk: https://github.com/xenosworks/xsdk
- Dusklight-Xenon: https://github.com/xenosworks/dusklight-xenon
- Vulkan4Xenon: https://github.com/xenosworks/vulkan4xenon

## Development principles

1. Keep this project separate from unrelated repositories.
2. Never report a compile, emulator run, or hardware test as successful without an actual result.
3. Keep early hardware probes small and reproducible.
4. Avoid copying upstream source until the needed files and their licenses have been reviewed.
5. Treat a Vulkan compatibility layer as an option to evaluate, not proof that Shipwright's renderer will work unchanged.
