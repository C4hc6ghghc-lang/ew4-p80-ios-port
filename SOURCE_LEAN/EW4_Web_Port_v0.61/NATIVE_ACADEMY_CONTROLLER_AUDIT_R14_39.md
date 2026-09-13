# EW4 Web Port r14-39 — Military Academy native controller audit

Authority: original EW4 v1.4.42 APK, x86_64 `libeuropean-war-4.so`, `def_commander.xml`, `layout-568h.xml`.

## Candidate generation
- Native generator `0x5E4C0`.
- Tier 0: 6 candidates, star 1–3.
- Tier 1: 4 candidates, star 4–6.
- Tier 2: 2 candidates, star 7–9 (APK roster tops out at star 8).
- `drawlots=0`, already-owned commanders, all currently displayed candidates and newly staged picks are excluded.
- Refresh regenerates only the active tier and does not immediately redraw a commander already visible in that tier.

## Native slot record and prices
Each displayed slot is 12 bytes: `{commanderId, medalPrice, badgePrice}`.
- `medalPrice` is copied from the commander's `price` field in `def_commander.xml`.
- `badgePrice` is looked up by star from `.rodata 0x1B60C0`: star 1..8 => `0,0,0,3,3,4,6,8`.
- Therefore 1–3 star are medal-only, 4–6 star support medal or badge, and 7–8 star are badge-only.

## Purchase
- Native availability checks: `0x5E720` medal, `0x5E780` badge.
- Native purchase: `0x5E890`, currency selector 0=medal, non-zero=badge.
- It deducts the selected positive price, adds the commander to HQ ownership, then writes `-1` to only that candidate slot. It does not auto-refill or shift neighboring slots.
- User mod: medal/badge resources are unlimited, so the resource sufficiency gate is bypassed, but the original per-commander currency availability and displayed prices remain intact.

## Success UI
- Successful native purchase creates `SceneGetGeneralTips` and passes the acquired commander ID.
- `form_getgeneraltips` is 152x184; `tcmder` is x36,y42,w78,h98; title is `获得将军`; opening sound is `sfx_lvup2.wav`.
- Native also instantiates `effect_getgeneral_hd.xml`; its three original point emitters are preserved structurally in `assets/data/native_getgeneral_effect.json`. Rendering that particle system remains separate until emitter integration is proven.

## Failure path
- If the player lacks the chosen resource in the unmodified game, the callback opens `SceneBuyMedal` with currency selector 1/2. The unlimited-resource player mod makes this path unreachable in the modded player flow; do not invent a replacement error toast.
