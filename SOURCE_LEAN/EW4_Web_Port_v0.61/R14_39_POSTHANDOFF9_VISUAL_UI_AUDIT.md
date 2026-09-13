# r14-39 Post-Handoff 9 — Visual / UI completion pass audit

Baseline: cumulative r14-39 + post-handoff patches 1..8.

## What this patch actually closes

### Combat visual source coverage
- Expanded the simple particle runtime from the previously hand-wired attack subset to every `def_effectsanim.xml` particle XML whose source file actually exists in the APK.
- Runtime data now contains **23 effect groups / 65 emitters**.
- The four referenced names whose XML source is absent from this APK — `effect_airstrike`, `effect_airgun`, `effect_airfire`, `effect_parachuter` — remain unresolved and are not fabricated.
- Added native impact-effect selection so attack-side fire/muzzle cues can be followed by native target-side strike visuals.
- Reversed impact selection uses native damage bands `<=10 / 11..25 / 26..40 / >=41`, body/wood/stone/cold/land/sea families, and the Rocket army-id 13 `rocketstrike` special case.
- Impact cues are scheduled at the end of the authored attack motion rather than at muzzle-fire time.

### Options controller
- `GameSpeed` is a real 1..5 setting and controls the already-reversed native camera motor.
- `ShowGrids` is a persisted native boolean and actually changes battle-grid presentation.
- Options use draft/commit/cancel semantics instead of mutating settings merely by opening the form.

### Original-form UI recovery
- Rebuilt battle `form_unitinfo` around the original 330x187 geometry: unit/resource block, 4x3 ability grid, commander block, equipment description region.
- Kept `form_recruitunit` at its already-correct 441x185 content geometry and restored native user-window title/close/confirm chrome.
- Tightened victory/failure panels to their original 568h form dimensions and retained native decorative geometry.
- Replaced the Web tutorial card grid with original `form_tutorials` **250x200**, containing three **145x40** buttons at y=40/85/130.
- Restored `form_playnotice` **400x225** with the original `html_notice` Chinese content in a 390x186 scrollable framed body.

## Deliberately unresolved / not falsely claimed
- `SceneSelCountry` controller is not yet considered closed. `layout-568h.xml` proves the final chooser is 234x150 with two 85x67 cards, but native code also proves that scene receives exactly two country codes from an upstream conquest-country-list item. The upstream pairing/list semantics are still being reversed, so the current multi-country Web selector is not replaced by an invented two-card flow yet.
- The four absent air/parachute effect XMLs are not reconstructed.
- Full animation coverage remains 265/877 unit definitions and 1076/3519 motions; 1076/1076 parity means the migrated compact BILE set is correct, not that all APK motions have been ported.
- Victory reward/list controller conditions still need a dedicated native audit before claiming complete controller parity.

## Regression
- Full JS suite: **73/73 PASS**.
- Compact BILE full parity: **1076/1076 PASS**.
- Machine Gun Finish corrected set: **18/18 PASS**.
