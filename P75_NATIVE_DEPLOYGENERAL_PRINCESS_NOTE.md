# P75 Native DeployGeneral + Princess Battle Flow

P75 closes a major battle-context gap in the original `SceneDeployGeneral` / `form_deploygeneral` flow.

## Landed
- Battle general deployment now consumes the recovered original `form_deploygeneral` structure: top Princess / Shop / Military Academy controls, `generalnumber.png`, 508x204 six-column general grid, original separators/bottom decoration, and lower-right deploy confirmation.
- The battle grid excludes princesses and uses the original 8-princess child flow instead of silently filtering princesses out of deployment entirely.
- `form_princess` is restored in battle context with original 468x300 geometry, original princess order `[202,204,201,203,205,206,207,208]`, two rows, and eight `btn_gobattle` controls.
- All eight user-unlocked princesses can be selected when not already deployed on another player unit. Already-deployed princesses remain unavailable.
- General-grid overflow uses the recovered six-column scrolling geometry instead of the previous custom 18-card page controls.
- Military Academy can be opened from battle deployment and returns to the exact same live `NativeBattleScene`; newly acquired generals refresh back into the open deployment list.
- Battle-context Shop remains visually present but disabled, matching the mature P39/Web battle-context adaptation rather than substituting the facility shop.

## Preserved
- `NativeGeneralDeploymentCore.assign` remains authoritative for duplicate clearing and HP-bonus preservation.
- Unlimited player general capacity remains in force.
- All eight princesses remain owned/unlocked from the start; only Lan/Victoria/Isabela keep the approved player-side overrides.
- No battle formula, map, camera, AI, HUD, save schema, resource or Native asset changes.

## Evidence boundary
The original native callback proves Princess / College / Shop entry points. The mature P39/Web battle context intentionally disables Shop while preserving Princess and College, and P75 follows that proven adaptation. Exact original internal commander-card ornament packing remains less certain than the outer XML geometry.
