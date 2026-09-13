## P35 final native presentation — 2026-09-10
- Keep recovered 568x320 battle coordinates but move the battle Canvas to a device-density/stage-scale HiDPI backing store (up to 4x), removing the systemic whole-canvas upscale that could blur map art, formations, flags and HP/commander overlays together on modern iPhones.
- Replace battle `offsetX/offsetY` input with `clientX/clientY -> canvas rect -> 568x320` inverse mapping so CSS scale/HiDPI never shifts tap, path or pinch anchors.
- Apply equivalent HiDPI backing to the 410x320 conquest country preview while keeping all marker geometry unchanged.
- Preserve unit scale, native refpoints, hex centers, 0.2..1.0 camera, 0.5 LOD and P34 layer ordering; do not hide raster blur by resizing formations.
- Remove user-facing `Web Port v0.61` shell wording, add iOS standalone metadata, suppress Web long-press/overscroll chrome and remove the stage card shadow without touching legacy save keys.
- Add map/unit integrity and native-presentation regressions. Final local suite: 122/122 PASS, 5/5 repeated; SW CORE 1054/1054.
- Current player MOD authority remains attack +4/+4, base troop HP +120 and movement +2. Any older +2/+2 examples further below are historical notes from earlier passes, not current runtime authority.

## P34 final visual closure candidate — 2026-09-10
- Close the remaining evidence-backed StageIntro geometry mismatches: native empty user-window header band, 180px-centered victory/best values, and the HD `pattern_stage_intro.png` decoration at its 0.5 logical size instead of the stretched Web draft.
- Close Talk geometry against `form_talk`: 78x78 logical commander portrait, exact mirrored content offset, original `board_dialog_ex.png`, and half-scale HD dialogue arrow.
- Make embarked transport selection explicit through the original item semantic: function 12 `Armored Carrier` -> `transportship2`, otherwise `transportship1`; retain native refpoints and per-segment facing/mirroring from P33.
- Remove the Web-only 6px minimum city/port label floor so those labels scale with the world at low zoom; native 0.2..1.0 camera range and 0.5 tactical/strategic split remain unchanged.
- Preserve P33 Attack-end HP/death presentation commit, result gate, native layer order, pointer interruption cleanup, all single-player logic and all user MOD rules.
- Add P34 closure regression and bump the offline cache without modifying protected save/upgrade cores.

## P33 visual timing polish — 2026-09-10
- Split already-computed combat results from presentation commit so HP/death feedback lands at the native authored Attack-motion endpoint rather than before impact or after the full Attack/Reload/Finish chain.
- Keep pending-kill units visually present until impact-time commit; delay result evaluation until that presentation completes; preserve combat RNG and AI decision semantics.
- Keep visual-only pending-impact state non-enumerable so frozen save serialization is untouched.
- Correct embarked transport facing along the current path segment and mirror `transportship1/2` around their original native refpoints while preserving each source sprite's natural orientation.
- Remove the Web-only StageIntro title and restore `board_dialog_ex.png` as the Talk board resource.
- Add lost-pointer-capture / window-blur cleanup without changing proven native zoom, tap-slop, pinch or 0.5 LOD contracts.
- Regression: 119/119 PASS; five consecutive full-suite runs all 119/119.


## r14-36 — Britain artillery 8
- Added original `gbr` Light/Heavy/Siege Artillery and Rocket levels 1/2: 8 units, 28 BILE motions.
- Advanced native animation mainline from 241/992 to 249 units / 1020 motions.
- Preserved native artillery state differences: Siege has no Reload; Rocket has no Finish.
- Reused r14-34 path-local BILE cycle guard for complete Siege Finish extraction.
- Added Britain artillery integration/zero-damage/runtime-sheet regressions; full JS suite 23/23 PASS.

# EW4 Web Port 0.61

## Locked modifications
- Medals: Infinity
- Badges / shields: Infinity
- Military academy refresh: Infinity / zero cost
- Campaign general hard cap: removed
- Conquest general hard cap: removed
- Player-owned units only: attack lower bound +4 and upper bound +4; base troop HP +120; movement +2

## 0.61 combat corrections
- Replaced average-attack placeholder with an actual inclusive attack interval roll.
- Lower attack bound is a first-class value in every roll and can no longer be silently averaged away.
- Independent lower/upper/flat modifier paths are centralized in `combat_core.js`.
- If a lower-bound modifier overtakes the previous upper bound, the effective upper follows it instead of deleting the lower modifier.
- Original attack equipment (`def_item.xml`, function 11) now raises both ends of the effective attack interval, including the lower end.
- Scenario/default commander equipment and future per-commander save equipment use the same modifier path.
- Player +2/+2 is applied only when the acting unit owner is the selected player country; AI is unchanged.
- Counterattacks use the same corrected interval core.
- Artillery active attacks continue to suppress ordinary counterattack.
- Dense Attack (skill 15) is honored for infantry HP-output scaling in the current reconstructed combat core.

## Compatibility
- Save schema version: 61
- Automatically migrates saves from `ew4_web_port_v06` and `ew4_web_port_v05`.

## Verification
- `combat_core.js` unit tests PASS.
- Chromium battle smoke test PASS on `campaign1_01.btl`.
- Player interval regression PASS: base 2–9 -> player 4–11.
- Lower-bound RNG regression PASS: RNG=0 returns exactly the computed minimum.
- Equipment regression PASS: infantry 1–5 + Ferguson Rifle (+6) + player (+2/+2) -> 9–13.
- AI isolation regression PASS: AI attack interval receives no player +2/+2.

## Still in progress
This is a port checkpoint, not a claim of 100% original runtime parity. Native alliance/event logic, original AI behavior, remaining combat modifiers, and the full BILE animation state machine are still being reconstructed from the APK/native library.

