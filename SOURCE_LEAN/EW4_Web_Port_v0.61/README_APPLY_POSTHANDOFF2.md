# Apply EW4 r14-39 post-handoff patch 2

Baseline: `EW4_r14-39_POSTHANDOFF1_INFITEM_MGVIS_DELTA.zip` already applied to the frozen 2026-09-08 2254 r14-39 handoff tree.

Overlay the `EW4_Web_Port_v0.61/` directory from this ZIP onto that tree, preserving paths and replacing same-name files.

This patch adds original Light/Heavy/Siege Artillery visual timelines and the required whole-effect rotation correction. It does not add rocket or naval visuals.

Expected regression result after apply: **59/59 PASS**.
Service Worker cache: `ew4-port-v061-r14-39-artilleryvisual2`.
