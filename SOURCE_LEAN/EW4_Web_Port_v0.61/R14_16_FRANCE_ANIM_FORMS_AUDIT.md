# EW4 Web Port r14-16 — France native animation + 568h forms recovery

Authority:
- Original APK: European War 4 v1.4.42, user-supplied.
- Original UI geometry: `assets/layout-568h.xml`.
- Native unit motion: `assets/xml/def_motion.xml` + `army_*.xml/.bin/.png` BILE resources.

## 1. France country-specific infantry animation pack
Merged into mainline:
- Militia fra 1/2/3
- Line Infantry fra 1/2/3
- Light Infantry fra 1/2/3
- Grenadier fra 1/2/3
- Guards fra 1/2/3

Totals:
- 15 France-specific unit definitions.
- 66 France-specific native motion assets.
- Together with the generic 15-unit pack: 30 native-animation unit definitions / 132 motion assets.
- Grenadier/Guards alternate `attack[1]` retained.
- Every runtime asset carries native `world_union`, per-frame bounds, fixed canvas, 24 FPS metadata and runtime sheet.
- Runtime chooses the country-specific key when that exact variant exists; unmatched nations continue using the existing static original pose rather than an incorrect generic animated substitute.

## 2. Original 568h form recovery
Recovered into the r14-15 reconstructed mainline through `r14_native_forms.css` and runtime changes.

### form_game
- pause: 541,0 / 37x37
- undo: 0,293 / 37x37
- next: 541,293 / 37x37
- AI skip replaces the left undo position during AI phase.
- action strip: 140,309 / 270x11; 33x33 action buttons.
- resource board restored.
- compact 110x48 facility summary restored.

### form_compaignlist
- stage list: 410,23 / 160x275
- intro: 42,232 / 345x88
- confirm: 468,298 / 80x22
- original `board_dialog_ex` composition restored.

### form_deploygeneral
- removed the r14-9 custom two-pane “units + generals” shell.
- shortcuts: 20,30 / 249,30 / 480,30.
- count marker: 255,43; number: 290,43.
- general grid: 30,85 / 508x204, six columns, 99 row height.
- native 58x79 small-general frame ratio restored.
- current gameplay bridge materializes selected generals onto battle units on deployment; the exact original native unit-target assignment controller remains a separate reverse-engineering gap.

### form_recruitunit
- 441x185 layout.
- 440x65 horizontal unit selector.
- 152x72 stats grid.
- 284x72 description group.
- selection + confirm replaces the old large facility Web card recruitment path.

### form_generalinfo / form_deployitem
- general info: 440x217 geometry.
- item picker: 353x261, 7-column native-shaped bank geometry.

### form_shop / form_exchange / form_recruitgeneral
- market: 440x259.
- shop: 425x259; seller + buyer inventory regions restored.
- tavern: 300x275; four 55px vertical candidate rows restored.

## Verification
- `node --check app.js`: PASS.
- 23/23 current JS test files PASS (including `test_original_forms_568h.js`).
- native animation integration: 30 units / 132 motions PASS.
- asset reference scan across index/CSS/app: 96 referenced assets, 0 missing.
- static HTTP smoke for index/app/sw/CSS/native animation manifest/original boards: 200.

## Explicit remaining fidelity gaps
- France is the first country-specific animated infantry family in mainline; Britain/Russia/Austria/Prussia/Ottoman and others still need batch conversion.
- cavalry, artillery, warship and fort full production animation coverage is not yet batch-integrated.
- native deployment unit-target controller is not completely reconstructed; current bridge preserves playability.
- original Merchant portrait from PKM is still not decoded.
- exact shop select-then-buy native controller and regroup state machine remain separate gaps.
- true on-device visual verification is still required.