## Player-general enhancement layer (same 0.61 line)
- Original `commanders.json` is left untouched. Player-only overrides live in `assets/data/player_general_overrides.json`.
- AI-controlled copies of the same historical commander continue to use original APK stats and original four skills.
- All player-controlled commanders: max-rank HP bonus cap = +500; max-nobility healing cap = +25 HP/round.
- Napoleon player-only exception: max-rank HP bonus cap = +1000; max-nobility healing cap = +100 HP/round.
- Seven selected player-only commanders have movement/march set to 7, intentionally above the original 0-5 attribute ceiling.
- Napoleon: infantry 5; movement 7; add Explosives, Geography, Assault Art, Accuracy, Ballistics, Defense Art, Spy, Leadership.
- Davout: cavalry 5; artillery 5; movement 7; add Maneuver, Leadership, Defense Art (Surprise already existed and is deduplicated).
- Lannes: cavalry 5; movement 7; add Formation, Infantry Tactics, Bugle, Spy, Defense Art (Leadership/Geography already existed).
- Murat: cavalry 5; artillery 5; movement 7; add Geography, Defense Art, Raid, Maneuver, Leadership (Surprise already existed).
- Soult: infantry 5; artillery 5; movement 7; add Leadership, Infantry Tactics, Bugle, Geography, Defense Art.
- Suchet: infantry 5; movement 7; fill missing infantry + cavalry skill families, including teaching skills, plus Assault Art.
- Massena: cavalry 5; artillery 5; movement 7; fill missing infantry + artillery + cavalry skill families, including teaching skills, plus Assault Art.
- HQ now exposes a player-general detail panel showing effective player stats, added skills, rank HP bonus and nobility healing, with zero-cost rank/nobility upgrading for owned commanders.
- Corrected skill ID regression: Dense Attack is skill 15 in the APK; skill 16 is Helmsman.

## Verification additions
- Player override browser regression PASS for all seven selected commanders.
- AI-isolation regression PASS: original AI stats remain unchanged.
- Max-rank/max-nobility caps PASS: Napoleon +1000/+100, other selected generals +500/+25.
- Napoleon battle assignment PASS: +1000 max HP applied at rank 14 and +100 HP round healing at nobility 9.
- Extended skill arrays PASS: Napoleon 12, Davout 7, Lannes 9, Massena 17, Suchet 12, Soult 9, Murat 9 unique skills.

## Continued 0.61 runtime pass
- The seven player-only enhanced generals are now regression-tested against the live combat core, not only against the HQ panel.
- Requested lower-bound skills are active in the repaired die floor: Infantry Tactics (13), Maneuver (11), Ballistics (7).
- Requested upper-bound skills are active in the die ceiling: Formation (12), Surprise (10), Explosives (8).
- Accuracy/Bugle/Raid avoidance-bypass, Spy anti-fort bonus, Leadership morale protection, Geography movement, Engineering artillery movement, Navigation naval movement, Dense Attack full-formation preservation, Attack Tactics and Defense Tactics are connected to battle resolution.
- AI copies of Napoleon/Davout/Lannes/Massena/Suchet/Soult/Murat still receive original APK stats/skills only.
- Enemy AI was upgraded from one-hex shuffling to full movement-point path selection. It now searches reachable cells, prefers legal firing positions, can move and attack in the same AI action, and still uses the same skill-aware damage pipeline.
- Original field-work definitions from `def_installation.xml` are now loaded: trench, fence, bunker. Player land units can construct them with original `def_card.xml` base costs, and their infantry/cavalry/artillery avoidance values feed the same terrain/building damage-reduction pipeline.
- Troopship base cost is read from original `def_card.xml`; player land troops on a coastline can enter transport state, move across sea cells, use original transport-ship art, suffer the embarked combat penalty unless Sailor/Armored Carrier cancels it, and disembark on land.
- PWA service-worker cache revision bumped so iPhone home-screen installs do not keep stale 0.61 JS/data after this pass.

## New verification
- `test_enhanced_generals_combat.js`: PASS.
- Napoleon player infantry lower-bound test: player +2 and Infantry Tactics +1 both survive into the die floor.
- Davout cavalry lower/upper skill test: Maneuver and Surprise both survive simultaneously.
- Massena artillery lower/upper skill test: Ballistics and Explosives both survive simultaneously.
- `test_data_integrity.js`: PASS (101 BTL entries, 208 commanders, original trench/fence/bunker and troopship build cards present).
- `node --check app.js`, `combat_core.js`, and all combat/player-override regression tests: PASS.

## Native BTL objective / event reconstruction pass
- Reverse-engineered the BTL trailing objective/event block instead of guessing goals from stage text.
- All 101 runtime BTL files now have a native trigger companion record in `assets/data/battle_native_triggers.json`.
- Extracted 144 native strategic objective positions; 144/144 map back to a real BTL city/port/facility object.
- Objective examples verified directly from BTL data: Toulon -> Bordeaux/Marseille; Egypt -> Izmir plus a stable target; Marengo -> Milan; Austerlitz -> Prague/Vienna; North American Independence I -> Lexington.
- Extracted 360 native event records. Current decoded fields include event ordering, trigger class, trigger parameters, event id, optional map position and optional packed country code.
- Parsed original `def_dialogues.xml`: 336 original campaign dialogue definitions. 323/360 BTL event records now link directly to the original commander id, dialogue text id, left/right portrait placement flag, and Chinese dialogue text.
- Added original BTL objective star markers to the live battlefield and status summaries.
- Added a real battle-end overlay using the original victory texture and original defeat music asset. Base elimination victory/defeat is functional while exact native special-condition semantics remain under reconstruction.
- Capturing a facility now immediately re-evaluates battle result state.
- Retry now preserves the player's pre-battle general assignments instead of silently resetting them.
- Added `test_native_triggers.js` regression coverage for all 101 trigger records, 144/144 objective-object mappings, 360 events, 86 packed country-code events, and 323 dialogue-linked events.
- PWA cache bumped to r8 and now pre-caches the native trigger/dialogue DB plus victory/defeat assets.

### Important parity note
The extracted BTL targets and event records are native data. Their exact trigger semantics (especially alliance changes, scripted reinforcements, fires, country-state changes and special chapter unlock conditions) are not yet guessed into the runtime. They remain data-driven and will only be activated as each trigger class is verified against the native library.

