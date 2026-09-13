# EW4 Web Port 0.61 r14-39 — Native Motion@speed audit

## Result
`Motion@speed` is now proven native playback data, not metadata-only.

On x86_64 `libeuropean-war-4.so` from the authoritative v1.4.42 APK:

- the `def_motion.xml` parser allocates a 0x20-byte motion record;
- record `+0x1c` defaults to float `1.0` at `0x71368`;
- XML attribute `speed` is parsed at `0x713df..0x713ff` and stored at record `+0x1c`;
- the live unit-animation update at `0x510f6..0x5110c` loads the active motion record and calls the animation updater with `deltaTime * motion.speed`;
- real animation duration is also divided by that same speed in native logic (`0x514fb..0x5150a` and `0x5157c..0x51588`).

Therefore the Web runtime rule is:

`effective elapsed = real elapsed * Motion@speed`

or equivalently:

`real motion duration = frame_count / fps / Motion@speed`.

## Current source impact
`native_animation_controller.js` now applies this to both phase duration and frame selection.

Known non-1 motions in the current 1076-motion integrated set are the Machine Gun and Armored Car attack motions, all `speed=2.5`.

Examples:
- Machine Gun 1 Attack: 72 frames / 24fps / 2.5 = 1.2 seconds.
- Armored Car 1 Attack: 85 frames / 24fps / 2.5 ≈ 1.4167 seconds.

## Effects/audio timing note
`def_effectsanim.xml` remains a separate real-second timeline. The effects runtime constructor is given effect-name/direction/position but no Motion speed parameter. Do not multiply its `at=` timestamps by Motion speed. A separate runtime-integration test covers timed audio before it is enabled in battle.
