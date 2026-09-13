# Apply/check — EW4 r14-39 Post-Handoff 11

Required baseline: verified Post-Handoff 10 delta SHA-256
`dd6216b9fdbd5d2edc8917d4dc8cfb1b243a21724b8f9b0d5c47552393e6eeb5`.

Apply this ZIP over the cumulative r14-39 + P1..P10 `EW4_Web_Port_v0.61/` directory, preserving paths and allowing same-name replacement.

This checkpoint changes only UI/controller/source/test/audit files. It does not replace animation assets.

Expected after apply:
- original main-menu/campaign absolute geometry restored;
- main `指挥部` enters shared native `SceneDeployGeneral` flow rather than the legacy Web HQ card wall;
- HQ general cards open general info; battle deploy context remains functional;
- old Web HQ render/controller/CSS path absent;
- Service Worker cache: `ew4-port-v061-r14-39-posthandoff11-maincampaignui`;
- full JS regression: **76/76 PASS**;
- compact BILE: **1076/1076 PASS**;
- Machine Gun Finish corrected set: **18/18 PASS**.

Known next UI/controller gap: native Headquarters `btn_shop -> SceneShop` is proven but the dedicated SceneShop controller is intentionally not substituted with the battle-facility shop in P11.
