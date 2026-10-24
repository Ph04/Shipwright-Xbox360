# Source baseline and license review

**Recorded:** 2026-10-24  
**Purpose:** keep source-level conclusions reproducible. These revisions are research references, not evidence of a successful target build.

## Main source baseline

| Repository | Exact revision | What it anchors |
|---|---|---|
| [HarbourMasters/Shipwright](https://github.com/HarbourMasters/Shipwright/tree/2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41) | `2827fc2a0f56a9cdc18a87adf8c1bb7e91315f41` | Main project commit; committed 2026-10-20 |
| [kenix3/libultraship](https://github.com/kenix3/libultraship/tree/da6daf1a50a5e46d6641408d52227e31e85e46df) | `da6daf1a50a5e46d6641408d52227e31e85e46df` | Exact libultraship gitlink stored by the Shipwright commit |
| [HarbourMasters/Torch](https://github.com/HarbourMasters/Torch/tree/2ab12fe9660aec04e02ee89fe81baed304a1a1d6) | `2ab12fe9660aec04e02ee89fe81baed304a1a1d6` | Exact Torch gitlink stored by the Shipwright commit |

The Shipwright commit metadata reports 2026-10-20 05:40:37 UTC. The gitlink pins above were read from GitHub's contents API for the exact Shipwright commit, rather than inferred from the branch names in .gitmodules.

## Supporting research snapshots

| Repository | Exact revision inspected | Scope |
|---|---|---|
| [xenosworks/xsdk](https://github.com/xenosworks/xsdk/tree/2c4599b31066efcf67be099673287fbec786ef14) | `2c4599b31066efcf67be099673287fbec786ef14` | Toolchain, runtime and platform APIs |
| [xenosworks/vulkan4xenon](https://github.com/xenosworks/vulkan4xenon/tree/b79913b407504b1e1663e74b14579cd91d2e7040) | `b79913b407504b1e1663e74b14579cd91d2e7040` | Vulkan subset and graphics roadmap |
| [xenosworks/SDL-xenon](https://github.com/xenosworks/SDL-xenon/tree/adb87a744ae056f1849718770cf198fa6c4899f9) | `adb87a744ae056f1849718770cf198fa6c4899f9` | SDL 3.4.10 Xbox port notes and API bridge |
| [xenosworks/dusklight-xenon](https://github.com/xenosworks/dusklight-xenon/tree/d04e793671ca50bf3dad5dc3f5a16a45974558e3) | `d04e793671ca50bf3dad5dc3f5a16a45974558e3` | Reference homebrew game port and build flow |

These supporting revisions are evidence references only. Before importing or adapting code, re-check their licenses and dependencies at the exact files/commits being used.

## License review status

- libultraship at the pinned gitlink contains an MIT LICENSE: https://github.com/kenix3/libultraship/blob/da6daf1a50a5e46d6641408d52227e31e85e46df/LICENSE
- Torch at the pinned gitlink contains an MIT LICENSE: https://github.com/HarbourMasters/Torch/blob/2ab12fe9660aec04e02ee89fe81baed304a1a1d6/LICENSE
- xsdk exposes an MIT LICENSE at the reviewed revision: https://github.com/xenosworks/xsdk/blob/2c4599b31066efcf67be099673287fbec786ef14/LICENSE
- Vulkan4Xenon exposes an MIT LICENSE at the reviewed revision: https://github.com/xenosworks/vulkan4xenon/blob/b79913b407504b1e1663e74b14579cd91d2e7040/LICENSE.
- The root listing for the inspected Shipwright commit did not show a top-level LICENSE file. This is not a legal conclusion about the project: the license/permission status for any source to be copied or redistributed still needs an explicit review of upstream notices and policies.
- Every dependency brought into the port needs its own license and notice record. Build scripts must not pull ROMs, extracted copyrighted assets, or other user-supplied content into a distributable artifact.

## Baseline rules

1. Use the three main source SHAs above for initial source diffs and code reviews.
2. If upstream advances, perform an explicit comparison first; do not silently float the target to a new branch tip.
3. Record every intentional source change against the relevant pinned baseline.
4. Keep host-built asset tools separate from the PowerPC target build.
5. A pinned source tree is not a build result. Build, emulator and physical-console verification remain separate status levels.
