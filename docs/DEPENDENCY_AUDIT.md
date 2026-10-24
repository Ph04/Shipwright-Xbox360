# Initial dependency and platform audit

**Date:** 2026-10-24  
**Status:** preliminary; based on public project documentation, not yet a source-by-source audit.

## Evidence collected

### Shipwright

The upstream build guide describes a CMake-based C/C++ project with submodules and a number of desktop dependencies. It documents platform build paths for Windows, macOS, Linux, Switch, and Wii U. The current documented graphics APIs include Direct3D 11, OpenGL, and Metal. Xbox 360 is not listed as a supported target.

Source: https://github.com/HarbourMasters/Shipwright/blob/develop/docs/BUILDING.md

Implication: a new target requires more than changing compiler flags. We must identify which platform code and dependencies are coupled to desktop APIs, then introduce a target-specific implementation.

### xsdk

The xsdk project describes itself as a homebrew SDK that builds Xbox 360 .xex titles for the retail kernel/dashboard on RGH consoles, with a GPU layer that drives Xenos directly. Its README points to getting-started, guide, pitfalls, parity, hardware notes, samples, and a related Vulkan 1.0 subset.

Source: https://github.com/xenosworks/xsdk

Implication: xsdk is the first candidate for a native Xbox 360 build foundation. Its supported APIs and samples must be verified against Shipwright's needs before choosing a renderer route.

### Vulkan4Xenon and Dusklight-Xenon

xsdk documents Vulkan4Xenon as a Vulkan 1.0 subset built on the xsdk GPU layer and identifies Dusklight-Xenon as a project drawing through it.

Sources:
- https://github.com/xenosworks/vulkan4xenon
- https://github.com/xenosworks/dusklight-xenon

Implication: this is evidence that a Vulkan-based graphics route exists in the ecosystem, not evidence that Shipwright's renderer or shaders are compatible. Required Vulkan features, resource formats, synchronization, shader compilation, and performance remain to be measured.

## Initial blocker matrix

| Area | Initial assessment | Evidence needed |
|---|---|---|
| Toolchain | Candidate: xsdk | Build a sample from a clean checkout; record compiler/toolchain versions |
| Entry point / runtime | Unknown for Shipwright | Map startup, lifecycle, filesystem, logging, timing |
| Graphics | High risk | Compare Shipwright API calls and shaders with Vulkan4Xenon coverage; test present path |
| Input | Unknown | Map SDL/controller abstractions to Xbox 360 controller input |
| Audio | Unknown | Inventory actual backend and required audio APIs |
| Third-party libraries | Unknown | Full dependency/submodule list and per-library port status |
| Asset pipeline | Potentially reusable, unverified | Test extraction/build tools on host separately from target runtime |
| Saves/configuration | Unknown | Identify path assumptions and writable storage strategy |
| Performance/memory | Unknown | Measure baseline after minimal renderer and runtime tests |

## Next source inspection

1. Pin a specific Shipwright commit and inspect CMakeLists.txt, submodules, renderer selection, and platform-specific files.
2. Read xsdk docs/GETTING_STARTED.md, docs/PARITY.md, docs/PITFALLS.md, and its sample build scripts.
3. Inspect Dusklight-Xenon for its integration pattern and dependency adaptations.
4. Convert findings into a concrete per-library port matrix with exact file paths and licenses.
