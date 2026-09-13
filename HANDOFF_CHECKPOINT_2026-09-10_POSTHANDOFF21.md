# EW4 Web Port 0.61 — Post-Handoff 21 Native Campaign Upgrade Frozen

Date: 2026-09-10

## Authoritative baseline
This checkpoint supersedes Post-Handoff 20. P1-P20 remain frozen. P21 restores the original Campaign SceneUpgrade / Star / warzone technology progression loop.

Read first:
1. `CURRENT_STATUS.json`
2. `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF21_NATIVE_CAMPAIGN_UPGRADE_AUDIT.md`
3. `TEST_RESULTS_POSTHANDOFF21_97_OF_97_PASS.txt`

## Frozen P21 content
- Native Campaign `btn_lvlup -> form_upgrade` controller, 421x265.
- 5 visible tabs / 22 military techs; 26 internal tech entries.
- Exact six-warzone initial tech manifest from retained original `def_warzonetech.xml`.
- Spendable Star wallet and historical-best delta award rule; 999 cap.
- Exact native 26x4 Star cost table.
- Recruit/build lock at tech < 0.
- Tech-driven initial TRAINING level, explicitly separate from 1/2/3 formation grade.
- Farm / Financial / Factory per-round bonuses.
- Dock infantry/cavalry/artillery transport gates.
- Battle tech snapshot + BattleSave schema 6 for save/load consistency.
- P21 Service Worker cache generation and original upgrade assets.

## Verification
Full independent JS tree: **97 / 97 PASS**.
Warzone manifest: **156 / 156 original levels matched**.
Service Worker CORE: **231 / 231 files present**.

## Next pass
Continue residual single-player Scene/controller census and cross-system long-session integration. Do not reopen P21 unless a reproducible runtime regression is found. True-device iPhone visual calibration remains pending.
