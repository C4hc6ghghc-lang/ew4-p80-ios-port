# HANDOFF — R14-39 POSTHANDOFF24 Native UnitInfo + Campaign Growth Chain Frozen

Date: 2026-09-10
Parent: P23 Native Defense + Pause Frozen
Status: FROZEN / trusted checkpoint

## Completed in P24

1. `form_unitinfo` controller semantics were corrected against original `layout-568h.xml` plus preserved native `.so` evidence.
   - Native 330x187 shell retained.
   - Left unit image now uses original recruit/build art rather than battle READY art.
   - 1/2/3 formation layering uses `buildmaker.png` + the original family marker lookup.
   - Ability grid restored to native attack+formation / HP+food / range+move structure.
   - Web-only morale, training-level and training-defense cells were removed from this form.
   - Lower `group_desc` now dynamically shows native unit `name_%s` + `desc_%s`; the incorrect equipment-list substitute was removed.
2. Existing `form_useitem` was audited and accepted rather than rewritten: 280x175 geometry, native five item IDs 11-15, native validation/effects/action consumption, supply SFX/recover effect, and the user's non-consuming consumable mod remain intact.
3. Added a true cross-module campaign growth regression:
   improved result -> score-delta Stars -> tech purchases -> locked-unit unlock -> recruit training -> Farm/Financial/Factory bonuses -> Dock permission -> fort unlock -> Battle Tech Snapshot -> BattleSave schema 6 -> JSON round-trip -> snapshot isolation from later meta upgrades.
4. Service Worker cache bumped to `ew4-port-v061-r14-39-posthandoff24-unitinfo` and all UnitInfo runtime assets were added.
5. Root `START_HERE.md` was corrected; it had stale P18 text even though CURRENT_STATUS had advanced to P23.

## Verification

- Independent Node `test_*.js`: 101/101 PASS.
- Service Worker CORE referenced files: 290/290 present.
- P21 campaign-upgrade guard files are byte-identical to P23 parent:
  - `native_upgrade_core.js`
  - `battle_save_core.js`
  - `assets/data/native_warzone_tech.json`
  - `assets/data/def_warzonetech.xml`
- `node --check app.js`: PASS.
- Test invocation must run with cwd `SOURCE_LEAN/EW4_Web_Port_v0.61`; several historical tests intentionally resolve assets relative to that source root.

## Do not overclaim

- This does not constitute real-iPhone visual/touch verification.
- UnitInfo controller semantics are now much closer to native and backed by layout/.so evidence, but exact native pixel rendering of `tmp_commander`, marker anchoring and font metrics still require true-device comparison.
- The new campaign chain is a deterministic regression, not yet a many-stage hours-long live playthrough.

## Recommended next

1. Continue residual Scene/controller census beyond UnitInfo; only rewrite a flow when a proven native gap exists.
2. Add repeated multi-stage save/load/replay integration stress, not just one deterministic chain.
3. Finish true-device iPhone calibration: Dock `transportship1/2`, touch/pinch feel, particle z-order, exact font/marker alignment and audio timing.
