# EW4 Web Port v0.61 — P28 Native Achievement Exact Local Semantics Audit

## Scope
P28 starts from frozen P27 and uses the authoritative original EW4 v1.4.42 APK embedded in the checkpoint (SHA-256 `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`). This pass replaces P27's deliberately conservative Achievement placeholders only where native `.so` evidence is now available.

## Native evidence ✅
### Campaign star counter
Achievement init around x86_64 `0x98590` writes `text_medal` using two Headquarters calls:
- `0x2c200`: sum saved best stage scores;
- `0x2c240`: count stage definitions across 8 zone records and multiply by 5.
Original `def_battlelist.xml` has 84 Campaign stage slots, so the native denominator is **420**. This counter is historical Campaign stars earned, not the spendable P21 Stars wallet.

### Global military / nobility summary
Achievement init maps:
- `text_millevel` <- `0x53e80`
- `text_milscore` <- `0x53f80`
- `text_noblevel` <- `0x53f00`
- `text_nobscore` <- `0x53fe0`

Per-general raw values are native functions `0x54d20` and `0x54f40`:
- military raw = `300 + completed military thresholds + current military progress`;
- nobility raw = `60 + completed nobility thresholds + current nobility progress`.
The threshold arrays are the same arrays already used by `native_general_core.js`.

Native global formulas:
- military level: level 1 through total 99; otherwise start level 2 / threshold 121, repeatedly truncate float32(`threshold * 1.214`) until total falls below threshold or level reaches 99;
- military score: `floor(total military raw / 10)`;
- nobility level: level 1 through total 49; otherwise start level 2 / threshold 56, repeatedly truncate float32(`threshold * 1.125`) to level 99;
- nobility score: `total nobility raw * 4`.

Original native code sums 12 Headquarters commander pointers (`HQ+0x10 .. HQ+0x68`). The user's port deliberately removes the general hard cap, so P28 extends the proven native per-general and global formulas over every owned HQ general rather than silently ignoring owned general 13+. This is a **user-mod adaptation**, not a literal 12-slot reproduction.

### Continent rule-years display
`0x2c550(HQ,index)` returns `HQ + 0x118 + index*4`. Achievement init renders this one integer with `rule_%d.png` into `image_rule_%d1/2/3`:
- no leading zero hundreds/tens;
- ones is always shown (`0` renders `rule_0.png`);
- display is capped at 999.
There is no separate dynamic year-number label; static strings are `统治` and `年` around the digit images.
`0x2c560` only replaces the stored continent value when a larger value arrives. Conquest completion reports indices 0/1/2 to platform achievements `ew4_european_conqueror`, `ew4_american_conqueror`, `ew4_asian_conqueror`.

## Code implemented ✅
- `native_achievement_core.js` now computes historical Campaign stars / 420.
- Global military/nobility level and score now use native formulas and actual owned-general growth state.
- Achievement UI displays native `Lv %d` form.
- Continent display now renders one rule-years integer using native no-leading-zero digit behavior; the invented P27 separate `year-value` label is removed.
- `recordConquestValue` implements the native max-only persistence primitive, but the runtime does **not** yet call it on generic Web conquest victory.

## Deliberately unresolved ⏳
Native function around x86_64 `0x7e760` computes the conquest value ultimately passed to `0x2c560`. It depends on conquest state/HQ inputs and has not yet been fully decoded. P28 therefore does not invent a formula or retroactively create Europe/America/Asia records.
Champion/Ranking call a Multiplayer/platform service; exact external service semantics remain outside the local single-player reconstruction.
