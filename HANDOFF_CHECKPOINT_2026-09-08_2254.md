# EW4 Web Port 0.61 — r14-39 handoff checkpoint

Checkpoint time: 2026-09-08 22:54 +08:00

This is the handoff snapshot after the current assistant's work line. Do not restart from an older package. The original EW4 APK remains the sole authority for UI, controller, map, geometry, timing, animations, audio, and rules wherever original evidence exists.

## Project boundary — critical

This is **EW4 Web Port**, not ImperialFrontier. Do not import ImperialFrontier-only systems or numbers.

Do not add: custom transport price, custom garrison/fort rules, rollback, custom recruitment UI, custom neutral/diplomacy system, disaster generals, corps/fleet mechanics, ImperialFrontier economy/fort values, 9999-turn substitute caps, or other custom systems unless the user explicitly assigns them to this port.

## Latest test state

Run from `SOURCE_LEAN/EW4_Web_Port_v0.61`:

- 56 test files
- 56 PASS
- 0 FAIL

See `TEST_RESULTS_LATEST_56_OF_56_PASS.txt`.

## Original APK

`ORIGINAL_APK/ouluzhanzheng4_v1.4.42_uhrfojh_anfensi.com(1)(3).apk`

SHA-256:

`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

## Compact BILE / animation

Current integrated subset:

- 265 Unit definitions
- 1076 Motion definitions

Original `def_motion.xml`:

- 877 Unit definitions
- 3519 Motion definitions

Therefore animation coverage is only about 30%; do not claim full migration.

Important completed work:

- compact BILE geometry parity = 1076 / 1076
- historical 18 Machine Gun Finish mismatches are corrected
- production battle Canvas can render compact BILE directly
- expanded 1076 `runtime_sheet.png` cache files are NOT required by production or tests
- lean test path validates compact BILE fallback instead of requiring the 600+ MiB expanded cache
- Motion `speed` is now applied with the native rule `deltaTime * speed`; e.g. speed 2.5 genuinely accelerates frame progression
- real iPhone visual/timing verification remains pending for the later Codex/IPA stage

## Map

Completed:

- original Europe 4992x3582
- original America 3456x4014
- original map grid / terrain / anchor work
- original `maptext` assets integrated
- 102 Europe + 41 America maptext placements wired as a world-space layer

Still not safe to call 100% original: exact native zoom-visibility controller details may still exist outside the already reconstructed data path.

## Audio / music completed

Original audio inventory restored from APK:

- battle1.mp3
- battle2.mp3
- battle3.mp3
- battle4.mp3
- defeat_music.mp3
- all 38 original WAV SFX

Native battle music behavior restored:

- a new battle picks `battle1..battle4` with the native `rand()%4 + 1` behavior
- selected battle track loops
- defeat stops battle music and uses `defeat_music.mp3`
- victory uses `sfx_celebrate.wav`; APK has no victory_music.mp3

Original option audio state restored:

- BGVol default 50
- SEVol default 50
- original-style two-slider `form_option` path is wired

Timed combat SFX:

- all 143 `def_effectsanim.xml` audio timelines are structured and used
- old generic "attack -> immediate guessed SFX" behavior was removed
- movement SFX mapping restored: leg / cavalry / armour / naval
- recruit / occupy / build / upgrade and multiple UI form SFX paths restored from original evidence

## Player-only locked modifications

These are intentional backend rule overrides, while AI/raw original data stays unchanged where applicable.

### Global player units

- attack minimum +4
- attack maximum +4
- base HP +120
- movement/action points +2
- forts remain immobile
- AI does not get these bonuses

Old +40 saves migrate by adding only the missing +80 and preserve absolute damage.

### Campaign / conquest

- campaign/conquest hard forced turn termination is removed
- original BTL turn metadata may remain for rating/metadata but must not force defeat
- general deployment hard count cap is removed: all eligible existing player units may receive distinct owned generals; do not create extra units or duplicate a historical general

### Rank / nobility

- player rank max 14
- player nobility max 9
- ordinary player general max-rank HP cap +500
- ordinary max-nobility heal +25/round
- Napoleon special +1000 HP / +100 heal

### Seven player general overrides

IDs 1,2,5,10,11,26,30 = Napoleon, Davout, Lannes, Massena, Suchet, Soult, Murat.

Use `player_general_overrides.json` as the exact truth source. Do not modify AI same-name commander raw data.

### Princess system

All eight original princesses 201–208 are directly owned/available for the player from the start.

Only these three have player-side stat/skill overrides:

- Lan 208
- Victoria 205
- Isabela 204

Use `player_princess_overrides.json` as the exact truth source. The other five remain original in stats/skills.

Original princess/deployment flow is now substantially reconstructed:

- `form_deploygeneral` original princess button is active
- it opens original-sized `form_princess`
- eight princess order follows original data
- no duplicate deployment of the same princess
- player general hard-slot gate is removed as requested
- deployment still returns through the general deployment confirmation flow

## Effective-value UI rule

Locked principle:

**If original UI normally displays a value, show the player's effective modified value. If original UI does not explain a cheat/mod source, do not add MOD/free/infinity explanations.**

Current effective chains cover unit HP, attack interval, movement, general/princess effective stats/skills, recruit values, etc.

Do not add a "强化" badge or special color solely to advertise added skills.

## Military Academy / SceneGetGeneral

Original-style `form_getgeneral` is retained.

Native candidate generation was reverse-engineered and replaced the old ID-range approximation:

- 6-person tier: commander stars 1–3
- 4-person tier: stars 4–6
- 2-person tier: stars 7–9
- `drawlots=0` excluded
- already-owned commanders excluded
- all currently staged candidates are globally de-duplicated
- switching tier does not refresh it
- refreshing one tier leaves the other two unchanged
- the tier being refreshed also excludes its currently displayed old candidates from the same immediate redraw
- buying a commander clears that slot to an empty `-1/null`; no automatic replacement until the user refreshes
- empty slots persist through save/load

Native purchase semantics reconstructed:

- green = medal
- red = badge
- medal price from commander `price`
- badge by star: 1–3: 0, 4:3, 5:3, 6:4, 7:6, 8:8
- success opens original `form_getgeneraltips` 152x184 and plays `sfx_lvup2.wav`
- `effect_getgeneral_hd.xml` is structurally extracted but its full native particle rendering is not yet completed

**Authorized mod:** Military Academy refresh is unlimited/zero-cost, backend only; do not display FREE/∞ in original UI.

### Critical scope discrepancy to clean up

The current `app.js` still contains legacy `MODS.medals=Infinity` / `MODS.badges=Infinity` and related tavern comments from an older scope. The latest locked user scope does **not** authorize global infinite medals/shields; only Academy refresh infinity is explicitly preserved. Do not treat those legacy constants/comments as approved. Clean them up in a small audited patch before final Codex/IPA handoff, without changing original price displays.

## Training system — reconstructed and wired

This is the commander's eighth stat `training`; it is not rank HP.

Original troop training level is 0–5 and BTL `raw[20]` is preserved for original starting veteran units.

Training stat controls the maximum troop training level the commander can manually train to:

- commander training 1 -> troop max manual level 1
- ...
- training 5 -> troop max manual level 5

Manual training costs by current troop level:

- 0->1: 30 money
- 1->2: 45
- 2->3: 70
- 3->4: 105
- 4->5: 160
- food = current unit consumption * 3
- industry = 0

On successful manual/automatic level up:

- level +1
- current HP recovery = +10/+20/+30/+40/+50 according to new level
- max HP is unchanged
- accumulated training EXP is preserved correctly; manual training does not zero it

Training table also supplies:

- fixed defense reduction: 0/2/4/6/8/10
- per-round recovery: 0/2/3/4/5/6
- base next-level EXP parameters: 0/100/150/220/300/400

Automatic combat training EXP:

- EXP is based on damage dealt
- retaliation damage awards EXP to the retaliator
- rocket splash damage contributes when the native rocket splash path exists
- commander threshold multiplier = 1.5
- navy type threshold multiplier = 2
- one settlement upgrades at most one level and keeps excess EXP
- EXP settlement is placed after both ordinary attack and retaliation damage to avoid healing before retaliation

Original-style resource confirmation (`group_funcres`) is used for training: money + food.

## Construction / facility system — reconstructed

Original per-level outputs are now data-driven through `native_construction_core.js`.

### City

1: money3, supply1, ALL3
2: money6, supply2, ALL6
3: money12, supply4, ALL9
4: money20, industry2, supply6, ALL12
5: money30, industry4, supply8, ALL15
6: money45, industry6, supply10, ALL18
7: money60, industry8, supply12, ALL20

### Factory

1: industry4, supply2, ALL3
2: industry8, supply4, ALL6
3: industry12, supply6, ALL9
4: industry16, supply8, ALL12

### Stable

1: money2, supply2, ALL3
2: money4, supply4, ALL6
3: money6, supply6, ALL9

### Port

1: money3, industry1, supply2, ALL3
2: money6, industry2, supply4, ALL6
3: money9, industry3, supply6, ALL9

### Farm

1: food5, ALL0
2: food15, ALL0
3: food40, ALL0

`ALL` has been proven to be the construction's universal defense/avoid percentage, not an economy stat.

Important native defense selection rule now implemented:

- if a construction exists on the tile, use the construction's own `avoid/ALL`
- otherwise use max(terrain defense, field-fortification defense)
- do NOT add construction ALL on top of terrain/field fortification
- this means a farm with ALL0 still takes the construction branch instead of inheriting underlying terrain defense through that path

Original construction info UI uses dynamic slots chosen from money / industry / food / ALL / infantry defense / cavalry defense / artillery defense rather than a hardcoded four-label Web panel.

### Construction upgrade costs

Fixed by construction type; they do not scale with current level:

- city: money65 / industry0
- factory: 60 / 20
- stable: 80 / 5
- port: 75 / 10
- farm: 40 / 0

Architecture discount is native `*3/5` (60%) with integer truncation.

Upgrade now opens reusable original-style `group_funcres` first. Construction upgrade shows money+industry; insufficient resource values are visible and OK becomes the original gray-disabled button.

## Particle/effect runtime — current state

A native-oriented simple particle runtime now exists and is tested.

Proven/implemented pieces include:

- `area` emitter sampling
- x/y path interpolation shares one random path parameter; width/height jitter use separate random values
- quantity is emission rate, not "spawn N at once"
- lifetrack values are linearly interpolated
- `once` emitters stop emitting after emitter life; already-born particles finish their own life
- `cont` emitters continue until controller stops them
- per-particle motion integration order includes position update before gravity update as verified in native
- native RGB tint for supported effects
- additive blend for supported water effect path

### effect_build

- real original `eff.png` atlas
- original build marker particle data
- wired to successful construction upgrade
- Canvas pixel smoke PASS

### effect_recover

- real original data and RGB multiplier
- Canvas pixel smoke PASS
- **do not attach to building per-round supply recovery**
- native evidence shows it belongs to item function=8: Medikit / Medikit L / First Aid Box, with `sfx_supply.wav`

### movement effects

Original mapping is wired:

- infantry -> effect_moving1
- cavalry -> effect_moving2
- artillery -> effect_moving3
- sea/naval/transport movement -> effect_moving4

These emit along the unit's actual movement path; after movement, emission stops and existing dust/water particles finish naturally. Canvas smoke + integration tests PASS.

Still unresolved: exact native z-order relative to unit model/flags/UI is not yet fully proven.

## Best next work for next conversation

Do not start IPA yet unless the user explicitly says it is Sunday/Codex handoff time.

Recommended next micro-batches:

1. **Combat visual effect timeline**
   - connect original visual effects to the already-reconstructed 143 effect/audio cue timelines
   - start with machine-gun muzzle flash, then artillery gunnery/smoke, rocket, naval/torpedo
   - preserve audio/visual cue timing; do not invent a generic muzzle effect

2. **Particle fidelity**
   - finish exact native z-order
   - expand generic emitter support only as native evidence is proven
   - wire `effect_getgeneral_hd` once its emitter semantics are verified

3. **Scope cleanup**
   - remove legacy global infinite medals/badges code/comments; retain only explicitly authorized Academy unlimited/zero-cost refresh and general count-cap removal

4. **Remaining controller fidelity**
   - training button appearance/resource UI exact native details
   - rank/nobility original `form_generalinfo` presentation where current Web still explains more than original
   - any remaining princess/controller nuances

5. **Continue animation coverage only after higher-impact original fidelity work**
   - current 265/1076 subset is not the full 877/3519 original set
   - no cross-country animation substitution

6. **Real-device verification at Codex/IPA stage**
   - compact BILE visuals/timing
   - touch hit-testing/zoom/pan
   - particle z-order and effects
   - audio timing and iOS autoplay/session behavior

## Do not redo

Do not redo compact BILE parity, maptext integration, Music1-4 selection, audio inventory, Academy candidate algorithm, training mechanics, construction outputs/ALL formula, player +120/+4/+4/+2, princess data layer/deployment baseline, or movement particles unless a regression test/evidence shows an actual defect.

