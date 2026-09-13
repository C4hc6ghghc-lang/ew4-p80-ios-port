# P45 Native Live Round Settlement

Mainline: P39 -> P40 -> P41 -> P42 -> P43 -> P44 -> P45.

This checkpoint does not rewrite Campaign/Conquest/map/presentation truth. It wires the already-migrated P42 settlement formulas into the live P44 incremental AI/SpriteKit battle lifecycle.

Landed:
- AI country economy is committed at each authored country-end boundary.
- Added `roundReadyToSettle` barrier; previous-round `attacked` survives until tent/nobility/flag recovery is computed.
- Player economy, upkeep, training heal, facility supply, nobility/flag/tent recovery now mutate the live native battle and persistence ledger.
- All surviving units reset after settlement; fortress construction advances after that reset, matching P39 ordering.
- Scene emits round settlement and autosave-payload callbacks after the completed transition.
- Commander/equipment/nobility effects enter through an explicit projection provider; raw commander data is not silently treated as the user's upgraded profile.

Verification:
- Native Swift: 76/76 PASS.
- Mature SOURCE_LEAN JS: 126/126 PASS.
- Native resource audit: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units, 3519 motions, BILE 12/12, errors=[]
- iOS Swift syntax parse: PASS.
- Native IPA preflight: 26/26 PASS.
- SOURCE_LEAN vs P44: 6321 files, changed=0, missing=0.

Frozen visual baseline remains untouched. No Xcode/iPhoneOS build or true-device acceptance is claimed in this Linux environment.
