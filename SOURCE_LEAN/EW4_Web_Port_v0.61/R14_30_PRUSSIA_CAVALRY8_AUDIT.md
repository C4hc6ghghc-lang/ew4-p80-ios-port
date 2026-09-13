# EW4 Web Port v0.61 — r14-30 Prussia Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-29 mainline (193 animated unit definitions / 808 native motion assets) and adds the complete Prussia (`pru`) recruit cavalry roster from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_motion.xml` contains exact Prussia-specific entries for all 8 recruit cavalry definitions:
- Light Cavalry pru 1/2
- Heavy Cavalry pru 1/2
- Guards Cavalry pru 1/2
- Armored Car pru 1/2

All 32 Prussia motion assets were independently decoded from the original BILE containers. No Austria, Russia, Britain, France, or generic runtime sheet is substituted for a Prussia unit.

### Prussia Light Cavalry
- Light Cavalry pru 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Light Cavalry pru 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Prussia Heavy Cavalry
- Heavy Cavalry pru 1: Ready 23f / UndoReady 11f / Attack 32f / Finish 9f
- Heavy Cavalry pru 2: Ready 27f / UndoReady 11f / Attack 31f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Prussia Guards Cavalry
- Guards Cavalry pru 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Guards Cavalry pru 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal attack path: `Attack0 -> Reload -> Finish -> Ready`
- Guns-vs-warship/fort alternate path: `Attack1 -> Ready`

### Prussia Armored Car
- Armored Car pru 1: Ready 12f / Attack 85f
- Armored Car pru 2: Ready 12f / Attack 85f
- Both original Attack motions retain `Motion@speed="2.5"`
- Proven attack chain: `Attack -> Ready`

All extracted motions retain the original 24 FPS base.

## Code implemented ✅
- Added 8 Prussia-specific cavalry unit definitions.
- Added 32 Prussia-specific native BILE motion assets.
- Main native-animation manifest advanced:
  - r14-29: 193 units / 808 motions
  - r14-30: **201 units / 840 motions**
- New runtime manifest: `assets/data/native_animation_core201.json`
- Source-pack label appended: `prussia_cavalry8`
- Runtime loader now targets `native_animation_core201.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-30-prussiacavalry`.

## Regression protection ✅
- All 193 pre-r14-30 unit records compare JSON-value identical after merge.
- All 808 pre-r14-30 asset records compare JSON-value identical after merge.
- All 840 runtime sheets exist and have valid PNG signatures.
- Prussia cavalry integration assertions verify Light/Heavy UndoReady, Guards Cavalry Attack1 on both grades, normal/alternate attack chains, and Armored Car speed 2.5.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original Prussia-specific UndoReady assets are preserved, but the exact external native-controller trigger remains unresolved. No guessed trigger was added.

### Motion@speed playback math ⏳
Armored Car attack `speed=2.5` is preserved as source data. Exact original native playback-duration math remains unresolved.

### Real iPhone verification ⏳
This exact r14-30 build has not yet been visually verified on the user's iPhone.

## Next recommended micro-batch
Proceed to Ottoman (`tur`) complete cavalry 8, using the same country-specific extraction/integration pipeline and reporting after that single batch.
