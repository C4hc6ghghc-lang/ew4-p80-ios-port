# EW4 Web Port r14-39 — player modification locks (2026-09-08)

This file separates the user's intentional EW4-port modifications from the unrelated ImperialFrontier project. Anything not listed here remains original-APK behavior unless separately evidenced in the EW4 port history.

## Player units
- attack minimum +4
- attack maximum +4
- base unit HP +120 (supersedes the earlier +40; never stack +40 +120)
- movable unit movement/action points +2
- forts remain immobile
- AI unchanged
- old +40 battle saves migrate by +80 delta while preserving absolute damage

## Player generals
Only the seven previously locked generals receive their custom stat/skill layer: Napoleon, Davout, Lannes, Murat, Soult, Suchet, Massena. AI copies remain original APK.

Player-owned general growth remains:
- rank max 14; ordinary max-rank HP bonus +500
- nobility max 9; ordinary max-nobility heal +25/round
- Napoleon exception +1000 HP / +100 heal
- player-owned rank/nobility upgrades cost zero

## Battle/campaign limits
- no forced campaign defeat solely because the original normal-victory round line has been exceeded
- conquest likewise has no artificial turn cap
- original BTL round lines may still be retained for result/rating information
- campaign/conquest general hard quantity caps remain removed; one distinct owned commander cannot be duplicated across multiple units

## Military Academy
- refresh unlimited / zero cost as a hidden backend rule
- original `form_getgeneral` visual/controller evidence remains the UI baseline

## Princesses
All eight original princess commander records (201–208) are immediately owned/available to the player, without conquest unlock gating.

Only three receive stat/skill overrides:

### Lan (208)
- Infantry 5, Cavalry 5, Movement 7; Training stays original 5
- Original: Attack Tactics, Raid, Surprise, Leadership
- Add missing cavalry family: Maneuver, Cavalry Teaching
- Add missing infantry family: Formation, Infantry Tactics, Bugle, Dense Attack, Infantry Teaching
- Add Defense Tactics, Spy
- 13 unique skills total after dedupe

### Victoria (205)
- Infantry 5, Movement 7; Training stays original 5
- Original: Bugle, Dense Attack, Attack Tactics, Defense Tactics
- Add Formation, Infantry Tactics, Infantry Teaching, Leadership, Geography
- 9 unique skills total after dedupe

### Isabela (204)
- Artillery 5, Movement 7, Training 5
- Original: Accuracy, Ballistics, Engineering, Geography
- Add Explosives, Artillery Teaching, Attack Tactics, Spy, Defense Tactics
- 9 unique skills total after dedupe

Maria, Sophia, Fatimah, Kate and Sakurako are unlock-only: original stats/skills remain unchanged.

## Presentation rule
If original EW4 UI displays a stat, show the effective modified value naturally. Never add custom `MOD`, `FREE`, `∞`, `enhanced`, `+120 cheat`, or similar explanation labels. Raw original commander/princess data remains untouched; player-only overrides are layered separately.
