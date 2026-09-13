# EW4 Web Port v0.61 — r14-26 France Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-25 mainline (161 animated unit definitions / 680 native motion assets) and adds the complete France (`fra`) recruit cavalry roster from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_motion.xml` contains exact France-specific entries for all 8 recruit cavalry definitions:
- Light Cavalry fra 1/2
- Heavy Cavalry fra 1/2
- Guards Cavalry fra 1/2
- Armored Car fra 1/2

The French assets were independently decoded from original BILE containers. They were not aliases or copies of the generic cavalry sheets.

### France Light Cavalry
- Light Cavalry fra 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Light Cavalry fra 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Current proven attack chain: `Attack -> Finish -> Ready`

### France Heavy Cavalry
- Heavy Cavalry fra 1: Ready 23f / UndoReady 11f / Attack 32f / Finish 9f
- Heavy Cavalry fra 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Current proven attack chain: `Attack -> Finish -> Ready`
- Note: France Heavy Cavalry 1 uses 32 attack frames while the generic counterpart uses 33, directly proving the country-specific pack is not a reused generic animation.

### France Guards Cavalry
- Guards Cavalry fra 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Guards Cavalry fra 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal attack path: `Attack0 -> Reload -> Finish -> Ready`
- Guns-vs-warship/fort alternate path: `Attack1 -> Ready`

### France Armored Car
- Armored Car fra 1: Ready 12f / Attack 85f
- Armored Car fra 2: Ready 12f / Attack 85f
- Both original Attack motions carry `Motion@speed="2.5"`
- Current proven attack chain: `Attack -> Ready`

All extracted BILE frames retain the original 24 FPS base.

## Code implemented ✅
- Added 8 France-specific cavalry unit definitions.
- Added 32 France-specific native BILE motion assets.
- Main native-animation manifest advanced:
  - r14-25: 161 units / 680 motions
  - r14-26: **169 units / 712 motions**
- New runtime manifest: `assets/data/native_animation_core169.json`
- Source-pack label appended: `france_cavalry8`
- Runtime loader now targets `native_animation_core169.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-26-francecavalry`.

## Regression protection ✅
- All 161 pre-r14-26 unit records compare JSON-value identical after merge.
- All 680 pre-r14-26 asset records compare JSON-value identical after merge.
- All 712 runtime sheets exist and have valid PNG signatures.
- France cavalry integration assertions verify:
  - Light/Heavy `UndoReady` assets exist.
  - Light/Heavy attack chains resolve to `Attack -> Finish -> Ready`.
  - Guards Cavalry Attack1 exists on both grades.
  - Guards normal path resolves to `Attack0 -> Reload -> Finish -> Ready`.
  - Guards alternate guns-vs-fort path resolves to `Attack1 -> Ready`.
  - Armored Car 1/2 preserve original attack speed attribute 2.5 and resolve `Attack -> Ready`.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original France-specific UndoReady assets are preserved, but the exact native external-controller trigger remains unresolved. No guessed trigger was added.

### Motion@speed playback math ⏳
Armored Car attack `speed=2.5` is preserved as source data. Exact original native playback math remains unresolved, so runtime duration is not falsely claimed as timing-perfect 1:1.

### Real iPhone verification ⏳
This exact r14-26 build has not yet been visually verified on the user's iPhone.

## Next recommended micro-batch
Proceed to Britain (`gbr`) complete cavalry 8, using this country-specific cavalry pipeline and independently extracting British BILE motions rather than reusing French or generic sheets.
