# Fast3D shader pipeline: Xbox 360 feasibility

**Reviewed:** 2026-10-24  
**Baseline:** Shipwright `2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41`, libultraship `da6daf1a50a5e46d6641408d52227e31e85e46df`, xsdk `2c4599b31066efcf67be099673287fbec786ef14`, Vulkan4Xenon `b79913b407504b1e1663e74b14579cd91d2e7040`.  
**Status:** source analysis only; no shader or game build has been validated for Xbox 360.

## 1. What the current Fast3D renderer does

In the pinned libultraship source, `GfxRenderingAPIOGL::CreateAndLoadNewShader(shader_id0, shader_id1)`:

1. Derives combiner features from the two shader IDs through `gfx_cc_get_features`.
2. Builds vertex and fragment GLSL source in the host-side C++ code.
3. Calls OpenGL's `glCreateShader`, `glShaderSource` and `glCompileShader` for the two stages.
4. Creates and links a GL program, then caches the program for later draws.

This is not just selection of precompiled, fixed shaders. The source generation and compile step are a core part of the existing Fast3D renderer.

Source: [pinned gfx_opengl.cpp](https://github.com/kenix3/libultraship/blob/da6daf1a50a5e46d6641408d52227e31e85e46df/src/fast/backends/gfx_opengl.cpp).

## 2. What XSDK and Vulkan4Xenon actually provide

The XSDK API `xsdk_xsc_compile` accepts **SPIR-V words**, compiles them to a Xenos shader container, and returns structured metadata describing uniforms, samplers, constants and other resource bindings. `xsdk_shader_load` then loads a generated container into GPU memory.

Source: [pinned xsdk xsc.h](https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/include/xsdk/xsc.h) and [shader.h](https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/include/xsdk/shader.h).

Vulkan4Xenon accepts SPIR-V through `vkCreateShaderModule`. Its shader tools can bundle known shaders ahead of time; when a SPIR-V shader is not in the bundle, the implementation can compile it with xsdk's xost compiler on the console and cache it. That is valuable runtime support, but the input is still SPIR-V—not GLSL source text.

Source: [pinned Vulkan4Xenon README](https://github.com/xenosworks/vulkan4xenon/blob/b79913b407504b1e1663e74b14579cd91d2e7040/README.md).

**Therefore:** Vulkan4Xenon can cover the SPIR-V-to-Xenos stage; it does not, by itself, replace the GLSL frontend that Fast3D currently receives from desktop OpenGL.

## 3. Candidate approaches

### A. Compile generated GLSL on the Xbox

Port or embed the GLSL-to-SPIR-V frontend (likely glslang), feed the resulting SPIR-V to Vulkan4Xenon/xost, and cache the resulting shader modules. The generator can initially reuse the existing Fast3D shader logic.

**Advantages:** shaders generated from new render states can work without having every combination known in advance.

**Risks to measure:** PowerPC compiler compatibility, static executable growth, peak memory during compilation, first-seen shader stalls, additional dependency/license obligations and any GLSL features xost refuses. Do not assume this is too large or feasible without measuring a minimal proof.

### B. Precompile observed Fast3D shader permutations

Instrument a supported desktop reference build to record each `(shader_id0, shader_id1)` pair and the generated GLSL. Build a host-side tool that compiles those shaders into SPIR-V and xost containers, then package them with the title and load by key.

**Advantages:** removes the GLSL frontend from the console and makes first use more predictable.

**Risks:** a captured list is only as complete as the scenes, settings and effects actually exercised. A cache miss must be detectable and logged; never silently substitute an incorrect shader. Proving complete coverage for all supported content may be more difficult than the shader compiler itself.

### C. Redesign the Fast3D shader generation path

Change the shader representation to a more constrained or precompiled pipeline designed for Xenos. This could remove the GLSL frontend but is a deeper renderer change, with its own correctness and performance validation.

**Advantages:** architecture can be optimized for the target.

**Risks:** largest rewrite, and there is no evidence yet that the simpler representation covers all existing combiner and framebuffer behavior.

For an actionable setup to collect the generated pairs described below, use [SHADER_TRACE.md](SHADER_TRACE.md) and the pinned-source helper [apply-fast3d-shader-trace.sh](../tools/apply-fast3d-shader-trace.sh).

## 4. Recommended experiments, in order

1. **Host shader trace:** build the pinned desktop renderer, log every distinct shader key, generated source hash, and any shader compile failures during representative scene coverage. Do not store game ROMs or copyrighted extracted assets in this repository.
2. **Offline compiler probe:** compile a representative set of generated GLSL through a pinned glslang version, then through xsdk's `xsdk_xsc_compile`. Record accepted/refused status and the refusal message for every key.
3. **Offline batch experiment:** run [compile-fast3d-shader-dumps.sh](../scripts/compile-fast3d-shader-dumps.sh) against captured source and keep the manifest/logs; report the exact rejected shader keys and xost refusal messages.
4. **Target compile probe:** build a tiny .xex that loads a known SPIR-V shader, invokes the runtime xost path, draws a result and records memory/latency. This verifies the target API before integrating the whole Fast3D backend.
5. **Dynamic-frontend spike:** separately compile/link a small GLSL frontend for the PowerPC target and measure executable size, peak allocated bytes, time for the first shader and cache-hit time. Include shader sources with the constructs used by the real Fast3D generator.
6. **Decision:** compare complete-cache coverage and runtime compilation cost. Choose A, B or C only with logs and measured evidence. If no path has acceptable coverage and cost, treat the renderer port as blocked rather than hiding the problem behind a stub.

## 5. Required diagnostics in any prototype

For each shader key, log:

- Both 64-bit Fast3D shader IDs and a stable generated-source hash.
- Whether the shader was a cache hit, compiled at runtime or loaded from a packaged bundle.
- GLSL frontend status, xost status and the exact refusal message, when present.
- Build/version hashes for the GLSL frontend, xost and shader bundle.
- Compile duration, cache-write/read duration and approximate peak memory.
- The first draw/pipeline that consumes the resulting shader.

Rate-limit repeated failures, but preserve a count and a summary. A shader-compile failure must return an explicit error to the renderer; it should not crash without diagnostic context.

## Acceptance criteria

The shader path is not considered viable until a target test demonstrates runtime shader use, cached reuse, a controlled unsupported-shader failure, and no shader-cache corruption after restart. Before full game integration, the generated source and SPIR-V feature subset must be checked against the actual shader set—not just the single triangle sample.

This document establishes a source-informed test plan only. No Xbox 360 Fast3D shader has been compiled or rendered by this repository yet.
