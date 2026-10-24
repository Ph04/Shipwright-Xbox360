# Xbox 360 dependency and portability matrix

**Reviewed:** 2026-10-24  
**Status:** preliminary source-based inventory; no target dependency has been certified as built.

This matrix separates source presence from Xbox 360 build/runtime verification. The source baseline and exact submodule gitlinks are pinned in [BASELINE.md](BASELINE.md); none of those pins implies a successful target build.

| Component / subsystem | Evidence in current source | Xbox 360 assessment | Required action | Priority |
|---|---|---|---|---|
| Compiler and runtime | Shipwright asks for C23/C++20; xsdk supplies a custom PowerPC toolchain, C17 runtime and C++23 library support | Language support is promising, not a whole-program compatibility guarantee | Compile a small mixed C/C++ probe with exceptions, RTTI, filesystem, atomics, chrono, formatting and TLS; then compile actual target sources to expose unsupported builtins/ABI assumptions | P0 |
| CMake/platform selection | Root config has Windows/macOS/Linux/console-specific logic but no Xbox 360 target; xsdk uses CMAKE_SYSTEM_NAME=Generic | Existing target selection can choose the wrong feature path | Add a dedicated Xbox toolchain/profile and explicit feature guards; don't patch global defaults | P0 |
| SDL | Shipwright application CMake requests SDL2; available SDL-xenon is SDL 3.4.10 | Not source/API compatible by default; the port exposes dummy/offscreen video only | Inventory SDL2 calls and decide between SDL2 port and SDL3 adaptation; wrap controller, audio, timing, paths and lifecycle behind platform code | P0 |
| SDL2_net/network | SDL2_net is explicitly searched for/linked in application configuration | No Xbox SDL2_net port has been verified; multiplayer/networking is not needed to prove initial local boot | Search every call site, split optional network-dependent code, then test socket/runtime assumptions separately | P2 |
| Graphics selection | Pinned libultraship `da6daf1...` contains Direct3D 11, DXGI, Metal and OpenGL backends in `src/fast/backends`, but no Vulkan backend; generic non-Windows CMake defines `ENABLE_OPENGL` | No existing backend targets xsdk/Xenos; a Vulkan4Xenon route still needs a new adapter/backend | Add an explicit Xbox backend choice and implement the full `GfxRenderingAPI` operation set; prove it with a renderer probe | P0 |
| Fast3D shader generation | `gfx_opengl.cpp` generates GLSL at runtime from a pair of 64-bit shader keys; XSDK xost accepts SPIR-V, not GLSL | Vulkan4Xenon/xost covers SPIR-V-to-Xenos only; first-stage GLSL conversion and permutation coverage remain unproven | Capture real shader keys/sources, run `compile-fast3d-shader-dumps.sh`, record every accepted/refused stage, then choose an offline bundle or runtime frontend | P0 |
| Vulkan4Xenon | Vulkan 1.0 subset on xsdk; has a separate test .xex and hardware-tested port | Candidate substrate only; not conformant and not proven against Shipwright's renderer | Compare features, shaders, formats, pipeline state, depth/stencil, render targets, resolves, synchronization and measured CPU cost | P0 |
| SDL/ImGui UI | Pinned libultraship uses `imgui_impl_opengl3.cpp` and `imgui_impl_sdl2.cpp`; `Fast3dGui.cpp` directly initializes and submits through them | Neither SDL3's dummy/offscreen video nor the existing OpenGL ImGui renderer supplies an Xbox UI path | Port SDL events/input and implement an ImGui renderer on the selected Xenos/Vulkan4Xenon backend | P1 |
| Audio | SoH fetches dr_libs and links Ogg/Vorbis/Opus/OpusFile; SDL-xenon bridges SDL audio to xsdk | Requires target builds and confirmation of which playback path is used | Build codecs statically; implement/test a small tone and then game audio with correct channel layout, sample format and timing | P1 |
| Asset tools (Torch, OTR packer) | Root CMake builds tools alongside application | Host tools must not be accidentally cross-compiled for PowerPC | Separate host-tools configure/job from Xbox-target build; target build should consume prebuilt OTR files | P1 |
| Compression/archives | Root/LUS configuration includes zlib, bzip2, libzip, libpng; libultraship requires libzip | Individual C/C++ libraries may be portable, but none is yet target-verified here | Add one static library at a time, confirm cross-build and link closure, and note any filesystem/large-file assumptions | P1 |
| Data/config libraries | nlohmann-json, tinyxml2 and spdlog are required by libultraship | Likely portable candidates; compiler/runtime behavior and size still need measurement | Build/link smoke tests; set log sinks and file paths for console storage | P1 |
| Image/media libraries | libpng, stb_image, Ogg, Vorbis, Opus, OpusFile | Source availability does not prove target compiler/endianness/performance compatibility | Compile/link each dependency; exercise decoding with small test assets | P1 |
| Threads and synchronization | libultraship uses a thread pool; xsdk provides pthreads/C++ threads but documents hardware-thread placement and other caveats | Likely possible with explicit budgeting; scheduler/TLS differences may surface | Inventory worker count, affinity assumptions, thread_local, waits, priorities and shutdown order; cap worker pools during early bring-up | P1 |
| Scripting / dynamic modules | libultraship has optional TCC scripting and dynamic library loading options | Runtime compilation and shared/dynamic library assumptions complicate a first port | Disable optional scripting and dynamic module features in milestone 1; re-evaluate after static app boot works | P2 |
| Filesystem and saves | SDL-xenon documents game-relative base/preference paths; xsdk has documented storage APIs | Paths and available devices differ from desktop assumptions | Centralize config/save/log paths; test the actual target device and write failures | P1 |
| Memory and performance | Xbox 360 has shared CPU/GPU memory; xsdk notes GPU allocations have platform-specific behavior | Texture/target caches and translation overhead can dominate; no budget measured yet | Instrument total/free allocations, high-water marks, per-frame CPU/GPU time and texture-cache sizes from the first probe | P0 |
| ROM and copyrighted assets | Upstream build uses local ROM/asset extraction to create OTR files | User must supply lawful local inputs; don't store them in this repository | Keep asset generation out of source control and document generated files as local-only | P1 |

## Dependency versions and license follow-up

The upstream CMake files pin some fetched dependencies but also use package discovery for others. A release-grade inventory must record, for each dependency: exact version/commit, license, static/shared linkage, required symbols, patches, target build result and test evidence. This initial matrix does not assert that any dependency has compiled for PowerPC.

## Recommended order

1. Build the stock xsdk hello and triangle samples in a clean environment.
3. Build a target logging/input/audio/filesystem test.
4. Build the renderer probe and settle the graphics architecture.
5. Port dependency closure and only then enable the SoH application target.
