# EW4 Web Port v0.61 — r14-28 Russia Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-27 mainline (177 animated unit definitions / 744 native motion assets) and adds the complete Russia (`rus`) recruit cavalry roster from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_motion.xml` contains exact Russia-specific entries for all 8 recruit cavalry definitions:
- Light Cavalry rus 1/2
- Heavy Cavalry rus 1/2
- Guards Cavalry rus 1/2
- Armored Car rus 1/2

All 32 Russia motion assets were independently decoded from the original BILE containers. No Britain, France, or generic runtime sheet is substituted for a Russia unit.

### Russia Light Cavalry
- Light Cavalry rus 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Light Cavalry rus 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Russia Heavy Cavalry
- Heavy Cavalry rus 1: Ready 23f / UndoReady 11f / Attack 32f / Finish 9f
- Heavy Cavalry rus 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Proven attack chain: `Attack -> Finish -> Ready`

### Russia Guards Cavalry
- Guards Cavalry rus 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Guards Cavalry rus 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal attack path: `Attack0 -> Reload -> Finish -> Ready`
- Guns-vs-warship/fort alternate path: `Attack1 -> Ready`

### Russia Armored Car
- Armored Car rus 1: Ready 12f / Attack 85f
- Armored Car rus 2: Ready 12f / Attack 85f
- Both original Attack motions retain `Motion@speed="2.5"`
- Proven attack chain: `Attack -> Ready`

All extracted motions retain the original 24 FPS base.

## Code implemented ✅
- Added 8 Russia-specific cavalry unit definitions.
- Added 32 Russia-specific native BILE motion assets.
- Main native-animation manifest advanced:
  - r14-27: 177 units / 744 motions
  - r14-28: **185 units / 776 motions**
- New runtime manifest: `assets/data/native_animation_core185.json`
- Source-pack label appended: `russia_cavalry8`
- Runtime loader now targets `native_animation_core185.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-28-russiacavalry`.

## Regression protection ✅
- All 177 pre-r14-28 unit records compare JSON-value identical after merge.
- All 744 pre-r14-28 asset records compare JSON-value identical after merge.
- All 776 runtime sheets exist and have valid PNG signatures.
- Russia cavalry integration assertions verify Light/Heavy UndoReady, Guards Cavalry Attack1 on both grades, normal/alternate attack chains, and Armored Car speed 2.5.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original Russia-specific UndoReady assets are preserved, but the exact external native-controller trigger remains unresolved. No guessed trigger was added.

### Motion@speed playback math ⏳
Armored Car attack `speed=2.5` is preserved as source data. Exact original native playback-duration math remains unresolved.

### Real iPhone verification ⏳
This exact r14-28 build has not yet been visually verified on the user's iPhone.

## Next recommended micro-batch
Proceed to Austria (`aus`) complete cavalry 8, using the same country-specific extraction/integration pipeline and reporting after that single batch.
