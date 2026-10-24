# Renderer and platform feasibility: Xbox 360

**Reviewed:** 2026-10-24  
**Status:** source-level assessment only; no Xbox 360 Shipwright target has been built.

## Executive finding

A port is technically plausible as a substantial platform and renderer project, but the existing renderer cannot be treated as an Xbox-compatible backend by changing compiler flags. The most important engineering gate is a standalone graphics proof-of-concept that exercises the exact rendering operations used by Shipwright's Fast3D layer.

The current source-level evidence points to a new Xbox-specific backend or a sizeable adaptation layer, plus explicit SDL/audio/platform integration. Vulkan4Xenon is a candidate implementation substrate, not a drop-in replacement for OpenGL.

## What current source configuration tells us

### Shipwright's application build

- The upstream root CMake config uses CMake 3.26+, C++20 and C23.
- The application CMake currently discovers SDL2 and SDL2_net and defines ENABLE_OPENGL on the generic GNU/Clang path. The Windows x64 path selects ENABLE_DX11 instead.
- libultraship is a submodule and builds the shared Fast3D graphics/runtime layer; the root build also includes Torch-based asset tools and OTR generation.
- There is no Xbox 360 target branch in the inspected application CMake configuration.

Sources:
- https://github.com/HarbourMasters/Shipwright/blob/develop/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/develop/soh/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/develop/.gitmodules
- https://github.com/kenix3/libultraship/tree/port-maintenance

**Important reproducibility note:** Git submodules are checked out at a specific gitlink commit, not automatically at the branch named in .gitmodules. Before editing libultraship source, resolve and record the exact gitlink SHA from the chosen Shipwright commit. A moving branch tip is not a substitute for that pin.

### SDL/platform layer

- Shipwright's inspected application CMake explicitly requests SDL2 and SDL2_net.
- The available Xbox port at https://github.com/xenosworks/SDL-xenon is a modified SDL 3.4.10 port. Its notes say it has no native video/render/GPU driver; only dummy and offscreen video drivers are available. Titles must draw through xsdk's GPU layer or Vulkan4Xenon.
- That SDL port documents Xbox controller input, audio adaptation to xsdk's audio API, thread/timer support, and game-relative preference paths. Those facilities are useful, but the SDL3 port does not directly satisfy SDL2 call sites or SDL2_net dependencies.
- The ImGui integration and all SDL call sites must be included in any SDL2-to-SDL3 decision; changing only find_package is not sufficient.

Source:
- https://github.com/xenosworks/SDL-xenon/blob/xenon/docs/README-xsdk.md

Decision still open: either develop/maintain an SDL2 compatibility port, or port the application integration to SDL3 behind a dedicated Xbox platform layer. Do not select either path until the exact submodule revision and all required SDL APIs are inventoried.

### Graphics: highest-risk subsystem

The existing application CMake enables OpenGL on its generic GCC/Clang branch. xsdk's CMake toolchain uses CMAKE_SYSTEM_NAME=Generic, and the Xbox GPU is not exposed as a normal desktop OpenGL device. Consequently, an xsdk configure could enter the wrong feature-selection path unless the Xbox build profile explicitly overrides the existing renderer selection.

Vulkan4Xenon provides a Vulkan 1.0 subset over the xsdk GPU layer and has hardware-tested samples and a separate game port. Its own documentation explicitly describes a subset, not Vulkan conformance. The subset includes useful primitives—buffers, textures, graphics pipelines, render passes, command buffers and presentation—but some formats, features and operations remain unsupported or constrained.

Sources:
- https://github.com/xenosworks/xsdk/blob/main/cmake/xsdk.cmake
- https://github.com/xenosworks/vulkan4xenon
- https://github.com/xenosworks/vulkan4xenon/blob/main/docs/ROADMAP.md
- https://github.com/xenosworks/dusklight-xenon/blob/xenon/docs/README-xsdk.md

The graphics proof-of-concept must answer these questions with a runnable .xex, not assumptions:

1. Can the current Fast3D backend contract be mapped to Vulkan4Xenon without reproducing OpenGL state semantics in a fragile shim?
2. Are the shader inputs and generated shaders compatible with glslang/xost? Which shaders need rewriting or precompilation?
3. Can required depth/stencil, blend, cull, texture/mipmap, framebuffer, resolve and synchronization operations be represented?
4. What is the CPU cost of translating commands and replaying work, and what memory is consumed by textures, command buffers and render targets?
5. Does the title sustain representative gameplay scenes on physical hardware?

**Recommendation:** build a renderer probe independently of the game first. Draw a clear, textured triangle, then add depth, alpha blending, texture formats/mips, render-to-texture, a UI pass and a representative Fast3D command stream. Log each unsupported feature and capture a frame. If this probe reveals a poor fit, compare a native xsdk GPU backend before investing in a Vulkan wrapper.

### Audio

The application uses a custom audio dependency path (dr_libs) and links Ogg/Vorbis/Opus libraries. SDL-xenon's audio bridge feeds xsdk's API, which expects six channels of big-endian float audio at 48 kHz in 256-frame chunks. The audio architecture must be traced to determine whether SDL actually owns playback in each configuration or whether SoH's custom path bypasses it.

Sources:
- https://github.com/HarbourMasters/Shipwright/blob/develop/soh/CMakeLists.txt
- https://github.com/xenosworks/SDL-xenon/blob/xenon/docs/README-xsdk.md

Required test sequence: silent boot; one sustained tone; Ogg/Vorbis; Opus; music/effects concurrently; pause/resume; long-running underrun and memory logging.

### Asset pipeline and host tools

The current root CMake creates host-oriented asset tools (Torch and the OTR packer) inside the same project as the game target. With a PowerPC cross toolchain, any executable built as part of that same configuration can accidentally be treated as a target executable. Split the workflow into:
- host tools built with the PC toolchain;
- user-local ROM extraction where applicable;
- generated OTR inputs;
- the Xbox-target application, which consumes only already-generated inputs.

Do not put ROMs, extracted copyrighted assets, or user-specific generated files into this repository. The current upstream docs state that the required ROM/asset preparation is a separate step.

Source:
- https://github.com/HarbourMasters/Shipwright/blob/develop/CMakeLists.txt
- https://github.com/HarbourMasters/Shipwright/blob/develop/docs/BUILDING.md

## Minimum gates, in order

1. **Toolchain smoke test:** build xsdk and its hello/triangle samples from the documented clean setup; record compiler versions and logs.
2. **Platform smoke test:** an Xbox-target .xex that logs, reads a controller, writes a preference file, plays a tone and exits cleanly.
3. **Graphics smoke test:** the renderer probe described above, tested on the intended console.
4. **Dependency closure:** build each required static dependency for the target and record licenses, patches, disabled optional systems and known limitations.
5. **Application slice:** start SoH, load its own UI, then a local save/game scene, only after the prior gates pass.

These gates have not yet been executed in this repository. This document records source findings and a test plan; it does not claim a successful target build.
