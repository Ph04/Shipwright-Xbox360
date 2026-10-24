# Dependency and platform audit

**Date:** 2026-10-24  
**Status:** source-level audit expanded; Shipwright and submodule revisions are pinned. Dependency builds and target validation remain open.

## Current findings

### Shipwright application

The inspected upstream CMake entry point identifies Shipwright as 9.3.1, requires CMake 3.26+, C++20 and C23, uses a libultraship submodule and Torch, and contains no Xbox 360 target path. Its platform-specific configuration selects Direct3D 11 on Windows x64 and enables OpenGL on the generic GNU/Clang path. The application CMake searches for SDL2 and SDL2_net, fetches dr_libs for custom audio, and links Ogg/Vorbis/Opus/OpusFile in the relevant platform configurations.

Sources:
- https://github.com/HarbourMasters/Shipwright/blob/2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41/soh/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41/docs/BUILDING.md
- https://github.com/HarbourMasters/Shipwright/blob/2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41/.gitmodules
- Full revision record: [BASELINE.md](BASELINE.md)

The dependency list above is a source-level inventory, not a complete closure or a statement that these packages build on PowerPC. The CMake file also assembles host-oriented tools (Torch and the OTR packer) alongside the game target; a cross-build must keep those tools on the host toolchain and pass generated OTR inputs to the target build.

### libultraship submodule: pinned revision

