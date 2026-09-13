# EW4 Web Port 0.61 — Post-Handoff 17 Native Campaign Frozen

Date: 2026-09-09

## Authoritative baseline
This checkpoint supersedes Post-Handoff 16 for future work. P1-P16 remain frozen and P17 adds the recovered native campaign target/hidden-stage controller.

Read:
1. `CURRENT_STATUS.json`
2. `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF17_NATIVE_CAMPAIGN_AUDIT.md`
3. `TEST_RESULTS_POSTHANDOFF17_87_OF_87_PASS.txt`

## P17 frozen content
- Recovered original BTL strategic target layout from native loader, eliminating the false old `raw[14]` objective model.
- Direct original-APK manifest: 101 BTLs; map type1 349, map type2 5, unit type1 185, unit type2 6.
- Native type1 red objective result behavior for both map and unit targets.
- Native campaign side relations (1/2 primary opponents, 3 hostile third side, 4 neutral/excluded from primary outcome).
- Exact 11/11 type2 trigger -> hidden campaign-stage mapping.
- Hidden stages no longer block ordinary main-line progression and become selectable only after secret unlock.
- Type2 secret unlock persists on the campaign victory-result path, matching recovered native control flow.
- campaign4_10 TUR/RUS alternate BTL branch exposes only its corresponding hidden stage.
- Campaign target visual list and offline cache use the new manifest.
- Pristine-battle initial target snapshot survives save restore semantics.

## Verification
- Fresh generator run from extracted original APK is byte-identical with production `native_campaign_targets.json`.
- Manifest SHA-256: `1c0b6e0e64b7e7e4d8e78313727041646bc851a6b4abcf1c60cfd1da3cec9979`.
- Exhaustive campaign behavior replay covers 87 campaign BTLs including variants.
- Full independent JS tree: **87 / 87 PASS**.

## Do not regress
- Do not restore target inference from legacy `objects[].raw` / `units[].raw` parser guesses.
- Do not make all non-player campaign countries allies; campaign now uses original side data.
- Do not expose all `hide=1` stages by default and do not let a hidden branch reveal its sibling.
- Do not make hidden stages block the next visible main-line stage.
- Do not move type2 unlock persistence to arbitrary touch/kill time; recovered native result path evaluates it on campaign victory.

## Next major target
GeneralInfo / commander management controller parity: upgrade, regroup/organization, rank, nobility, equipment and remaining original flows. Then perform a residual Web-substitute controller audit and true-device calibration.
