# Initial dependency and platform audit

**Date:** 2026-10-24  
**Status:** preliminary; based on upstream documentation and targeted file reads. A full dependency/source audit is still pending.

## Evidence collected

### Shipwright

The current upstream CMake entry point identifies Shipwright as version 9.3.1, requires CMake 3.26+, C++20 and C23, and defines desktop package setup for Windows including zlib, bzip2, libzip, libpng, SDL2, SDL2_net, GLEW, GLFW, nlohmann-json, tinyxml2, spdlog, Ogg/Vorbis and Opus/opusfile. The build guide documents Windows, macOS, Linux, Switch and Wii U paths; it does not list Xbox 360 as a supported target. Documented graphics APIs include Direct3D 11, OpenGL and Metal.

Sources:
- https://github.com/HarbourMasters/Shipwright/blob/develop/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/develop/docs/BUILDING.md

Implication: the Xbox 360 target needs a deliberate toolchain and platform layer, not just compiler flags. The package list above is only a first observation from the Windows CMake branch, not a complete cross-platform dependency inventory.

### xsdk

The xsdk getting-started guide specifies Windows 10/11 with WSL 2 and Debian, an RGH/JTAG console, and a custom PowerPC target toolchain (GCC 15.3, binutils 2.47 and newlib 4.6 for powerpc-xsdk-elf). The guide notes that unsigned .xex titles are for RGH/JTAG consoles; a standard retail console will not load them. Its parity document reports C17/C++23 runtime support and CMake integration, while listing limitations that must be checked before porting.

Sources:
- https://github.com/xenosworks/xsdk/blob/main/docs/GETTING_STARTED.md
- https://github.com/xenosworks/xsdk/blob/main/docs/PARITY.md
- https://github.com/xenosworks/xsdk

Implication: xsdk is the first candidate for the build foundation. A successful xsdk sample is the first required engineering gate; it is not evidence that Shipwright itself compiles.

### Dusklight-Xenon as a reference port

Dusklight-Xenon documents a real port built with xsdk and drawn through Vulkan4Xenon, with SDL-xenon and glslang-xenon in its build path. Its port-specific notes describe a 1280x720 output, a constrained memory budget, console-specific thread placement, a shader-pack workflow, and features intentionally left out. The project notes that some shaders are compiled on first use and cached.

Sources:
- https://github.com/xenosworks/dusklight-xenon
- https://github.com/xenosworks/dusklight-xenon/blob/main/docs/README-xsdk.md

Implication: this is a useful reference for integration patterns, memory budgeting, shader handling and CMake/toolchain setup. It is a different game and renderer, so it does **not** prove Shipwright's graphics operations or shaders are supported by Vulkan4Xenon.

### Vulkan4Xenon

xsdk describes Vulkan4Xenon as a Vulkan 1.0 subset built on the xsdk GPU layer.

Source: https://github.com/xenosworks/vulkan4xenon

Implication: treat this as a candidate backend, not a drop-in compatibility guarantee. We need to inventory the exact graphics features, shader inputs, resource formats, synchronization, render targets and presentation behavior used by Shipwright.

## Initial blocker matrix

| Area | Initial assessment | Evidence needed |
|---|---|---|
| Toolchain | Candidate: xsdk; target is PowerPC | Build a sample from a clean checkout; record toolchain versions and output |
| Console compatibility | RGH/JTAG required for unsigned .xex according to xsdk docs | Confirm user's target environment before planning distribution |
| Entry point / runtime | Unknown for Shipwright | Map startup, lifecycle, filesystem, logging, timing |
| Graphics | Highest-risk area | Compare Shipwright API calls and shaders with Vulkan4Xenon coverage; build a focused renderer probe |
| Input | SDL/controller adaptation likely required | Inspect SDL-xenon and map Shipwright input/event abstractions |
| Audio | Unknown | Inventory Shipwright's actual audio backend and test available APIs |
| Third-party libraries | Partial list only | Full CMake/submodule/transitive dependency inventory, licenses, and port status |
| Asset pipeline | Potentially reusable, unverified | Test extraction/build tools on host separately from target runtime |
| Saves/configuration | Unknown | Identify path assumptions and writable storage strategy |
| Memory/performance | Significant concern | Establish baseline and budget; console CPU/GPU share physical memory |
| Shader strategy | Unknown for Shipwright | Identify shader sources and runtime compiler assumptions; assess precompiled-pack feasibility |

## Next source inspection

1. Pin the exact Shipwright commit and inspect the rest of its root CMake configuration, submodules, renderer selection and platform-specific files.
2. Read xsdk's getting-started, parity, pitfalls and sample build scripts; choose one minimal sample as the first reproducible build.
3. Inspect Dusklight-Xenon and its SDL-xenon/Aurora integration for patterns that can be adapted without copying game-specific code.
4. Produce a per-library matrix with exact versions, source paths, licenses, target availability, changes needed and verification status.
5. Only after those checks, add a minimal Xbox 360 build profile and a renderer proof-of-concept. No full-game build is claimed at this stage.