## Original round-trigger dialogue runtime
- Verified a native BTL event family instead of inventing a trigger rule: `trigger_type=2` + `param_a=4` contains exactly 240 records, and all 240/240 link to original `def_dialogues.xml` dialogue entries.
- Their `param_b` values form round numbers only: 1, 2, 3, 4, 5, 6, 7, 10, 14. 217 of the 240 are round-1 dialogue events; later values line up with reinforcement/warning/tutorial dialogue timing.
- 0.61 now schedules this verified event family by battle round and displays the original commander portrait, commander name and original Chinese dialogue in an EW4-layout talk panel based on `form_talk` / `board_dialog_ex.png`.
- Multiple dialogues on the same round are queued in native sequence order. Tapping the panel advances the queue.
- Player battlefield input and End Turn are blocked while the native talk panel is open, matching modal talk behavior.
- Fired event ids are remembered for the current battle so the same native round dialogue does not replay within that run.
- Round-trigger dialogue state resets cleanly on retry/new battle; retry still preserves the player's general assignments.
- `test_round_dialogues.js` validates all 240 native scheduled dialogue records, including 217 round-1 records and the exact observed round set.
- PWA cache revision bumped to r9 and now pre-caches the original dialogue board/arrow assets.


## 2026-09-07 · 原生火灾事件 + 战斗存读档

- 继续保持版本号 **0.61**。
- `trigger_type=2 / param_a=5` 的 31 条原生回合火灾事件已接入运行时：按 BTL 原始回合与地图位置触发，并使用 APK 原 `anim_fire_hd.png` 与火焰音效。
- 防火术（skill id 2）与灭火设备 Pumper（item function 16）现在会真实阻止所在格起火；防火单位进入燃烧格会清除该格火势。
- 原版提示明确说明“燃烧区域会对部队造成伤害”，但精确 native 伤害常量仍未完全还原，因此当前不伪造火灾伤害数值。
- 右上角暂停按钮改回原版式 `form_pause` 行为，不再直接跳主菜单。
- 暂停菜单接入：存档 / 设定 / 重新开始 / 退出。
- 按原 `form_save` 布局接入 **自动存档 + 6 个手动存档槽**。
- 战役、征服选择页加入读档入口。
- 战斗存档保存：当前关卡、玩家国家、回合、资源、所有动态单位（含新征募）、城市/设施归属、ownership、野战工事、火灾格、已执行 native trigger、玩家上将配置、相机位置。
- 读档不会再次重复叠加玩家将领军衔 HP，也不会重复执行已经记录的 native trigger。
- 自动存档在新回合事件/对白完成后写入，退出战斗前也会刷新。
- PWA cache 升级为 `ew4-port-v061-r10`，加入 `battle_save_core.js`、原生火焰贴图和火焰音效。

### 本轮测试

- combat_core：PASS
- player overrides：PASS
- 7 名玩家强化将领回归：PASS
- 101 BTL / 208 commanders / fieldworks：PASS
- 144/144 native objectives：PASS
- 360 native triggers：PASS
- 240/240 round-dialogue events：PASS
- 31 native fire events / 16 battles：PASS
- battle save serialize/normalize round-trip：PASS

- 已从原版 `form_stageintro` + BTL 文件头高置信度锁定回合字段：`header.raw[12]` = 普通胜利回合线，`header.raw[13]` = 重大胜利回合线。87/87 正式 campaign BTL 均满足普通线 ≥ 重大线。
- 战役列表现在直接显示“胜利 X 回合 / 重大胜利 Y 回合”；超过普通胜利回合线判失败，在重大胜利回合线内完成则显示“重大胜利”。征服模式不套用此战役回合线。

## Native entity-trigger pass: occupation + unit destruction

- Reverse-engineered and wired the two non-round trigger families conservatively:
  - `trigger_type = 0`: occupation / ownership-change path.
  - `trigger_type = 1`: unit destruction / death path.
- Generated `assets/data/native_trigger_targets.json` from the original BTL entity records instead of guessing from dialogue text.
- High-confidence coverage:
  - capture/occupation triggers: **31 / 33** mapped to exact original map-object indices.
  - destruction/death triggers: **23 / 25** mapped to exact original unit indices.
- The remaining 2 capture + 2 death bindings are explicitly kept unresolved and are NOT fired heuristically:
  - capture: `campaign3_03.btl #2`, `campaign3_13.btl #4`
  - death: `campaign3_14.btl #2`, `campaign4_09.btl #3`
- Native event action switch now includes the newly confirmed `action 3`:
  - action 0 => target-country morale `+1`
  - action 1 => target-country morale `-1`
  - action 2 => target-country morale `-2`
  - action 3 => target-country morale `-3`
  - action 4 => dialogue-only branch
  - action 5 => fire at native `param_c` cell
- Country morale effects use the native three-round timer and still respect Leadership cancellation of negative morale.
- Capture/death events share `nativeAppliedEvents`, so manual save/load and autosave do not replay already-applied native effects.
- If an entity trigger owns an original dialogue, the original commander portrait + Chinese dialogue are queued at the actual occupation/destruction moment.
- If an entity trigger owns a fire action, the existing original fire animation/audio pipeline is reused.
- Added `test_native_entity_triggers.js`; all previous combat/player-overrides/dialogue/fire/save/turn-limit tests remain green.
- PWA cache bumped to `ew4-port-v061-r11` and now pre-caches `native_event_core.js` + `native_trigger_targets.json`.

## Recovery continuation pass · cavalry / construction supply / reinforcement audit

