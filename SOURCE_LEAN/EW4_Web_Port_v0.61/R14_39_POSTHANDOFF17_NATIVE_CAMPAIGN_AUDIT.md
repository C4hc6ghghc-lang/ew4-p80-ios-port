# R14-39 Post-Handoff 17 — Native Campaign Target / Hidden Stage Audit

## Frozen conclusion
P17 replaces the earlier Web/heuristic objective model with target data parsed directly from the original APK BTL binary layout and the native result-controller semantics.

## Native binary evidence
The original fresh-battle loader uses:
- 72-byte BTL header (`18 * int32`)
- country records: 180 bytes each
- ownership grid: `width * height` bytes
- map-state records: 16 bytes each
- unit-state records: 32 bytes each

Recovered native restore paths prove:
- map-state **byte 10** -> runtime map-cell target field (`+0x18`)
- unit-state **byte 19** -> runtime unit target field (`+0x54`)
- native counters at the recovered `0x57320 / 0x573a0` paths count target types 1 and 2 across map cells and attached units.

The old Web `objects[].raw` / `units[].raw` representation is shifted relative to those native records and is no longer authoritative for strategic targets. In particular, old object `raw[14]` is a facility/shop/tavern-related byte and must never be used as an objective type.

## Reproducible original corpus manifest
`tools_generate_native_campaign_targets.py` parses the original APK BTL corpus directly and generates:

`assets/data/native_campaign_targets.json`

Corpus: **101 BTL files**.

Recovered target census:
- map type1: **349**
- map type2: **5**
- unit type1: **185**
- unit type2: **6**

Generated manifest SHA-256:
`1c0b6e0e64b7e7e4d8e78313727041646bc851a6b4abcf1c60cfd1da3cec9979`

Original BTL corpus SHA-256 recorded by generator:
`a82fd1857eb7055aa53d6477ee1604003d6a63f937e08a67d25b0e8f58633c12`

A fresh regeneration from the extracted frozen APK is byte-identical to the production manifest.

## Type 1 campaign objectives
Type1 is the native red/main objective set. It contains both map targets and unit targets. Campaign result logic now:
- uses the original campaign country side field from each BTL country record;
- treats side1 and side2 as opposing primary sides;
- treats side3 as the independent hostile third side used by the native result aggregation;
- excludes side4 from primary hostility/outcome aggregation;
- counts friendly/hostile type1 targets by side, not simply `playerOwner` vs all other owners;
- defeats the player when an originally friendly red-objective set reaches zero;
- wins when the originally hostile red-objective set reaches zero;
- falls back to annihilation only when the corresponding side had no native red objectives.

The pristine original battle `b` is used for the initial objective snapshot even when restoring a saved battle. Therefore loading a save after captures/deaths cannot erase the original objective contract.

## Type 2 / hidden campaign stages
The corpus contains exactly **11** type2 triggers and original `def_battlelist.xml` contains exactly **11** hidden campaign stages. They map one-for-one:
- campaign1_04 -> campaign1_05
- campaign1_17 -> campaign1_18
- campaign2_04 -> campaign2_05
- campaign2_13 -> campaign2_14
- campaign3_11 -> campaign3_12
- campaign3_13 -> campaign3_14
- campaign4_10 (TUR) -> campaign4_11
- campaign4_10b (RUS) -> campaign4_12
- campaign5_04 -> campaign5_05
- campaign5_08 -> campaign5_09
- campaign6_08 -> campaign6_09

All 11 native type2 targets start hostile to the selected campaign side. Unit type2 targets clear on destruction; map type2 targets clear when captured into the player's/allied side.

Native victory-result disassembly additionally shows the type2 counter is evaluated on the campaign victory/result path: when the non-player type2 sum is zero, the next hidden-stage state is exposed. P17 therefore persists a secret-stage unlock on **victory result**, not at the instant a yellow target is touched.

`campaign4_10` is a genuine two-country branch. The original base/alternate BTL pair is preserved; TUR exposes 4_11 and RUS exposes 4_12. A hidden branch cannot chain-reveal its sibling.

## SceneSelBattle behavior
- `hide=1` rows do not block ordinary main-line progression.
- They remain non-selectable until their persistent secret unlock is set.
- Once unlocked, they are selectable normally.
- Main campaign completion continues to use the last non-hidden main-line stage (P16 rule).

## Campaign relations
Campaign-only owner relations now use the native BTL side field. This fixes the previous Web behavior where every non-player country was implicitly allied to every other non-player country. Conquest mode remains on the existing conquest relation controller.

## Visual/data integration
- Campaign objective markers are produced from the new native manifest, including unit targets that the old trigger JSON omitted.
- Service Worker caches `native_campaign_targets.json` for offline PWA use.
- Debug battle caption now reports native red/yellow target counts instead of the old misnamed objective table.

## Regression
- `test_native_campaign_targets_p17.js`: format/side/secret/branch/red-objective behavior.
- `test_native_campaign_targets_exhaustive_p17.js`: **87 campaign BTLs**, no instant false result; 84 hostile-red clear victory simulations; 83 friendly-red loss defeat simulations; **11/11** yellow secret clear simulations.
- `test_native_campaign_p17_integration.js`: production wiring/offline cache/no legacy target API.
- Full independent JS tree: **87 / 87 PASS**.

## Remaining caveat
P17 proves campaign objective and hidden-stage semantics. It does not claim final true-device pixel/touch/audio parity, and it does not complete the remaining GeneralInfo upgrade/regroup/rank/nobility controller work.
