# EW4 Web Port 0.61 · Recovered checkpoint

## Recovery status
- Latest working tree recovered successfully after interrupted reasoning run.
- No prior 0.61 runtime changes were lost.
- Current source root: `EW4_Web_Port_v0.61/`.

## Newly confirmed / completed in this continuation
- Cavalry annihilation -> extra action for both player and AI.
- AI can consume repeated cavalry actions in the same phase.
- Light Infantry preserves high mobility through complex land terrain; generic infantry no longer receives this rule.
- Geography / matching equipment remain terrain-ignore paths.
- Trench / fence / bunker construction is infantry-only.
- Construction supply now applies to every faction using original `def_construction.xml` values, once per completed battle round.
- Player-only nobility/flag/tent healing is kept separate so AI does not receive player-only enhancements and facility healing is not double-counted.

## Native construction supply values
- City: 1 / 2 / 4 / 6 / 8 / 10 / 12
- Industry: 2 / 4 / 6 / 8
- Stable: 2 / 4 / 6
- Port: 2 / 4 / 6
- Farmland: 0

## Reinforcement reverse-engineering status
- `unit.raw[4]` is rejected as a simple appearance-round field.
- Copenhagen (`campaign2_06.btl`) has a round-4 reinforcement dialogue but zero units with `raw[4] == 4`.
- Reinforcements remain unresolved; no speculative hiding/spawning has been enabled.
- Current likely avenues: native activation/group logic, relation-state changes, or pre-deployed distant units. These remain hypotheses until verified.

## Regression status
All current `test_*.js` suites pass:
- battle save core
- cavalry + facility supply rules
- combat core
- data integrity
- enhanced generals combat
- native entity triggers
- native fire events
- native morale events
- native triggers
- player overrides
- round dialogues
- stage turn limits
- UI/runtime contract

## Locked user modifications still active
- Medals ∞
- Badges/shields ∞
- Military academy refresh ∞ / zero cost
- Campaign general hard cap removed
- Conquest general hard cap removed
- Player units attack min +2 / max +2
- Lower-bound bug repaired
- Player-only enhanced general layer including Napoleon special +1000 HP / +100 heal and the seven requested enhanced generals

## Continuation checkpoint · multi-country scheduler / national ledgers / reinforcement audit

- The old merged enemy phase has been split into sequential per-country AI action phases.
- Pairwise **conquest** relation checks now govern AI target selection and facility capture; decoded conquest allies no longer fight one another. Campaign relation hints are kept separate because Copenhagen proves their semantics differ.
- Every country now owns an independent money / industry / food ledger. Conquest selection uses that country's BTL country-record economy triplet rather than the old shared battle-header resources.
- Player HUD, recruitment, fieldworks and troopship costs remain wired to the selected player's ledger.
- AI countries settle facility income and food upkeep into their own ledgers after their action segment.
- Battle save schema v2 persists `countryResources`; schema-v1 saves remain compatible.
- Reinforcement safety audit extended: `raw[9]` round-number coincidence eliminated as map-position high byte; reinforcement-worded dialogue is proven not to imply spawning by campaign4_03 event 4035 (verified morale action).
- No guessed reinforcement spawn/activation logic has been introduced.
- Added `COUNTRY_TURN_LEDGER_AUDIT_0.61.md`, `REINFORCEMENT_EVENT_AUDIT_0.61.json`, `test_country_turn_core.js`, and `test_reinforcement_safety.js`.
- All current tests pass.