- Recovered the latest 0.61 working tree after an interrupted reasoning run; no previously written runtime work was lost.
- Confirmed from the original tutorial text that cavalry receives another action after annihilating an enemy. This is now a base rule for both player and AI cavalry, not a player-only buff.
- AI cavalry can consume that extra action in the same AI phase instead of silently losing it.
- Confirmed original complex-terrain mobility wording for Light Infantry. Light Infantry now preserves its high movement through complex land terrain; the previous over-broad behavior that effectively granted this to all infantry was removed.
- Geography / matching equipment terrain-ignore continues to use the same movement-cost bypass path.
- Field fortifications (trench / fence / bunker) are now explicitly infantry-only in both UI and execution, matching the original tutorial rule.
- Construction supply is now driven directly from original `def_construction.xml` data and applies to **all factions**, not just the player. A wounded friendly unit stationed on its own construction receives that construction level's native supply value once per completed battle round.
  - city supply: 1 / 2 / 4 / 6 / 8 / 10 / 12
  - industry supply: 2 / 4 / 6 / 8
  - stable supply: 2 / 4 / 6
  - port supply: 2 / 4 / 6
  - farmland supply: 0
- Player-only nobility / flag / tent healing remains separate from the global construction-supply pass, preventing double-counting and preventing AI copies from receiving player-only general enhancements.
- Added `test_cavalry_supply_rules.js`; all current 0.61 regression tests remain green.

### Reinforcement safety audit

- Explicitly rejected `unit.raw[4]` as a reinforcement appearance-round field.
- Strong counterexample: `campaign2_06.btl` has a native round-4 dialogue stating that enemy reinforcements have joined the battlefield, but contains **zero** units with `raw[4] == 4`.
- `raw[4]` is also heavily populated in conquest data with values such as 20 / 30 / 40 / 50 / 55, so hiding units until that value would corrupt native initial deployments.
- Reinforcement activation therefore remains unresolved and is intentionally not guessed. See `REINFORCEMENT_FIELD_AUDIT_0.61.md`.
- PWA cache remains on the recovered 0.61 r12 line for this pass.

## 2026-09-07 · Multi-country turn scheduler + independent national ledgers + reinforcement safety pass

- Version remains **0.61**; this is a bottom-layer continuation, not a feature reset.
- Replaced the merged “all enemies in one phase” AI loop with deterministic **country-by-country action phases**. Each living non-player, non-neutral country receives its own action segment in BTL country-index order.
- In conquest, AI target acquisition and capture now use pairwise decoded conquest relations instead of “everyone who is not the player”. Same-group allies no longer attack/capture each other; opposing relation groups can fight and capture facilities from each other.
- Campaign safety correction: campaign `relation_hint` is not treated as a conquest alliance group. Copenhagen has player Britain and enemy Denmark both tagged `1`, proving that reuse would be wrong. Campaign keeps recovered player-vs-nonplayer hostility while non-player countries are grouped together for AI-vs-AI decisions until native campaign diplomacy is decoded.
- Added `country_turn_core.js` as the isolated country relation / scheduler / resource-ledger decoder.
- Added independent `countryResources` ledgers for money / industry / food. Conquest mode reads each country's high-confidence BTL economy triplet at `country.raw_u32_36_180[30..32]`; campaign/tutorial keeps the stage-header treasury for the selected player.
- The player HUD and player purchases remain bound to the selected player's ledger, preserving the existing UI while removing the old hidden global-account coupling.
- Each AI country now settles its own facility income, industry income, food income and unit food upkeep after its country action segment.
- Battle-save schema advanced to **2** to persist all country ledgers. Schema-1 saves remain readable; their legacy player resource state is preserved on load.
- Added `test_country_turn_core.js` and expanded the save/runtime contract tests.
- Reinforcement reverse-engineering advanced conservatively: `raw[4]` remains rejected; `raw[9] == round` was also eliminated because `raw[8..9]` is the decoded map-position field.
- Found a decisive narrative counterexample: `campaign4_03.btl` event 4035 explicitly says enemy reinforcements joined the battle, but its verified native event action is `param_a=1`, Turkish country morale -1 at round 11. Reinforcement dialogue therefore does not imply a spawn action.
- Added `REINFORCEMENT_EVENT_AUDIT_0.61.json` + `test_reinforcement_safety.js`. No speculative reinforcement spawning/hiding has been enabled.
- PWA cache bumped to `ew4-port-v061-r13` and now pre-caches `country_turn_core.js`.
- Full current `test_*.js` regression suite passes after the changes.


## r14-17 — Britain native infantry animation rebuild
- Added Britain (`gbr`) Militia/Line Infantry/Light Infantry/Grenadier/Guards grades 1–3.
- Added 66 true BILE native motion assets at 24 FPS; Grenadier/Guards Attack1 retained.
- Main native-animation manifest advanced from core30 to core45: 45 units / 198 motions.
- Service Worker cache advanced for the new animation payload.
- 23/23 JS regression tests pass.


## r14-18 — Russia native infantry animation rebuild
- Added Russia (`rus`) Militia/Line Infantry/Light Infantry/Grenadier/Guards grades 1–3 from original APK BILE motion resources.
- Preserved native 24 FPS timing and Attack1 paths for Russian Grenadier/Guards grades 1–3.
- Main native-animation manifest advanced from core45 to core60: 60 units / 264 motions.
- Runtime now loads `assets/data/native_animation_core60.json`; Service Worker cache advanced to `ew4-port-v061-r14-18-rusanim`.
- Britain r14-17 assets remain unchanged and preserved.

## r14-19 — Machine Gun infantry completeness fix
- Corrected the national-infantry migration scope: original `def_army.xml` defines Machine Gun as `type="infantry"`, not artillery.
- Original recruit infantry family count is six: Militia, Line Infantry, Light Infantry, Grenadier, Guards, Machine Gun.
- Machine Gun has grades 0/1 (runtime unit names 1/2), so a fully animated national infantry roster is 17 unit definitions, not 15.
- Added native BILE Machine Gun 1/2 animations for generic, France (`fra`), Britain (`gbr`) and Russia (`rus`).
- Added 8 unit definitions / 24 motions; each unit preserves native Ready -> Attack -> Finish -> Ready behavior and attack `speed=2.5`.
- Main native-animation manifest advanced from core60 to core68: 68 units / 288 motions.
- Runtime now loads `assets/data/native_animation_core68.json`; Service Worker cache advanced to `ew4-port-v061-r14-19-machinegunfix`.

