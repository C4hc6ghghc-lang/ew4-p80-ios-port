# HANDOFF — R14-39 POSTHANDOFF28 Native Achievement Exact Local Semantics Frozen

Date: 2026-09-10
Parent: P27 native Achievement conservative-runtime Frozen
Status: FROZEN / trusted checkpoint

## Major discovery
P27 itself contains the authoritative original EW4 v1.4.42 APK under `ORIGINAL_APK/`. Its SHA-256 is `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`. P28 extracted native Achievement semantics from the original x86_64 `.so` instead of retaining P27 placeholders.

## Completed in P28
1. Corrected Achievement `stage_star`: it is **historical Campaign stage-rating total / native maximum**, not the spendable Campaign Upgrade Stars wallet. Original `def_battlelist.xml` has 84 stage slots; native max is 84×5 = **420**.
2. Restored exact local global military/nobility semantics from native code. Per-general raw values use the same threshold arrays already present in `native_general_core.js`; global military score is floor(raw/10), nobility score raw×4, and both global levels use native float32 geometric thresholds to Lv99.
3. User mod adaptation: original native sums fixed 12 HQ general pointers. Because this port deliberately removes the HQ general hard cap, P28 extends the exact native formulas across all owned HQ generals rather than silently ignoring general 13+.
4. Corrected continent presentation: one integer is rendered between static `统治` and `年` using `rule_0..9.png`, with native leading-zero suppression and display clamp 999. P27's invented separate dynamic year text was removed.
5. Implemented native max-only continent persistence primitive (`recordConquestValue`) but deliberately did **not** wire generic Web conquest victory into it: native value-generation function around x86_64 `0x7e760` remains to be fully decoded.
6. Champion/Ranking are proven to call a native Multiplayer/platform service; P28 still does not fabricate an equivalent Web service.

## Native offsets / proof anchors
- Achievement form init: x86_64 around `0x98590`.
- Historical stage score sum: `0x2c200`; native max: `0x2c240`.
- Global military level/score: `0x53e80` / `0x53f80`.
- Global nobility level/score: `0x53f00` / `0x53fe0`.
- Per-general military/nobility raw: `0x54d20` / `0x54f40`.
- Continent read/max-only write: `0x2c550` / `0x2c560`.
- Native conquest value generation still unresolved: around `0x7e760`.

Detailed source audit: `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF28_NATIVE_ACHIEVEMENT_EXACT_AUDIT.md`.

## Verification
- Full `test_*.js`: **108/108 PASS**.
- Service Worker CORE: **327/327 present**.
- Six-zone long-session regression: PASS — 73 first clears + 73 replays, 292 BattleSave lifecycles, 500 Campaign meta reloads, 6/6 one-shot zone rewards.
- P21 protected Campaign Upgrade/BattleSave files remain byte-identical to P27 parent.
- Original APK SHA-256 reverified in this checkpoint.

## Truth boundary
Do not claim continent conquest Achievement generation is complete until native `0x7e760` has been decoded sufficiently to reproduce its inputs and formula. Do not wire a guessed conquest score. Do not merge historical Achievement stage stars with the spendable P21 Campaign Stars wallet; they are separate native/user-progression concepts.
