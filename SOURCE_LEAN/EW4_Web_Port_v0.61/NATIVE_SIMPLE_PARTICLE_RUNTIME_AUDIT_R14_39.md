# EW4 r14-39 native simple particle runtime audit

Evidence source: original `libeuropean-war-4.so`, original APK `effect_build.xml`, `effect_recover.xml`, `def_item.xml`, and `eff.png`.

## Area emitter spawn

The x86_64 particle spawn path at `0xC9D64..0xC9E3E` proves `type=area` uses:

1. one shared random `t` to interpolate both coordinates along the emitter previous/current position segment;
2. an independent width random with centered range `[-width/2,+width/2]`;
3. an independent height random with centered range `[-height/2,+height/2]`.

The `0.5f` multiplier is at rodata `0x1B431C`. `effect_build.xml` and `effect_recover.xml` omit area width/height, which the parser leaves zero, and both effects are attached with a point segment. Therefore their spawn position is exactly the supplied action anchor.

## Timetrack semantics

The emitter update at `0xC9180..0xC986B` stores a floating emission rate and remainder. Spawn count is `floor(dt * currentRate + remainder)`; XML `quantity` is therefore a rate, not a literal one-shot burst count. The `30 -> 0 over 0.1s` build/recover track produces the native short single-mark style rather than thirty simultaneous sprites. Emitter lifetime disables future emission; already emitted particles remain until their particle life expires.

## Lifetrack semantics

The native particle update around `0xC95C0..0xC9804` computes slopes between adjacent life-track keys and updates scale/color/alpha continuously. The Web runtime uses equivalent linear interpolation for the recovered fields used by build/recover.

## Build effect

Upgrade success xref around `0x59410..0x59459` plays `sfx_build1.wav`, creates `effect_build.xml`, and attaches it at the action coordinates through the same `bf970` point-position API. The Web upgrade path now calls `spawnNativeSimpleEffect('effect_build', q, r)`.

## Recover effect trigger (important)

`effect_recover.xml` must **not** be attached generically to construction round supply. The battle item action branch around `0x596A8..0x59756` first validates/applies the selected consumable and, after **any successful use**, unconditionally plays `sfx_supply.wav` and creates `effect_recover.xml` at the selected unit coordinates.

`SceneUseItem` (`0x4A250`) inserts exactly five item IDs, in order: 11, 12, 13, 14, 15. Native `0x51A30` / `0x525C0` prove their functions:

- Wine id 11 / function 7: usable while morale is below normal; sets temporary morale base to 0 for 3 turns.
- Spirit id 12 / function 6: usable while morale is normal or lower; sets temporary morale base to +1 for 3 turns.
- Medikit id 13 / function 8: +65 HP, clamped to max HP.
- Medikit L id 14 / function 8: +130 HP, clamped to max HP.
- First Aid Box id 15 / function 8: +200 HP, clamped to max HP.

Therefore the supply sound/recover visual belongs to the **generic successful battle-consumable action for these five items**, not only the medical subset, and not passive facility/training/nobility healing. The Web `form_useitem` controller now follows this boundary.

## Current deliberate boundary

The generic particle engine still has emitter types/effect parameters beyond the two simple zero-speed area effects. Do not claim all APK effects are restored from this runtime. `effect_build` is integrated. `effect_recover` is now integrated through the restored battle `form_useitem` controller for the five native consumables. Passive recovery sources remain deliberately silent unless their own native effect call is proven.