At Shipwright commit `2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41`, the libultraship gitlink is pinned to [`da6daf1a50a5e46d6641408d52227e31e85e46df`](https://github.com/kenix3/libultraship/tree/da6daf1a50a5e46d6641408d52227e31e85e46df); the Torch gitlink is pinned to [`2ab12fe9660aec04e02ee89fe81baed304a1a1d6`](https://github.com/HarbourMasters/Torch/tree/2ab12fe9660aec04e02ee89fe81baed304a1a1d6). Use those immutable revisions for source changes, not the moving branch names in `.gitmodules`.

The currently inspected libultraship CMake organizes Fast3D graphic backend sources, builds libultraship as a static library, and uses ImGui plus supporting libraries including libzip, nlohmann-json, tinyxml2, spdlog and stb_image. The precise requirements must be confirmed against the pinned submodule revision.

Sources:
- https://github.com/kenix3/libultraship/tree/da6daf1a50a5e46d6641408d52227e31e85e46df
- https://github.com/kenix3/libultraship/blob/da6daf1a50a5e46d6641408d52227e31e85e46df/src/fast/CMakeLists.txt
- https://github.com/kenix3/libultraship/blob/da6daf1a50a5e46d6641408d52227e31e85e46df/src/CMakeLists.txt

### SDL and platform services

The inspected Shipwright application asks for SDL2/SDL2_net. The available Xbox port, SDL-xenon, is based on SDL 3.4.10; its port notes explicitly say it has no native video/render/GPU driver, only dummy and offscreen video drivers. It documents controller input, an audio bridge to xsdk, threads/timers and preference paths, but is not a direct SDL2 replacement.

Source:
- https://github.com/xenosworks/SDL-xenon/blob/adb87a744ae056f1849718770cf198fa6c4899f9/docs/README-xsdk.md

Implication: an Xbox-specific SDL/platform decision is required. Either maintain an SDL2 port/compatibility layer or port all required application and ImGui integration to SDL3. This has not been implemented.

### Graphics feasibility

The existing generic GNU/Clang application path enables OpenGL. xsdk's CMake toolchain uses CMAKE_SYSTEM_NAME=Generic, so the Xbox profile must explicitly prevent unsuitable desktop-OpenGL selection. Vulkan4Xenon is a Vulkan 1.0 subset over xsdk's GPU layer; it has an independently tested .xex and can be evaluated as a substrate, but does not claim Vulkan conformance and does not establish compatibility with Shipwright's Fast3D renderer or shaders.

Sources:
- https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/cmake/xsdk.cmake
- https://github.com/xenosworks/vulkan4xenon/tree/b79913b407504b1e1663e74b14579cd91d2e7040
- https://github.com/xenosworks/vulkan4xenon/blob/b79913b407504b1e1663e74b14579cd91d2e7040/docs/ROADMAP.md
- https://github.com/xenosworks/dusklight-xenon/blob/d04e793671ca50bf3dad5dc3f5a16a45974558e3/docs/README-xsdk.md

The pinned libultraship `src/fast/backends` directory contains Direct3D 11, DXGI, Metal, OpenGL and SDL2 backend source files, but no Vulkan implementation. `include/fast/backends/gfx_rendering_api.h` exposes operations for shader lifecycle, texture upload/sampling, depth state, viewport/scissor, triangle draws, framebuffer lifecycle/copy/clear/readback and MSAA resolve. Its OpenGL implementation maps Fast3D behavior to GL-specific calls. This confirms that an Xbox backend must implement the contract or introduce an explicit adapter; toggling compile definitions is not sufficient. See [RENDERER_FEASIBILITY.md](RENDERER_FEASIBILITY.md) for the operation-by-operation proof plan.

A renderer proof-of-concept must validate Fast3D operations, depth/stencil, blending, texture formats and mipmaps, render targets/resolves, shader compilation, presentation, frame cost and memory use on the intended target. A custom backend or substantial adaptation is expected; changing compile definitions is not enough.

### xsdk and target environment

xsdk supplies a custom PowerPC toolchain (GCC 15.3, binutils 2.47, newlib 4.6 for powerpc-xsdk-elf), CMake integration, C17/C++23 runtime support, input and audio APIs, and a path to generate .xex files. Its getting-started guide states that these unsigned titles are for RGH/JTAG consoles, not standard retail consoles. This is the candidate build foundation, not a verified Shipwright toolchain.

Sources:
- https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/docs/GETTING_STARTED.md
- https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/docs/PARITY.md
- https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/docs/PITFALLS.md

### Dependency and renderer documents

- [Dependency portability matrix](DEPENDENCY_MATRIX.md) — initial per-subsystem findings, work required and priority.
- [Renderer feasibility](RENDERER_FEASIBILITY.md) — graphics, SDL, audio, asset pipeline and minimum test gates.
- [Testing policy](TESTING.md) — labels for source presence, build verification, emulator testing and physical hardware verification.

## Current blocker summary

| Area | Finding | Gate before broader integration |
|---|---|---|
| Upstream baseline | Shipwright `2827fc2...` and both submodule gitlinks are pinned | Finish review of upstream notices/license permissions and audit every redistributed dependency |
| Toolchain | xsdk is a credible homebrew candidate; Shipwright has not been built with it | Build clean xsdk hello/triangle samples; record logs and versions |
| Platform/runtime | No Xbox 360 target/profile in current application CMake | Prove startup, logging, controller, timing, writable paths and clean shutdown in a small .xex |
| SDL | SoH requests SDL2; SDL-xenon is SDL3 and has no native video/render driver | Decide and implement SDL API/platform path |
| Graphics | Existing path selects OpenGL; Vulkan4Xenon subset is not proven against Fast3D | Standalone renderer probe and hardware evidence |
| Audio | SDL bridge exists, but SoH's complete audio route is not yet mapped | Trace playback path; test tone and representative formats |
| Dependencies | Initial CMake inventory only; no libraries certified for PowerPC | Pin versions/licenses, cross-build one at a time and test link closure |
| Asset pipeline | Host tools are co-configured with target build | Build host tools separately and avoid committing ROMs/extracted assets |
| Memory/performance | No Shipwright-specific allocation or frame-cost measurements | Add memory, timing and cache instrumentation during the probe |

## Next engineering sequence

1. Build and record the stock xsdk hello and triangle samples from a clean environment.
3. Add a minimal target platform test for logging, controller, filesystem, audio and exit.
4. Build the renderer proof-of-concept and decide Vulkan4Xenon versus a native xsdk GPU backend based on evidence.
5. Finish dependency/license closure and only then integrate a small Shipwright application slice.

No Shipwright Xbox 360 build, emulator test or hardware test is claimed at this stage.
