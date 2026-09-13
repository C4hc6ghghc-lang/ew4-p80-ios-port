# P69 Native Main Regroup Parity Note

P69 closes the proven main `form_regroup` synthetic-layout gap left after P68. The Native regroup screen now consumes the recovered original XML geometry for its source/target commander widgets, preview group, equipment group, red regroup action, reorganization arrow, notice/separator rows and 550x98 commander list. Regroup gameplay semantics are unchanged.

Landed:
- source commander: original 78x98 `tmp_commander` at `(160,37)`
- target commander: original 78x98 `tmp_commander` at `(331,37)`
- original `arrow_reoganizion.png` centered at y=48
- original 146x120 preview group at `(8,37)` with original title/frame, rank/nobility preview, HP/recovery markers and teaching-bonus grid
- original 146x120 equipment group at `(415,37)` with original title/frame/pattern/split assets and two 45x45 slots
- selected source's real `equipmentPair` is shown in the equipment group so the player can see equipment at risk before confirmation
- original red 83x35 regroup action at `(243,100)`
- original 550x98 horizontal general list at `(24,190)`, restored to 78px commander-item width and 10px interval
- original notice/separator/bottom decoration geometry restored

Evidence: frozen `original_layout-568h.xml`, mature `regroupPreview()`/`equipmentPair()` semantics, frozen UI assets, existing 78x98 commander presentation evidence. Exact original-controller ownership of the main-form `group_items` binding is not directly recovered; P69 binds it to the currently selected source commander because that is the destructive equipment set relevant to regroup confirmation. This binding should be validated on original-controller evidence if later recovered.

Verification: Native 259/259 = 250 Swift Testing + 9 XCTest; mature JS 126/126; NativeCore Sources+Tests parse 175/175; entire Native Swift tree 177/177; SOURCE_LEAN 6321/6321 unchanged; Native Resources 1751/1751 provenanced; runtime resource audit errors=[]; IPA preflight 26/26; scope guard PASS.
