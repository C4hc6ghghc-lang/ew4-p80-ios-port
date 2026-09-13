# EW4 Web Port v0.61 — r14-32 Spain Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-31 mainline (209 animated unit definitions / 872 native motion assets) and adds the complete **Spain (`spa`) recruit cavalry roster** from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256 remains:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
Spain has independent `spa` BILE cavalry resources; this batch does not substitute generic/French/British/etc. runtime sheets.

### Light Cavalry spa 1/2
- Grade 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Grade 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Proven current attack chain: `Attack -> Finish -> Ready`

### Heavy Cavalry spa 1/2
- Grade 1: Ready 23f / UndoReady 11f / Attack 33f / Finish 9f
- Grade 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Proven current attack chain: `Attack -> Finish -> Ready`

### Guards Cavalry spa 1/2
- Grade 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Grade 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal path: `Attack0 -> Reload -> Finish -> Ready`
- Alternate guns-vs-warship/fort path: `Attack1 -> Ready`

### Armored Car spa 1/2
- Both grades: Ready 12f / Attack 85f
- Original attack `Motion@speed` attribute = `2.5`
- Proven current attack chain: `Attack -> Ready`

All extracted BILE frames use the original **24 FPS** base.

## Code implemented ✅
- Added 8 Spain cavalry unit definitions.
- Added 32 Spain-specific native BILE motion assets.
- Runtime animation mainline advanced:
  - r14-31: 209 units / 872 motions
  - r14-32: **217 units / 904 motions**
- New runtime manifest: `assets/data/native_animation_core217.json`
- Source-pack label appended: `spain_cavalry8`
- Runtime loader now targets `native_animation_core217.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-32-spaincavalry`.

## Regression protection ✅
- All 209 pre-r14-32 unit records are verified JSON-value identical after merge.
- All 872 pre-r14-32 asset records are verified JSON-value identical after merge.
- Spain cavalry assertions verify 8/8 units, Guards Attack1 on both grades, Armored Car speed 2.5, and the proven attack chains above.
- All 904 runtime sheets must exist and have valid PNG signatures.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original Spain UndoReady assets are preserved, but the exact external native-controller condition that invokes them is still not proven. No trigger is invented.

### Motion@speed playback math ⏳
The original Armored Car attack `speed=2.5` metadata is preserved, but exact native playback-duration math is still unresolved and is not guessed.

### Real iPhone verification ⏳
This exact r14-32 build is not yet visually verified on the user's iPhone.

## Next recommended micro-batch
Proceed to **USA (`usa`) complete cavalry 8** only after r14-32 packaging/apply-check passes.
