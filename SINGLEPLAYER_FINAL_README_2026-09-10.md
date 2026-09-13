> **Current authority (2026-09-10): P35 Final Native Presentation.** For current status read `START_HERE.md` and `P35_FINAL_NATIVE_PRESENTATION_NOTE.md`. Older P30-P34 wording below is retained as historical provenance.

# EW4 Web Port 0.61 — Singleplayer Final (PORT ONLY)

> Distribution note: the original APK binary is intentionally **not included** in this package. This ZIP contains only the reconstructed/ported project, its runtime assets, tests, and documentation. Historical source hashes/names may remain in audit metadata for provenance.

## 1. Final scope
This package is the final **single-player** reconstruction baseline. The original EW4 APK is the authority for local UI geometry, BTL data, maps, controller behavior, animation, audio, progression and battle/conquest behavior whenever evidence exists.

External online/commercial integrations are intentionally out of scope and are not replaced with fake Web services:
- medal/IAP purchase service;
- rewarded-video advertising;
- multiplayer/network matchmaking/transmission;
- Champion / Ranking platform service;
- website, email, update, service and operator-unlock panels.

These exclusions do not remove local Campaign, Conquest, HQ, general, princess, shop, tavern, equipment, academy, save/load, technology, tutorial, achievement, battle or result gameplay.

## 2. Original single-player parity — final audit
### Battles / Campaign / Conquest
- 101 original BTL files remain the data source.
- Native Campaign targets/triggers, hidden stages, ratings, results and progression remain active.
- Six-zone long-session regression: 73 first clears + 73 worse replays, 292 BattleSave save/load lifecycles, 500 Campaign-meta reloads, all 6 one-shot zone-completion rewards PASS.
- All six Conquest scenarios remain selectable with their original countries/data.
- Conquest extinction is now the locked rule: all infantry/cavalry/artillery gone + all non-port land facilities lost + all ports lost. Navy and fort remnants do not delay defeat.
- Six Conquest maps / 98 selectable-country perspectives pass the extinction matrix.
- Native country-eliminated `form_failure` is restored.
- Native Conquest `form_complete` is restored after the Victory result.
- Fast Conquest restores the native Challenge choice: choose Asia record or keep the Europe/America record. This supersedes P29's earlier automatic-Asia interpretation.

### UI / controller
The final census rechecked the local single-player forms and interaction paths. Recent residuals closed in P23–P30 include Defense, Pause, UnitInfo, CampaignInfo, Campaign SelCountry, Save presentation, Achievement, Loading, country Failure and Conquest/Challenge Complete.

Alternate Web element IDs are not treated as missing native forms when the original geometry/controller behavior is already implemented. Local visible buttons were scanned for dead handlers; no local single-player dead button remains. The remaining no-local-handler entries are external homepage/email/platform-service actions intentionally excluded above.

### Animation / presentation data
- 877/877 native unit definitions integrated.
- 3519/3519 native motions integrated.
- 1754/1754 directional attack chains resolved.
- 7407/7407 battle units resolve to a valid native visual definition.
- compact BILE parity 1076/1076 PASS.
- Machine Gun Finish correction 18/18 PASS.
- Native 24 FPS/data-driven animation state logic remains in use.

### Music / sound
Before stripping the reference APK from this distribution, the final port was re-compared with the authoritative APK:
- 38 WAV + 5 MP3 = 43/43 audio files byte-identical.
- battle1..battle4 use the original battle-track randomization path.
- defeat_music is restored.
- original separate Music/Sound volume controller is restored.
- 143 original timed effect-audio timelines remain wired to battle presentation.

### Save / technology / progression
- BattleSave remains schema 6.
- P21 protected `native_upgrade_core.js`, `battle_save_core.js`, `native_warzone_tech.json`, and `def_warzonetech.xml` remain byte-identical to the trusted P29 parent.
- Spendable Campaign Upgrade Stars remain separate from historical Campaign rating stars used by Achievement/Conquest calculations.

## 3. User-requested modifications — locked and re-verified
The original presentation remains the UI baseline; these are hidden player-side rule overrides.

### Player units
- attack minimum +4;
- attack maximum +4;
- base unit HP +120 (this supersedes the older +40 rule; never stack both);
- movable unit movement/action points +2;
- forts remain immobile;
- AI unit values remain original;
- old +40 saves migrate by +80 delta while preserving absolute damage.

### Seven custom player generals
Only player-owned copies are modified; AI copies remain original:
- Napoleon (1)
- Davout (2)
- Lannes (5)
- Massena (10)
- Suchet (11)
- Soult (26)
- Murat (30)

The locked stat/skill layers in `assets/data/player_general_overrides.json` remain active. Player general rank max is 14 and nobility max is 9. Ordinary max-rank bonus is +500 HP and ordinary max-nobility recovery is +25/round. Napoleon's explicit exception is +1000 HP and +100/round at maximum. Player-owned rank/nobility upgrades cost zero. General hard quantity caps remain removed while one distinct commander cannot be duplicated across multiple units.

### Princesses
All eight original princesses (201–208) are owned/available from the start. Only Lan (208), Victoria (205), and Isabela (204) receive the user's locked stat/skill overrides; Maria, Sophia, Fatimah, Kate and Sakurako keep original stats/skills.

### Resources / Academy / consumables
- medals: infinite hidden backend value;
- badges/shields: infinite hidden backend value;
- Military Academy refresh: unlimited / zero cost;
- battle consumables (native UseItem IDs 11–15): do not consume player inventory;
- original prices/count presentation is retained; no `MOD`, `FREE`, `∞` or cheat labels are shown.

### Turn-limit rule
No forced player defeat is introduced merely because the original normal-victory rating round line was exceeded. Original BTL round lines remain available for result/rating semantics; Conquest has no artificial turn cap.

## 4. Verification snapshot
Final source-tree regression before freeze:
- JS tests: **115/115 PASS**;
- Service Worker CORE: **340/340 present**;
- animation full coverage: PASS;
- compact BILE full parity: PASS;
- original APK audio inventory: **43/43 byte-identical**;
- Campaign long-session: PASS;
- Conquest all-country extinction matrix: PASS;
- user unit/general/princess/infinite-resource/effective-UI contracts: PASS;
- P21 protected upgrade/save/warzone hashes: MATCH.

## 5. Honest remaining boundary
The code/data-side local single-player reconstruction is treated as complete for this checkpoint. One class of work cannot be truthfully declared pixel-perfect without a physical iPhone comparison: final device-specific font baselines, tiny popup offsets, transportship1/2 visual anchoring at every zoom, particle z-order edge cases, and subjective pinch/touch feel.

Those are **true-device calibration items**, not missing game systems. No external-service implementation is required to play the local single-player game.
