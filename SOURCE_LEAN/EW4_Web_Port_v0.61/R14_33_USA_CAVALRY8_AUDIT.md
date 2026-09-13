# EW4 Web Port v0.61 — r14-33 USA Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from verified r14-32 (217 animated unit definitions / 904 native motion assets) and adds the complete **United States (`usa`) recruit cavalry roster** from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256 remains:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
USA has independent `usa` BILE cavalry resources; this batch does not substitute generic/Spain/Ottoman/etc. runtime sheets.

### Light Cavalry usa 1/2
- Grade 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Grade 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Proven current attack chain: `Attack -> Finish -> Ready`

### Heavy Cavalry usa 1/2
- Grade 1: Ready 23f / UndoReady 11f / Attack 32f / Finish 9f
- Grade 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Proven current attack chain: `Attack -> Finish -> Ready`

### Guards Cavalry usa 1/2
- Grade 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Grade 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal path: `Attack0 -> Reload -> Finish -> Ready`
- Alternate guns-vs-warship/fort path: `Attack1 -> Ready`

### Armored Car usa 1/2
- Both grades: Ready 12f / Attack 85f
- Original attack `Motion@speed` attribute = `2.5`
- Proven current attack chain: `Attack -> Ready`

All extracted BILE frames use the original **24 FPS** base.

## Code implemented ✅
- Added 8 USA cavalry unit definitions.
- Added 32 USA-specific native BILE motion assets.
- Runtime animation mainline advanced:
  - r14-32: 217 units / 904 motions
  - r14-33: **225 units / 936 motions**
- New runtime manifest: `assets/data/native_animation_core225.json`
- Source-pack label appended: `usa_cavalry8`
- Runtime loader now targets `native_animation_core225.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-33-usacavalry`.

## Regression protection ✅
- All 217 pre-r14-33 unit records are verified JSON-value identical after merge.
- All 904 pre-r14-33 asset records are verified JSON-value identical after merge.
- USA cavalry assertions verify 8/8 units, Guards Attack1 on both grades, Armored Car speed 2.5, and proven attack chains.
- All 936 runtime sheets exist and have valid PNG signatures.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original USA UndoReady assets are preserved, but the exact external native-controller condition that invokes them is still not proven. No trigger is invented.

### Motion@speed playback math ⏳
The original Armored Car attack `speed=2.5` metadata is preserved, but exact native playback-duration math is still unresolved and is not guessed.

### Real iPhone verification ⏳
This exact r14-33 build is not yet visually verified on the user's iPhone.

## Cavalry main-country milestone
With r14-33, the standardized main-country cavalry8 production line is complete for:
- generic
- France
- Britain
- Russia
- Austria
- Prussia
- Ottoman
- Spain
- USA

This does **not** mean all country/mini-state cavalry visuals in the APK are complete; country-code/visual-code audit remains necessary for smaller historical states.

## Next recommended micro-batch
Do not immediately claim cavalry as globally complete. The next major production family should be the **generic artillery 8** template (Light Artillery 1/2, Heavy Artillery 1/2, Siege Artillery 1/2, Rocket 1/2), with native state-machine audit before country-specific artillery mass production.