## r14-20 — original recruit-tree audit + Austria native infantry animation
- Audited original `def_army.xml`: full army template = 41 definitions (17 infantry / 8 cavalry / 8 artillery / 4 warship / 4 fort).
- Locked the omissions to avoid: Machine Gun belongs to infantry; Armored Car belongs to cavalry; Rocket belongs to artillery.
- Audited `def_motion.xml` separately from stat templates and confirmed widespread minor-country land visual variants; full visual migration cannot stop at the major powers.
- Added Austria (`aus`) complete infantry roster: 17 definitions / 72 true BILE motions at native 24 FPS, including six Grenadier/Guards Attack1 paths and Machine Gun 1/2.
- Main native-animation manifest advanced from core68 to core85: 85 units / 360 motions.
- Runtime now loads `assets/data/native_animation_core85.json`; Service Worker cache advanced to `ew4-port-v061-r14-20-austriaanim`.
- 23/23 JS regression tests pass; stale test-only cache-version regex was widened to accept r14-20+.

## r14-21 — Prussia complete infantry17 native animation
- Added all 17 Prussia (`pru`) infantry definitions from original BILE motion data, including Machine Gun 1/2.
- Added 72 native motion assets; Grenadier/Guards Attack1 preserved and Machine Gun uses native Ready -> Attack -> Finish with speed 2.5.
- Main native-animation manifest advanced from core85 to core102: 102 units / 432 motions.
- Runtime now loads `assets/data/native_animation_core102.json`; Service Worker cache advanced to `ew4-port-v061-r14-21-prussiaanim`.
- Added regression coverage proving Coastal Fort remains present in army stats and Ready/Attack visual manifests.
- 23/23 JS regression tests pass.
## r14-22 — Ottoman complete infantry native animation batch
- Added all 17 Ottoman (`tur`) recruitable infantry animation definitions from original BILE resources.
- Added 72 native motion assets, preserving Grenadier/Guards Attack1 and Machine Gun Ready/Attack/Finish at native attack speed 2.5.
- Runtime animation mainline advanced from 102/432 to 119/504 (`native_animation_core119.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-22-ottomananim`.
- Prior 102 unit / 432 motion records verified unchanged; full JS suite 23/23 PASS.


## r14-23 — Spain complete infantry native animation batch
- Added Spain (`spa`) complete recruit-infantry animation family: 17 unit definitions.
- Added 72 original BILE native motion assets at 24 FPS.
- Preserved Grenadier/Guards Attack1 branches (6 total) and Machine Gun 1/2 native Ready -> Attack -> Finish flow with attack speed 2.5.
- Runtime animation mainline advanced from 119/504 to 136/576 (`native_animation_core136.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-23-spainanim`.
- Verified previous 119 units / 504 motions are byte-equivalent at manifest-record level after merge.
- Full JS regression suite: 23/23 PASS.

## r14-24 — USA complete infantry native animation batch
- Added United States (`usa`) complete recruit-infantry animation family: 17 unit definitions.
- Added 72 original BILE native motion assets at 24 FPS: Militia/Line Infantry/Light Infantry/Grenadier/Guards grades 1–3 plus Machine Gun grades 1–2.
- Preserved alternate `Attack1` for Grenadier 1–3 and Guards 1–3 (6/6) and original Machine Gun `Ready -> Attack -> Finish` state path with attack speed attribute 2.5.
- Runtime animation mainline advanced from 136/576 to 153/648 (`native_animation_core153.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-24-usaanim`.
- Regression protection: all 136 pre-r14-24 unit records and all 576 pre-r14-24 animation asset records compare byte-for-JSON-value identical after merge; 23/23 JS tests pass.

## r14-25 — generic cavalry8 native animation template
- Added the complete generic recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2, Armored Car 1/2.
- Added 32 original BILE native motion assets at 24 FPS.
- Preserved cavalry-specific state differences instead of reusing the infantry template: Light/Heavy include UndoReady + Finish; Guards Cavalry include Attack1/Reload/Finish; Armored Car uses Ready + Attack only.
- Guards Cavalry Attack1 is regression-tested through the proven guns-vs-warship/fort selection path.
- Armored Car Attack keeps the original Motion@speed attribute `2.5`; playback-speed math remains intentionally unresolved rather than guessed.
- Runtime animation mainline advanced from 153/648 to **161 units / 680 motions** (`native_animation_core161.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-25-genericcavalry`.
- All 153 prior unit records and 648 prior asset records remain unchanged; 680/680 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-26 — France complete cavalry8 native animation
- Added the complete France (`fra`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original France-specific BILE native motion assets at 24 FPS; these are independently decoded country assets rather than generic aliases.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 161/680 to **169 units / 712 motions** (`native_animation_core169.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-26-francecavalry`.
- All 161 previous unit records and 680 previous asset records remain unchanged; 712/712 runtime PNG sheets validate; full JS suite 23/23 PASS.


## r14-27 — Britain complete cavalry8 native animation
- Added the complete Britain (`gbr`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Britain-specific BILE native motion assets at 24 FPS; no French/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 169/712 to **177 units / 744 motions** (`native_animation_core177.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-27-britaincavalry`.
- All 169 previous unit records and 712 previous asset records remain unchanged; 744/744 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-28 — Russia complete cavalry8 native animation
- Added the complete Russia (`rus`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Russia-specific BILE native motion assets at 24 FPS; no Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 177/744 to **185 units / 776 motions** (`native_animation_core185.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-28-russiacavalry`.
- All 177 previous unit records and 744 previous asset records remain unchanged; 776/776 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-29 — Austria complete cavalry8 native animation
- Added the complete Austria (`aus`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Austria-specific BILE native motion assets at 24 FPS; no Russia/Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 185/776 to **193 units / 808 motions** (`native_animation_core193.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-29-austriacavalry`.
- All 185 previous unit records and 776 previous asset records remain unchanged; 808/808 runtime PNG sheets validate; full JS suite 23/23 PASS.


## r14-30 — Prussia complete cavalry8 native animation
- Added the complete Prussia (`pru`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Prussia-specific BILE native motion assets at 24 FPS; no Austria/Russia/Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 193/808 to **201 units / 840 motions** (`native_animation_core201.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-30-prussiacavalry`.
- All 193 previous unit records and 808 previous asset records remain unchanged; 840/840 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-31 — Ottoman complete cavalry8 native animation
- Added the complete Ottoman (`tur`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Ottoman-specific BILE native motion assets at 24 FPS; no Prussia/Austria/Russia/Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 201/840 to **209 units / 872 motions** (`native_animation_core209.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-31-ottomancavalry`.
- All 201 previous unit records and 840 previous asset records remain unchanged; 872/872 runtime PNG sheets validate; full JS suite 23/23 PASS.


## r14-32 — Spain complete cavalry8 native animation
- Added the complete Spain (`spa`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original Spain-specific BILE native motion assets at 24 FPS; no Ottoman/Prussia/Austria/Russia/Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 209/872 to **217 units / 904 motions** (`native_animation_core217.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-32-spaincavalry`.
- All 209 previous unit records and 872 previous asset records remain unchanged; 904/904 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-33 — USA complete cavalry8 native animation
- Added the complete United States (`usa`) recruit cavalry roster: Light Cavalry 1/2, Heavy Cavalry 1/2, Guards Cavalry 1/2 and Armored Car 1/2.
- Added 32 original USA-specific BILE native motion assets at 24 FPS; no Spain/Ottoman/Prussia/Austria/Russia/Britain/France/generic runtime sheets are substituted.
- Preserved Light/Heavy/Guards `UndoReady`, Guards Cavalry Attack1 on both grades, Guards Reload/Finish paths and Armored Car Motion@speed `2.5`.
- Runtime animation mainline advanced from 217/904 to **225 units / 936 motions** (`native_animation_core225.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-33-usacavalry`.
- All 217 previous unit records and 904 previous asset records remain unchanged; 936/936 runtime PNG sheets validate; full JS suite 23/23 PASS.
- This closes the generic + France/Britain/Russia/Austria/Prussia/Ottoman/Spain/USA standardized cavalry8 production milestone; smaller-state visual mappings are still not globally audited/complete.

## r14-34 — Generic complete artillery8 native animation + BILE cycle guard
- Added the complete generic recruit artillery roster: Light Artillery 1/2, Heavy Artillery 1/2, Siege Artillery 1/2, Rocket 1/2.
- Added 28 original BILE native motion assets at 24 FPS with family-specific native chains: Light/Heavy `Attack -> Reload -> Finish -> Ready`, Siege `Attack -> Finish -> Ready`, Rocket `Attack -> Reload -> Ready`.
- Fixed a real extractor failure in original siege-artillery Finish timelines: `130..138站直` contain self-referential BILE layers. New path-level cycle guard cuts only recursive re-entry; Light Artillery non-cycle regression is 8/8 runtime sheets byte-identical to pre-fix output.
- Runtime animation mainline advanced from 225/936 to **233 units / 964 motions** (`native_animation_core233.json`).
- Service Worker cache advanced to `ew4-port-v061-r14-34-genericartillery`.
- All 225 previous unit records and 936 previous asset records remain unchanged; 964/964 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-35 France artillery 8 native-animation micro-batch
- Added original French `fra` Light Artillery 1/2, Heavy Artillery 1/2, Siege Artillery 1/2, and Rocket 1/2 true BILE animations.
- Added 8 French artillery definitions / 28 unique motion assets; animation core advanced 233/964 -> 241/992.
- Preserved native per-family attack chains: light/heavy Attack->Reload->Finish, siege Attack->Finish, rocket Attack->Reload.
- Reused the r14-34 path-local BILE cycle guard; French Siege Finish extracted completely at 67/66 frames rather than being skipped.
- Fixed integration metadata assembly by restoring each new asset's authoritative `world_union` from its extracted BILE manifest before merging into the runtime core.
- Existing r14-34 233 units / 964 motions compare unchanged; all 992 runtime PNGs validate; full JS regression remains 23/23 PASS.

## r14-37 — Russia complete artillery8 native animation
- Added Russia (`rus`) Light Artillery 1/2, Heavy Artillery 1/2, Siege Artillery 1/2, and Rocket 1/2 original BILE native animation.
- Added 8 unit definitions / 28 motion assets; runtime core advanced 249/1020 -> **257 units / 1048 motions** (`native_animation_core257.json`).
- Preserved native family chains: Light/Heavy Attack->Reload->Finish, Siege Attack->Finish, Rocket Attack->Reload.
- Reused the r14-34 path-level BILE cycle guard; Russia Siege Finish extracts completely rather than being skipped.
- Restored authoritative per-asset `world_union` metadata during family-pack integration.
- All previous 249 units / 1020 assets compare unchanged; 1048/1048 runtime PNG sheets validate; full JS suite 23/23 PASS.

## r14-38 — Austria Artillery 8 + original Military Academy form fidelity pass
- Added Austria-specific Light/Heavy/Siege/Rocket artillery 1/2: 8 units / 28 original BILE motions.
- Main native animation core: 257/1048 -> 265/1076; old 257 units and 1048 motion records remain JSON-value identical.
- Preserved artillery native state families: Light/Heavy Attack->Reload->Finish->Ready; Siege Attack->Finish->Ready; Rocket Attack->Reload->Ready.
- Rebuilt Military Academy around original APK `form_getgeneral` 568x320 geometry and original UI assets.
- Corrected original academy tier behavior to 6 / 4 / 2 candidates and corrected pool ordering: low IDs 105-200, middle 31-104, high 1-30.
- Academy refresh stays unlimited; medals, badges and player general cap remain infinite backend overrides without replacing the native-form controls.
- Fixed academy back navigation so deployment -> academy -> back returns to deployment, HQ -> academy -> back returns to HQ.
- Corrected `pattern_getgeneral_2_1` ±0.8 / ±0.5 scale-anchor geometry from `layout-568h.xml`.
- Full JS suite: 23/23 PASS.
- Final-package size ceiling remains <=450 MB; current expanded PNG animation representation is development-only and requires a later production repack.

## r14-39 post-handoff patch 1
- Re-authorized player medals and badges/shields as unlimited backend resources; native price/currency presentation stays intact.
- Added unlimited non-consuming in-battle SceneUseItem consumables for original IDs 11..15 (Wine, Spirit, Medikit, Medikit L, First Aid Box) without adding FREE/∞ UI labels.
- Extended native `def_effectsanim` scheduling so supported visual cues share the exact timing data already used by battle SFX.
- Integrated original `effect_mgunfire.xml` dual-emitter machine-gun muzzle flash/smoke with native offsets and left/right rotation.
- Regression suite: 58/58 PASS.

## r14-39 post-handoff patch 2
- Integrated original Light/Heavy/Siege Artillery visual effects from `def_effectsanim.xml`: `effect_lightgun.xml`, `effect_gunnery.xml`, `effect_gunnery1.xml` with native timing, offsets and left/right rotations.
- Added all 11 native emitters from those three effect XMLs to the existing `eff.png` particle runtime.
- Fixed timeline-container rotation for non-zero-speed particles: cue rotation now rotates both particle velocity angle and sprite rotation, preventing left-facing artillery smoke from using right-facing motion physics.
- Added artillery visual timeline regression coverage; rocket/naval visuals remain explicitly out of scope for this micro-batch.

## r14-39 post-handoff patch 3 — native Rocket attack visual timeline
- Added original `effect_rocket1.xml` particle definition to the combat/simple-effect runtime (cloud + additive firecloud emitters from `eff.png`).
- Rocket grade 1/2 left/right attacks now render the APK-authored three-shot visual timeline at 1.6s / 1.8s / 2.0s, paired with the existing original `sfx_rocket.wav` cues.
- Preserved native offsets: grade 1 ±25,-23; grade 2 ±12,-20; left cue rotation is the APK-authored 220 degrees rather than an invented 180-degree mirror.
- `effect_rocketartillery1/2.xml` and naval effects remain unhooked until a proven original call path is established.
- Added `test_native_rocket_visual_timeline.js`; service worker cache bumped to `ew4-port-v061-r14-39-rocketvisual3`.

## r14-39 post-handoff patch 4 — native camera / layer order / low-zoom strategic LOD
- Reversed the original `CEntityCamera` battle gesture path from `libeuropean-war-4.so` instead of retaining the Web-only camera feel.
- Restored native zoom range 0.2..1.0 and native detail-interaction threshold 0.5; crossing below 0.5 clears tactical selection and disables unit/facility tapping.
- Restored one-finger incremental pan (`delta / zoom`), independent-axis 15 px tap slop, >40 px pinch gate, and event-by-event stationary-finger pinch anchoring.
- Restored the native 16-world-unit ordinary drag edge margin while keeping zoom/reposition clamping tight.
- Added the native low-zoom strategic unit LOD using exact `buildings_hd/mark_unit_0..21` sprites at intrinsic screen-space size. The 22 marker dimensions map sequentially to native army IDs 0..21.
- Proved native battle visual ordering through the global effect manager: Background -> SelectLower -> Outline -> HexFrame -> Object -> SelectUpper -> global particles; low-zoom strategic markers are a later post-particle pass.
- Corrected Web ordering so SelectUpper precedes particles and low-zoom markers follow particles. Unit-owned movement effects remain globally rendered, matching the native manager architecture.
- Exact native 64/54 screen-to-cell convention is documented but not forced over the already-validated Web 64/53/26.5 map anchor until those coordinate conventions are reconciled.
- Added native camera and low-zoom LOD regression coverage; full JS suite: 62/62 PASS.

## r14-39 post-handoff patch 5 — native hex geometry + strategic status
- Reversed CEntityMap construction and battle hit-test from x86_64 native code, proving the canonical grid is odd-row 64x54 with 32px odd-row horizontal offset and cell point `x=q*64+(r&1?32:0), y=r*54-18`.
- Replaced the historical Web odd-column 64/53/26.5 approximation across rendering, exact hit-testing, hex outline, neighbors, path/range distance, depth order and initial battle camera framing.
- Added exhaustive geometry regression over 101 BTLs: 7,407 units + 8,001 objects round-trip through native world/cell conversion with 0 mismatches.
- Completed low-zoom strategic composition: own/ally/enemy/neutral relation ring, native HP arc geometry and exact red->yellow->#00ff80 integer color path, followed by exact `mark_unit_0..21` sprite.
- Added battle-save camera geometry tagging; legacy saves preserve gameplay state but recenter their obsolete approximation-space camera pose. Save zoom normalization now uses native 0.2..1.0.
- Service Worker cache advanced to `ew4-port-v061-r14-39-posthandoff5-nativehexstatus` and now precaches both native hex and low-zoom modules.
- Full JS suite: 65/65 PASS; compact BILE parity remains 1076/1076 PASS.

## r14-39 post-handoff patch 6 — native programmatic camera / opening focus
- Removed the incorrect use of `def_battlelist.xml centerx/centery` as battle-camera coordinates; those fields belong to campaign-selection map layout.
- Added the reversed native programmatic camera motor with GameSpeed-linked coefficients `0.012 / 0.015 / 0.020 / 0.020 / 0.020`, default GameSpeed 2, native snap thresholds, and no invented manual-drag fling.
- Fresh battles now prefer the first player-owned commander-bearing unit as the proven native opening focus; no-commander `ActionAssist` scoring remains an explicit fallback gap.
- Full JS suite: 66/66 PASS.

## r14-39 post-handoff patch 7 — player action camera focus/wait
- Attached the native 64x72 area safe-visibility test and source/target midpoint focus to legal player move and attack presentation.
- Restored native-style ordering: focus camera when needed -> wait until camera movement completes -> begin existing movement/attack gameplay and animation.
- Kept AI country-turn scheduling unchanged in this patch to isolate presentation risk.
- Full JS suite: 67/67 PASS.

## r14-39 post-handoff patch 8 — AI action camera + native path tie-break
- Attached the same proven source/target camera focus/wait path to normal-speed AI direct attacks, moves, and move-followed-by-attack continuations without rewriting the underlying combat/country scheduler.
- Enemy fast-forward now remains available during AI presentation; subsequent AI actions bypass camera focus, matching the native skip-presentation branch.
- Reversed native `CEntityMap` direction indices at `0x858f0`: E -> SE -> SW -> W -> NW -> NE.
- Proved this order is used by the actual movement route search (`0x85850 -> 0x8ddc0 -> 0x8dc40`), where directions 0..5 are expanded in sequence and equal candidates retain the first predecessor.
- Updated `EW4NativeHex.neighbors()` and made Web equal-cost queue ordering explicitly insertion-stable, reproducing native route tie-break behavior.
- Full JS suite: **69/69 PASS**; compact BILE remains **1076/1076 PASS**; Machine Gun Finish remains **18/18 PASS**.

## r14-39 post-handoff patch 9 — combat visual coverage + native core UI forms
- Expanded original combat particle coverage to every `def_effectsanim` effect with an actual APK XML source: **23 groups / 65 emitters**; four absent air/parachute XML sources remain explicitly unresolved rather than fabricated.
- Added native target-impact selection across body/wood/stone/cold/land/sea strike families, native four-band damage severity, and Rocket `rocketstrike`; target impact is timed after the authored attack motion.
- Completed working `GameSpeed` 1..5 and `ShowGrids` option controllers with persisted commit/cancel behavior; GameSpeed feeds the native camera motor.
- Rebuilt battle `form_unitinfo` to original 330x187 structure and finished `form_recruitunit` title/close/confirm chrome around the existing 441x185 content geometry.
- Recovered original `form_tutorials` 250x200 / three 145x40 buttons and `form_playnotice` 400x225 using the APK's original `html_notice` content.
- Tightened native victory/failure form geometry and retained the existing save-form recovery.
- Service Worker advanced to `ew4-port-v061-r14-39-posthandoff9-visualui` and now precaches `native_impact_effect_core.js`.
- Full JS suite: **73/73 PASS**; compact BILE **1076/1076 PASS**; Machine Gun Finish **18/18 PASS**.


## r14-39 post-handoff 10 — native single-player conquest selection
- Reversed the original conquest controller boundary: `GameMode==2` uses `SelConquest -> conquest N -> PlayerCountryID`; `form_selcountry` belongs to the `multiplay N` branch and is no longer treated as the single-player conquest selector.
- Replaced the old four-column Web country wall with a `form_conquestlist`-style screen: 410px map field, native 160x297 right list frame, 45px country rows, and native 80x22 `new_confirm` button at (468,298).
- Replaced text country summaries on the six conquest cards with `lbox_country_*`-style horizontal flag strips.
- Country map markers are projected from live BTL city/unit ownership through the native odd-row 64x54 world geometry; selected country marker is emphasized.
- Preserved gameplay semantics: selected BTL country `index` continues to be passed as `playerOwner` / PlayerCountryID.
- Service Worker advanced to `ew4-port-v061-r14-39-posthandoff10-conquestui` and precaches original conquest list UI assets.

## r14-39 Post-Handoff 11 — Native Main / Campaign Geometry
- Corrected `form_mainmenu` to original 568h coordinates: title x20/y15 at 0.5x; menu x435; button y=115/153/191/229/267.
- Corrected all six `form_selcampaign` battle-zone pins to the original APK coordinates.
- Restored campaign selector title wording to original `title_campaigns` (`剧 本`).
- Added native main/campaign layout regression contract and advanced the offline cache version.
- Reversed main-menu `btn_hq` native transition (`0xA1164 -> 0xA1690`) and removed the Web-only Headquarters card-wall scene. Main Headquarters now reuses original `SceneDeployGeneral` / `form_deploygeneral`.
- Split shared DeployGeneral controller by native context: battle context assigns a commander to the active unit; main-menu HQ context opens general information and cannot invoke battle deployment without a battle Map/target (`btn_deploy` callback `0x95C20`).
- Preserved native Headquarters shortcuts: Princess -> `ScenePrincess`, Military Academy -> `SceneGetGeneral`; `SceneShop` transition is proven but remains the next dedicated controller item rather than being faked with the battle-facility shop.
- Removed legacy `renderHQ`, `hqFilter`, `#hq-grid`, `.hq-card`, and `.hq-toolbar` remnants, including stale startup/rank-up redraw calls.
- Full JS suite: **76/76 PASS**; compact BILE **1076/1076 PASS**; Machine Gun Finish **18/18 PASS**.

## Post-Handoff 13 — Full compact BILE animation production coverage
- Replaced the production 265-unit manifest bottleneck with `native_animation_core877.json`.
- Production now exposes all 877 native unit definitions and all 3519 native motion references from the original compact BILE source.
- Added target-relative left/right attack direction to the native animation controller path, fixing naval/directional attack coverage while preserving `all` fallback.
- Verified 1754/1754 left/right unit attack chains and 7407/7407 live BTL units resolve to the full animation pack.
- Kept the production renderer on compact BILE/atlas; no expanded runtime-sheet PNG dependency was reintroduced.
- Historical 1076/1076 compact parity and Machine Gun Finish 18/18 repairs remain green.

## R14-39 Post-Handoff 21 — Native Campaign SceneUpgrade (2026-09-10)
- Restored spendable Campaign Stars, six independent warzone tech trees, original SceneUpgrade UI/controller, recruit/training/economic/Dock effects, and BattleSave schema 6 tech snapshots.


## r14-39 Post-Handoff 23 — Native Defense + Pause
- Direct continuation from user-designated P21 baseline.
- Selectively merged audited original `form_defense` interior; P21 campaign technology/save guards stayed byte-identical.
- Restored residual `form_pause` round-word/number geometry and bottom `pattern_reoganizion.png`.
- Full independent Node tree: 99/99 PASS; SW CORE: 240/240 present.
