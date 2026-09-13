# EW4 Web Port r14-39 — native action audio audit

Authority: original EW4 v1.4.42 APK and x86_64 `libeuropean-war-4.so`.

## Direct native action SFX

The stripped x86_64 native binary contains direct single-purpose playback xrefs for:

- recruit/draft controller around `0x4d827` -> `sfx_draft.wav`
- occupation controller around `0x4f9f8` -> `sfx_occupy.wav`

These are controller sounds, not `def_effectsanim.xml` attack-timeline cues.

## Movement sound branch

The movement controller around `0x597e3..0x59b3c` chooses one movement SFX after the move path is accepted. Its branch shape is:

1. naval/sea-state branch -> `sfx_naval.wav` (`0x59af5`)
2. non-cavalry movable land branch -> `sfx_leg.wav` (`0x59a55`)
3. cavalry special Armored Car branch -> `sfx_armourmove.wav` (`0x59b35`)
4. remaining cavalry -> `sfx_cavalrymove.wav` (`0x59817`)

The Armored Car special is consistent with the original army definition (`type="cavalry"`) while retaining a distinct movement sound.

## Web integration

Added `native_action_audio_core.js` and replaced the prior coarse Web substitutions:

- successful recruit now plays original `sfx_draft.wav`
- successful hostile facility occupation now plays original `sfx_occupy.wav`
- movement now resolves original leg/cavalry/armour/naval movement SFX rather than using `sfx_select.wav` for most units
- embarked land units use the naval movement sound while in sea state

No attack SFX are handled here; those remain on the independently reconstructed `def_effectsanim.xml` timed cue path.

## Build / upgrade / training card proof

The same native action dispatcher can be tied to original `def_card.xml` IDs:

- card 41/42/43 = Trench/Fence/Bunker; their successful branch reaches `sfx_build.wav` (`0x593e0`).
- card 44 = Upgrade Construction; its successful branch reaches `sfx_build1.wav` (`0x59418`) and then creates `effect_build.xml`.
- card 45 = Training; its successful branch reaches `sfx_buff.wav` (`0x594b2`). The reconstructed Web Training controller now uses this sound and the native action-ending semantics.
- card 46 = Troopship follows a separate branch; no sound is assigned here without further proof.

The battle use-item branch around `0x596A8..0x59756` plays `sfx_supply.wav` together with `effect_recover.xml` after any successful use of original battle consumables 11–15. Passive end-of-round facility supply does **not** use this mapping.

Web runtime now uses `sfx_build.wav` for successful fieldwork construction and `sfx_build1.wav` for successful construction upgrades instead of the generic select click.

## Build/recover visual-effect source preserved

The exact APK sources were inspected before adding any renderer approximation:

- `effect_build.xml`: `build_mark.png`; `quantity=30` is the initial **emission rate**, fading to 0 over the 0.1 s emitter lifetime; particle life 1.4 s, base particle 30x30, scale 1.5, 8-point normalized life track.
- `effect_recover.xml`: `recover.png`; the same rate semantics apply; particle life 1.3 s, base particle 30x30, scale 1.0, 11-point normalized life track.
- both images live in original 512x512 `eff.png` atlas; exact atlas rectangles/reference anchors are preserved in `assets/data/native_simple_effects.json`.

The original `eff.png` atlas is included byte-for-byte. Native `area` spawn and emission-accumulator semantics are now reconstructed in `native_simple_effect_runtime.js`; build and recover use zero-width/height point-anchored area emitters rather than an invented scatter pattern.
