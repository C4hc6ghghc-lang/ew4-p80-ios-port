# EW4 Web Port v0.61 — r14-34 Generic Artillery 8 Native Animation Audit

## Scope
This micro-batch starts from verified r14-33 (225 animated units / 936 native motion assets) and adds the complete **generic recruit artillery roster** from the original EW4 v1.4.42 APK.

Authoritative APK SHA-256 remains:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Original evidence ✅
`def_army.xml` / factory recruitment data define 8 artillery definitions:
- Light Artillery 1/2
- Heavy Artillery 1/2
- Siege Artillery 1/2
- Rocket 1/2

`def_motion.xml` proves four different native motion layouts:

### Light Artillery 1/2
- Ready 10f / Attack 64f / Reload 60f / Finish 39f
- Proven runtime chain: `Attack -> Reload -> Finish -> Ready`

### Heavy Artillery 1/2
- Ready 10f / Attack 64f / Reload 60f / Finish 39f
- Proven runtime chain: `Attack -> Reload -> Finish -> Ready`

### Siege Artillery 1/2
- Ready 10f / Attack 64f
- Finish: 67f (grade 1), 66f (grade 2)
- No Reload motion
- Proven runtime chain: `Attack -> Finish -> Ready`

### Rocket 1/2
- Ready 10f / Attack 64f
- Reload: 44f (grade 1), 68f (grade 2)
- No Finish motion
- Proven runtime chain: `Attack -> Reload -> Ready`

All extracted BILE frames use the original **24 FPS** base.

## New BILE extractor finding/fix ✅
While extracting `Siege Artillery 1 / finish` (`131组合退步`), the preserved r14-16 extractor hit a genuine recursive BILE linkage:
- `131组合退步` references `131站直`
- `131站直` contains a layer that references **itself**
- analogous self-reference exists across the `130..138站直` artillery timeline family

Blind recursive expansion therefore cannot terminate and produced Python `RecursionError`.

r14-34 adds a path-level cycle guard to the development extractor:
- only an item already active on the current expansion path is skipped;
- ordinary repeated/shared child items are still rendered normally;
- non-cyclic extraction output was regression checked by re-extracting all 8 Light Artillery motion sheets and comparing SHA-256: **8/8 byte-identical** to the pre-fix extractor output.

This allows both Siege Artillery Finish motions to be fully produced rather than omitted or replaced with static fallback.

Patched development tools are preserved under:
`dev_tools/r14_34_animation/`

## Code implemented ✅
- Added 8 generic artillery unit definitions.
- Added **28** native BILE motion assets:
  - Light Artillery: 8
  - Heavy Artillery: 8
  - Siege Artillery: 6
  - Rocket: 6
- Runtime animation mainline advanced:
  - r14-33: 225 units / 936 motions
  - r14-34: **233 units / 964 motions**
- New runtime manifest: `assets/data/native_animation_core233.json`
- Added source-pack label: `generic_artillery8`
- Runtime loader now targets `native_animation_core233.json`.
- Service Worker cache advanced to `ew4-port-v061-r14-34-genericartillery`.

## Regression protection ✅
- All 225 pre-r14-34 unit records compare JSON-value identical after merge.
- All 936 pre-r14-34 asset records compare JSON-value identical after merge.
- All 964 runtime sheets exist and have valid PNG signatures.
- Artillery integration assertions verify the exact four attack chains above.
- Full JS regression suite: **23/23 PASS**.

## Fidelity boundaries still unresolved ⏳
- Exact native interpretation of some internal BILE linkage/timeline metadata beyond the proven cycle guard is not fully documented. The guard is deliberately minimal and only cuts recursive re-entry.
- `Motion@speed` native playback math remains unresolved globally; r14-34 does not invent new timing behavior.
- This exact build still requires real-iPhone visual verification.

## Next recommended micro-batch
Proceed to **France (`fra`) complete artillery 8**, using this generic artillery state/cycle audit as the template while still extracting and validating the exact French BILE resources independently.
