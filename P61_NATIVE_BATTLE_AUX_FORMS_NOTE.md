# P61 Native Battle Auxiliary Forms Audit

P61 is a narrow original-form behavior/presentation cleanup on top of P60. It does not add gameplay rules and does not reopen frozen map, camera/LOD, unit, flag, HP/HUD or AI systems.

## form_useitem
- Recovered `form_useitem` geometry from frozen `original_layout-568h.xml`: 280x175 form, 269x45 list, 45x45 item cells, 9px interval, 275x84 description group with 269x63 text body.
- Visual cells and touch hitboxes now consume the same `NativeOriginalFormGeometryCore.UseItem` truth.
- Removed the Native placeholder that drew raw item IDs (`11`...`15`) on the five battle consumables.
- Cards now use byte-provenanced original Resources/Items artwork: `Wine.png`, `Spirit.png`, `Medikit.png`, `Medikit_L.png`, `First_Aid_Box.png`.
- Selection still uses original `item_selected_ex.png`; title/name/description use frozen Chinese string keys.
- Item effects, ownership, non-consuming player override, selection/confirm semantics and saves are unchanged.

## form_defense
- Recovered `form_defense` geometry from frozen XML: 300x184 form, 298x65 list, 72px item width, 3px interval, 296x84 description group with 292x63 text body.
- Renderer visuals and hitboxes now consume `NativeOriginalFormGeometryCore.Defense` instead of independently recomputing row positions.
- Defense choices, costs, construction semantics and combat behavior are unchanged.
- P61 intentionally does **not** claim full original defense-card artwork parity. The current Native card art references do not have a sufficiently proven one-to-one resource mapping in the frozen Native resource layer, so P61 keeps existing text/cost presentation rather than inventing assets.

## Regression locks
- Added `NativeOriginalBattleAuxFormTests.swift` covering recovered XML geometry, five consumable artwork paths and the no-raw-ID-placeholder contract.
- Native: 224 Swift Testing + 9 XCTest = 233/233 PASS.
- Mature SOURCE_LEAN JS: 126/126 PASS.
- NativeCore source+test parse: 166/166 PASS; all project Swift additionally parsed 168/168 before packaging.
