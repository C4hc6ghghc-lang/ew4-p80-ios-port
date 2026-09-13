# EW4 Web Port r14-39 — effective value -> UI audit

User rule: where original EW4 displays a numeric/stat value, the port must show the player's effective modified value naturally. It must not explain the hidden modification.

## Verified current paths

### Battle unit info
`showUnitCard()` reads:
- `u.hp / u.max_hp` after the +120 base-HP layer and any commander-rank HP layer
- `attackInterval(u)` for the real repaired/randomized attack interval including player +4/+4 and skill/equipment modifiers
- `effectiveMovePoints(u)` including player +2 and commander/skill/equipment movement

Therefore a modified player unit does not display stale APK base values in this panel.

### Recruitment form
The original-style recruit statistics use:
- `EW4PlayerUnitRules.effectiveBaseHp(..., true)`
- `EW4Combat.effectiveAttackInterval(..., isPlayer:true)`
- `EW4PlayerUnitRules.effectiveMovement(..., true)`

A base Line Infantry 1 record with original HP 80 / attack 1–7 / move 6 therefore presents player-effective HP 200 / attack 5–11 / move 8 before commander assignment.

### Commander information
HQ player detail resolves `effectiveCommander(c,true)`; in-battle general information resolves `effectiveCommanderForUnit(u)`. Thus the seven selected generals and the three selected princess overrides expose their actual effective stats/skills rather than raw APK values.

### General HP assignment
`general_deployment_core.js` changes `max_hp` using the effective rank HP bonus while preserving absolute damage. Since the unit panel reads live `hp/max_hp`, the assigned general's HP contribution appears automatically in unit information.

## Still not claimed as native-perfect UI

The data flow is correct, but exact `form_generalinfo` visual/controller fidelity is not yet complete. Some current Web presentation text for rank/nobility is still a reconstruction. Do not equate “effective values are correct” with “every pixel/controller branch of the original form is already restored.”
