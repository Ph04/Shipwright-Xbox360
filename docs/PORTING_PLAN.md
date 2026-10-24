# Xbox 360 porting plan

## Phase 0 — Baseline and feasibility (current)

- [ ] Record upstream Shipwright revision and license.
- [ ] Inspect the current renderer abstraction and platform-specific source selection.
- [ ] Inspect xsdk, Vulkan4Xenon, and Dusklight-Xenon documentation and sample build flow.
- [ ] Build the smallest supported xsdk sample in a reproducible environment.
- [ ] Record whether the test is compile-only, emulator-tested, or verified on physical hardware.

**Exit criteria:** a documented toolchain setup and a reproducible minimal .xex test. Do not begin a broad source port before this passes.

## Phase 1 — Platform bring-up

- [ ] Add an Xbox 360 platform profile/build preset without changing upstream defaults.
- [ ] Implement a minimal entry point and main loop.
- [ ] Verify controller input, timing, filesystem access, logging, and clean shutdown.
- [ ] Test a simple Xenos clear/present path and capture evidence.

**Exit criteria:** stable test application with documented target hardware and test steps.

## Phase 2 — Dependency inventory and portability seams

For every direct and transitive dependency, record: required version/revision, license, API surface used, current xsdk port status, build-system changes, and unresolved blockers.

Priority areas:
- SDL/platform layer and event/input handling
- graphics abstraction and shader pipeline
- audio output and decoding
- threading, synchronization, timers
- filesystem, archives, compression, image decoding
- networking and platform services
- C/C++ standard library and compiler compatibility

Prefer small adapters behind existing interfaces. Avoid a wholesale rewrite until the minimum required APIs are mapped.

## Phase 3 — Renderer feasibility

- [ ] Identify the exact renderer implementation Shipwright selects on each platform.
- [ ] Map required graphics operations to either a Vulkan4Xenon-backed route or a native Xenos backend.
- [ ] Inventory shader formats, compilation tools, render targets, texture formats, synchronization, and presentation requirements.
- [ ] Build a focused renderer proof-of-concept independent of game logic.

**Decision gate:** continue with a Vulkan subset only if the required API features and performance costs are demonstrated. Otherwise estimate a native backend before committing to it.

## Phase 4 — Game integration

- [ ] Integrate upstream code in small, reviewable steps.
- [ ] Resolve dependency and compiler failures one at a time.
- [ ] Keep ROM/asset extraction as a user-supplied local step; do not commit ROMs or extracted copyrighted assets.
- [ ] Add startup diagnostics and explicit unsupported-feature messages.

## Phase 5 — Validation and packaging

- [ ] Compile from a clean checkout.
- [ ] Test on a supported emulator if available, then physical hardware.
- [ ] Validate input, audio, graphics, save/config paths, stability, and performance.
- [ ] Publish artifacts only after the build and test level are stated accurately.

## Required status labels

- **Not started** — no implementation exists.
- **Implemented** — code exists; not necessarily built.
- **Build verified** — clean build completed with recorded logs.
- **Emulator tested** — named emulator and test steps recorded.
- **Hardware verified** — test completed on physical Xbox 360 with evidence.

These labels are deliberately distinct.
