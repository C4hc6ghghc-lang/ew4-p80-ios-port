# EW4 Web Port 0.61 · Reinforcement field audit

## Confirmed negative result

`unit.raw[4]` must **not** be treated as a simple reinforcement appearance-round field.

Strong counterexample:
- `campaign2_06.btl` (哥本哈根战役)
- Native round dialogue at round 4: “由于敌人的援军大量的加入战场，我的军队目前损失很大。”
- Units with `raw[4] == 4`: **0**

Across the decoded BTL set, `raw[4]` is non-zero on many initially deployed units, including conquest values such as 20/30/40/50/55. Bulk-hiding units until `raw[4]` is reached would corrupt native initial deployments.

## New byte-level elimination in this pass

Copenhagen contains **13** units with `raw[9] == 4`, but this is not round timing either. The unit decoder already identifies `raw[8] + raw[9] * 256` as the unit's uint16 map-position field. The value 4 is simply the high byte of those map positions.

Other tempting round-number matches are similarly unsafe. For example `raw[10..11]` is the decoded army id, while `raw[12..13]` and `raw[14..15]` are HP/max-HP and `raw[24..25]` is commander code. Matching a dialogue round against an individual byte is therefore not evidence of activation timing.

## Reinforcement-word dialogue corpus

There are eight decoded native dialogues containing “援军” in the current event set. Most are `trigger_type=2 / param_a=4`, the already verified round-dialogue family. That family schedules text, not a proven spawn operation.

The strongest safety counterexample is `campaign4_03.btl`, event `4035`:
- trigger type: 2
- round: 11
- `param_a = 1`
- target country: `tur`
- dialogue: “由于敌人的援军大量的加入战场，我的军队目前损失很大。”

`param_a = 1` is already independently verified in the native event switch as **target-country morale -1** using the three-round native morale timer. So reinforcement wording can accompany a non-spawn gameplay effect. Dialogue semantics alone cannot authorize unit creation or activation.

`campaign2_06.btl` remains the best candidate battle for finding a real reinforcement path because its scenario text and round-4 dialogue both explicitly discuss French reinforcements, but no unit appearance-round field has been verified in the decoded unit records.

### Copenhagen deployment observation
The decoded Copenhagen BTL already contains **three French ships** (owner 8): a frigate at q31/r13, a battleship at q31/r14, and a frigate at q29/r15. Their `raw[4]` values are all 0. This materially narrows the possibilities: the original can be using pre-deployed reinforcements, a hidden/activation state elsewhere, or a country/relation-state change rather than a per-unit appearance-round byte.

The 32-byte unit tails do not expose an obvious simple active flag either. In particular `raw[31] == 1` for **all 7,407 decoded units** across the current 101-BTL corpus, so it cannot distinguish hidden reinforcement units. The remaining tail bytes have broad values used across ordinary initial units and are not unique to the French Copenhagen group.

This is evidence **against** inventing a spawn timer, but it is not yet proof that the original merely moves pre-deployed ships.

## Current safe runtime rule

0.61 does **not** hide, delay, spawn, or activate BTL units as reinforcements from any guessed unit byte.

Reinforcement behavior remains unresolved until one of these is verified:
1. a native activation/group field in BTL structures,
2. a code path from `libeuropean-war-4.so`, or
3. a controlled original-runtime before/after observation that can be matched back to exact BTL records.

The current Web package contains decoded runtime data and only a prefix of trailing BTL bytes, not the original native `.so` or full raw `.btl` files. That limits deeper binary-level proof in this package alone.

Machine-readable evidence is stored in `REINFORCEMENT_EVENT_AUDIT_0.61.json`, and `test_reinforcement_safety.js` prevents the disproven `raw[4]` / accidental byte-match theories from being reintroduced.
