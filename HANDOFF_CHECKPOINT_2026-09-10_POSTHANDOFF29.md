# HANDOFF — R14-39 POSTHANDOFF29 Native Conquest Achievement Frozen

Date: 2026-09-10
Parent: P28 Native Achievement Exact Local Semantics Frozen
Status: FROZEN / trusted checkpoint

## Completed in P29

1. Fully decoded the local native conquest Achievement value generator around x86_64 `0x7e760` from the authoritative original APK embedded in the checkpoint.
2. Restored exact normal Europe/America scoring inputs: player Money/Industry/Food, HQ commander military+nobility levels, historical Campaign best-star total, and native round-band contribution; restored the native `46660` normalization and threshold/year table.
3. Restored exact fast-conquest Asia path: victory-only, Europe <=65 rounds / America <=55 rounds; separate caps/round bands, `/700` normalization and native threshold table.
4. Reconstructed the critical caller behavior: a qualifying fast victory overwrites the pending normal Europe/America record with Asia index 2, and the native code performs one final max-only write. One victory never writes both records.
5. Added production `native_conquest_achievement_core.js` and wired conquest victory persistence through P28 `recordConquestValue`.
6. Preserved the user unlimited-general Mod: native uses 12 HQ slots; P29 extends the exact native per-general formula across all owned HQ generals, explicitly documented as a Mod adaptation.
7. Kept P21 spendable Upgrade Stars completely separate from historical Campaign Achievement stars.

Detailed reverse audit: `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF29_NATIVE_CONQUEST_ACHIEVEMENT_AUDIT.md`.

## Verification

- Full `test_*.js`: **109/109 PASS**.
- Service Worker CORE: **328/328 present**.
- Six-zone Campaign long-session regression remains PASS: 73 first clears + 73 worse replays, 292 BattleSave lifecycles, 500 Campaign meta reloads, 6/6 one-shot zone rewards.
- P21 protected files remain byte-identical to P28 parent:
  - `native_upgrade_core.js`
  - `battle_save_core.js`
  - `assets/data/native_warzone_tech.json`
  - `assets/data/def_warzonetech.xml`

## Native proof anchors

- value generator `~0x7e760`
- player country `0x805b0`
- resources `0x57a50 / 0x57b20 / 0x582a0`
- historical Campaign stars `0x2c200`
- map continent `0x839b0`
- result flags `~0x7da10`
- fast eligibility/override `~0x7eee0 / ~0x7ef50`
- final max-only write `~0x7efe0 -> 0x2c560`

## Remaining high-value work

- Continue evidence-based single-player controller census; avoid rebuilding forms that merely use alternate Web IDs.
- Champion/Ranking platform-service semantics remain unresolved and must not be fabricated.
- True iPhone calibration remains pending: Achievement digits/fonts/general strip, Dock `transportship1/2`, particle z-order, CampaignInfo offset, marker/font alignment, pinch/touch feel.
