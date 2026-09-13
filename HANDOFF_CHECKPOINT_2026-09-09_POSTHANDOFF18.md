# EW4 Web Port 0.61 — Post-Handoff 18 Native General Frozen

Date: 2026-09-09

## Authoritative baseline
This checkpoint supersedes Post-Handoff 17. P1-P17 remain frozen; P18 replaces the remaining simplified HQ general-management controller with the recovered native GeneralInfo / GeneralUpgrade / Regroup / DeployItem flow and native battle growth.

Read:
1. `CURRENT_STATUS.json`
2. `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF18_NATIVE_GENERAL_AUDIT.md`
3. `TEST_RESULTS_POSTHANDOFF18_90_OF_90_PASS.txt`

## P18 frozen content
- `SceneGeneralInfo` boundary restored: details expose Regroup and Item; rank/nobility purchases are not fake `+1` buttons inside GeneralInfo.
- Independent `SceneGeneralUpgrade` flow with recovered military/nobility growth thresholds, remaining-progress price formulas and 3600-medal all-full cap.
- MOD overlay is backend-only: the UI displays original medal prices, but player medals are not decremented.
- Persistent `rankProgress` / `nobilityProgress` added with old-save migration.
- Regroup uses recovered separate military/nobility retention tables, 300/60 base transferable progress, automatic cross-level settlement and seven teaching-skill stat bonuses (cap 5).
- Native Regroup source semantics preserved: source general is deleted and its equipped items disappear; explicit empty equipment override prevents item resurrection on re-recruit.
- `form_deployitem` rebuilt at original 353x261 geometry: previous/next owned general, rank/nobility/life/apply group, two equipment slots, description panel, full 28-slot ItemBank grid and explicit Equip commit button. The old instant Web equipment picker is removed.
- Native battle Military growth: 2x actual damage inflicted by the acting unit.
- Native battle Nobility growth: on kill, `(victim grade + 1)`, doubled when the defeated unit carries a commander.
- Battle growth item priority recovered: matching equipment (`function=1` nobility / `function=2` military) overrides skill multiplier; otherwise Nobility skill = 1.5x, War Expert = 1.4x, War Master = 1.8x. Positive native float conversion is reproduced with floor/truncation.
- Only player-controlled generals actually owned in HQ mutate persistent general growth; scenario/enemy commanders do not pollute HQ progression.
- Rank level-up during battle synchronizes the player-mod rank HP bonus immediately.

## Verification
- `native_general_core.js` syntax: PASS.
- `app.js` syntax: PASS.
- Dedicated P18 native general core/growth tests: PASS.
- Dedicated P18 production integration test: PASS.
- Dedicated native DeployItem geometry/controller test: PASS.
- Full independent JS tree: **90 / 90 PASS**.

## Do not regress
- Do not restore `rank + 1` / `nobility + 1` Web handlers in GeneralInfo.
- Do not collapse GeneralInfo and GeneralUpgrade into one Web panel.
- Do not restore `inventoryEquipmentPool/openEquipmentPicker/setEquipmentSlot`; DeployItem uses the 28-slot ItemBank and explicit Equip commit.
- Do not stack growth skill multipliers on top of matching growth equipment; native equipment wins.
- Do not award persistent HQ growth to enemy or non-owned fixed scenario commanders.
- Do not remove the existing hidden infinite medals/badges MOD merely because original prices are visible.

## Next major target
Residual Web substitute controller audit, especially remaining HQ commander modification-only flows such as dismissal/refund behavior, then cross-system long-session/save integration and true-device iPhone visual/audio/touch calibration.
