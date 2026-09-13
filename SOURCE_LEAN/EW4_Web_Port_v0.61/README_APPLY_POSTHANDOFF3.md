# Apply EW4 r14-39 post-handoff patch 3

Baseline required: **post-handoff patch 2 (artillery visual)** applied to the frozen r14-39 handoff tree.

Copy/merge the contained `EW4_Web_Port_v0.61/` over the existing project root and allow replacement of same-name files.

This patch adds the original Rocket grade 1/2 three-shot visual timeline (`effect_rocket1.xml`) and does not change gameplay stats.

After apply:
- Service Worker cache: `ew4-port-v061-r14-39-rocketvisual3`
- Full JS regression target: **60/60 PASS**
