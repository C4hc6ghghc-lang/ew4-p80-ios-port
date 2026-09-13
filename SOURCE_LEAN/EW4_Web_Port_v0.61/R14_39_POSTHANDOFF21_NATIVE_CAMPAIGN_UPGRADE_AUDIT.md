# R14-39 Post-Handoff 21 — Native Campaign SceneUpgrade Audit

Date: 2026-09-10

## Scope
P21 restores the original Campaign technology progression loop rather than adding a Web-only upgrade screen. Evidence was taken from `form_upgrade` / Campaign `btn_lvlup`, `def_warzonetech.xml`, and the native upgrade/income/recruit/transport code paths.

## Frozen behavior
- `form_upgrade` shell: 421x265; Campaign stage-list `btn_lvlup` entry.
- Five visible pages and 22 visible military technologies. Internal technology array remains 26 entries; IDs 22-25 are Farm, Financial, Factory, Dock and are not exposed as an invented sixth tab.
- Six warzones retain independent 26-entry technology states initialized exactly from `assets/data/def_warzonetech.xml`.
- Stars are a persistent spendable wallet capped at 999. A victory only awards the positive delta between the new native 1-5 stage score and the historical best.
- Legacy pre-P21 saves migrate Stars as the sum of historical best native stage scores because no previous build contained a Star spending path.
- Native 26x4 upgrade-cost table is implemented. Technology upgrades deduct Stars and persist per warzone.
- Military tech `< 0` locks the corresponding recruit/build option. Technology level is NOT formation grade. Newly recruited/built units receive initial training 0/1/2/3 according to internal tech 0/1/2/3; original 1/2/3 formation selection remains unchanged.
- Economic tech bonuses are applied after facility income: Farm +10/+20/+30 food, Financial +20/+40/+60 money, Factory +10/+20/+30 industry at internal levels 1/2/3. Commander commerce multipliers do not multiply these tech bonuses.
- Dock gates Campaign sea transport: infantry at internal level >=1, cavalry >=2, artillery >=3; naval units remain native sea units.
- Campaign tech is snapshotted into a battle when the battle begins. BattleSave schema 6 persists the 26-entry snapshot so later HQ upgrades do not mutate an older saved battle.
- P21 controller/data/assets are Service Worker precached for iPhone PWA offline use.

## Important correction locked by P21
The native unit field changed by Campaign military tech is the unit training level, not the Web formation-grade field. P21 explicitly prevents technology from overwriting `grade`.

## Verification
- Original warzone-tech manifest: 6 x 26 = 156 levels, byte-for-byte semantic reproduction from retained original XML; SHA256 `35320e99f2c39ac998c92340cb221653ae3f2c9fe8bb24b9ee3bfb321efe64db`.
- Service Worker CORE asset census: 231 entries, 0 missing.
- Independent Node suite: 97 / 97 PASS.

## Remaining uncertainty
Dock permission is behaviorally recovered and enforced, but exact original transport-ship renderer choice (`transportship1/transportship2`) still needs true renderer/visual calibration. This does not block the permission/state logic frozen in P21.
