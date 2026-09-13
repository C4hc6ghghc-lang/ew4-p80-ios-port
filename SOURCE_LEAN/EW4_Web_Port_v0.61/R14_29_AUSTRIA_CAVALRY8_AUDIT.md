# EW4 Web Port v0.61 — r14-29 Austria Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-28 mainline (185 animated unit definitions / 776 native motion assets) and adds the complete Austria (`aus`) recruit cavalry roster from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_motion.xml` contains exact Austria-specific entries for all 8 recruit cavalry definitions:
- Light Cavalry aus 1/2
- Heavy Cavalry aus 1/2
- Guards Cavalry aus 1/2
- Armored Car aus 1/2

All 32 Austria motion assets were independently decoded from the original BILE containers. No Russia, Britain, France, or generic runtime sheet is substituted for an Austria unit.

### Austria Light Cavalry
- Light Cavalry aus 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Light Cavalry aus 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Austria Heavy Cavalry
- Heavy Cavalry aus 1: Ready 23f / UndoReady 11f / Attack 32f / Finish 9f
- Heavy Cavalry aus 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Austria Guards Cavalry
- Guards Cavalry aus 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Guards Cavalry aus 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal attack path: `Attack0 -> Reload -> Finish -> Ready`
- Guns-vs-warship/fort alternate path: `Attack1 -> Ready`

### Austria Armored Car
- Armored Car aus 1: Ready 12f / Attack 85f
- Armored Car aus 2: Ready 12f / Attack 85f
- Both original Attack motions retain `Motion@speed="2.5"`
- Proven attack chain: `Attack -> Ready`

All extracted motions retain the original 24 FPS base.

## Code implemented ✅
- Added 8 Austria-specific cavalry unit definitions.
- Added 32 Austria-specific native BILE motion assets.
- Main native-animation manifest advanced:
  - r14-28: 185 units / 776 motions
  - r14-29: **193 units / 808 motions**
- New runtime manifest: `assets/data/native_animation_core193.json`
- Source-pack label appended: `austria_cavalry8`
- Runtime loader now targets `native_animation_core193.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-29-austriacavalry`.

## Regression protection ✅
- All 185 pre-r14-29 unit records compare JSON-value identical after merge.
- All 776 pre-r14-29 asset records compare JSON-value identical after merge.
- All 808 runtime sheets exist and have valid PNG signatures.
- Austria cavalry integration assertions verify Light/Heavy UndoReady, Guards Cavalry Attack1 on both grades, normal/alternate attack chains, and Armored Car speed 2.5.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original Austria-specific UndoReady assets are preserved, but the exact external native-controller trigger remains unresolved. No guessed trigger was added.

### Motion@speed playback math ⏳
Armored Car attack `speed=2.5` is preserved as source data. Exact original native playback-duration math remains unresolved.

### Real iPhone verification ⏳
This exact r14-29 build has not yet been visually verified on the user's iPhone.

## Next recommended micro-batch
Proceed to Prussia (`pru`) complete cavalry 8, using the same country-specific extraction/integration pipeline and reporting after that single batch.
