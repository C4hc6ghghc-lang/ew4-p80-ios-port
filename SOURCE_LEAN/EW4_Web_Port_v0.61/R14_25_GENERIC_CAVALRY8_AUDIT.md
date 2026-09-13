# EW4 Web Port v0.61 — r14-25 Generic Cavalry 8 Native Animation Audit

## Scope
This micro-batch starts from the verified r14-24 mainline (153 animated unit definitions / 648 native motion assets) and adds the complete **generic recruit cavalry roster** from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256 remains:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_army.xml` defines the recruit cavalry roster as 8 definitions:
- Light Cavalry 1/2
- Heavy Cavalry 1/2
- Guards Cavalry 1/2
- Armored Car 1/2

`def_motion.xml` proves that these four families do **not** share one universal state layout.

### Light Cavalry
- Light Cavalry 1: Ready 23f / UndoReady 11f / Attack 29f / Finish 9f
- Light Cavalry 2: Ready 25f / UndoReady 11f / Attack 32f / Finish 9f
- Runtime-proven attack chain used by current controller: `Attack -> Finish -> Ready`

### Heavy Cavalry
- Heavy Cavalry 1: Ready 23f / UndoReady 11f / Attack 33f / Finish 9f
- Heavy Cavalry 2: Ready 27f / UndoReady 11f / Attack 34f / Finish 9f
- Runtime-proven attack chain used by current controller: `Attack -> Finish -> Ready`

### Guards Cavalry
- Guards Cavalry 1: Ready 22f / UndoReady 11f / Attack0 30f / Attack1 42f / Reload 45f / Finish 9f
- Guards Cavalry 2: Ready 24f / UndoReady 11f / Attack0 36f / Attack1 42f / Reload 51f / Finish 9f
- Normal attack path: `Attack0 -> Reload -> Finish -> Ready`
- Alternate guns-vs-warship/fort path: `Attack1 -> Ready`

### Armored Car
- Armored Car 1: Ready 12f / Attack 85f
- Armored Car 2: Ready 12f / Attack 85f
- Original `Motion@speed` attribute on Attack is `2.5`
- Motion layout is `Ready + Attack` only; current proven attack chain is `Attack -> Ready`

All extracted BILE frames use the original **24 FPS** base.

## Code implemented ✅
- Added 8 generic cavalry unit definitions.
- Added 32 deduplicated native BILE motion assets.
- Advanced runtime manifest:
  - r14-24: 153 units / 648 motions
  - r14-25: **161 units / 680 motions**
- New runtime manifest: `assets/data/native_animation_core161.json`
- Source-pack label appended: `generic_cavalry8`
- Runtime loader and Service Worker now target `native_animation_core161.json`.
- Service Worker cache: `ew4-port-v061-r14-25-genericcavalry`.

## Regression protection ✅
- All 153 pre-r14-25 unit records compare JSON-value identical after merge.
- All 648 pre-r14-25 asset records compare JSON-value identical after merge.
- All 680 runtime sheets exist and have valid PNG signatures.
- Cavalry-specific integration assertions now verify:
  - Light/Heavy `UndoReady` assets exist.
  - Light/Heavy attack chain resolves to Attack -> Finish -> Ready.
  - Guards Cavalry Attack1 exists on both grades.
  - Guards normal path resolves to Attack0 -> Reload -> Finish -> Ready.
  - Guards guns-vs-fort path resolves to Attack1 -> Ready.
  - Armored Car 1/2 preserve original attack speed attribute 2.5 and resolve Attack -> Ready.
- Full JS regression suite: **23/23 PASS**.

## Important unresolved fidelity boundaries
### UndoReady semantics ⏳
The original assets are now preserved, but the exact external controller condition that invokes `UndoReady` is still not fully proven. r14-25 deliberately does **not** invent a trigger for it.

### Motion@speed playback math ⏳
The original `speed=2.5` attribute is preserved for Armored Car attacks, but `native_animation_controller.js` still intentionally does not apply Motion@speed to playback duration because the exact native playback math has not yet been proven. Do not claim timing-perfect 1:1 behavior from the stored attribute alone.

### Real iPhone verification ⏳
This exact r14-25 build has not yet been visually verified on the user's iPhone. Code/data/test completion does not equal real-device visual confirmation.

## Next recommended micro-batch
Proceed to **France (`fra`) complete cavalry 8**, using the generic cavalry state audit as the reference but still extracting and validating the exact French BILE motions rather than assuming identical frame/state data.
