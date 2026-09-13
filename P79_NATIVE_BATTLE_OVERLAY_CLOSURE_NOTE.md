# P79 Native Battlefield Overlay Closure

P79 was triggered by re-auditing the **current NativeBattleScene implementation**, not by trusting historical P32/P36 notes. P78 still omitted three mature battlefield presentation layers even though the frozen Web truth layer already rendered them.

## Closed in P79
- original flagpole + animated 4-frame country flag cloth;
- commander battlefield bubble using `board_smallgenerals.png` plus the real commander mini portrait;
- dynamic morale markers: up, down1, down2, down3;
- legacy BTL country aliases `gb -> gbr`, `de -> pru`, `fr -> fra` for the native flag atlas;
- overlays are attached to both normal tactical unit models and P78 transport-ship tactical models;
- flag frames and morale state update dynamically while the scene runs.

## Preserved rendering hierarchy
- flag root behind model;
- unit/transport model;
- relation ring + HP arc + army marker;
- commander board/portrait;
- morale marker.

## Evidence
`P79_MAP_UNIT_DYNAMIC_OVERLAY_AUDIT.json` proves, from the current package:
- 101 battles (84 Europe / 17 America);
- 7407/7407 unit visual resolution across 22 families;
- 12/12 BILE frozen identity;
- P78 transport assets/branch remain valid;
- every raw battle country code resolves to all four flag frames after alias normalization;
- all valid battle commander IDs have a frozen mini portrait;
- flagpole, commander board and all four morale assets are byte-identical to SOURCE_LEAN;
- NativeBattleScene consumes and dynamically updates all three overlay branches;
- audit errors = `[]`.

## Product delta P78 -> P79
- add `NativeBattlefieldOverlayCore.swift`;
- modify `NativeBattleScene.swift`;
- add `P79BattlefieldOverlayParityTests.swift`;
- Native Resources: 0 changes;
- SOURCE_LEAN: 0 changes.

## Acceptance boundary
This closes the **known source/data/renderer gaps** for map/unit/transport/flag/commander/morale presentation. It still does not substitute for real Apple-SDK compilation or iPhone visual acceptance. Texture filtering, final anchor feel, z-order on device, touch/pinch feel and frame appearance remain device-owned evidence.
