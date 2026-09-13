# P50 Native Campaign / Conquest Original Shell

P50 is a UI/coordinator parity checkpoint on top of P49; it does not rewrite Campaign or Conquest rules.

Landed: original-style Native main menu; Campaign zone/stage/branch selection; Conquest scenario/country selection; `form_complete` Campaign/Challenge/Summary rendering; app coordinator start/restart/exit/Continue routing; outer autosave restore; hardcoded Toulon boot removed.

Hard verification: Native 175/175 PASS; mature JS 126/126 PASS; resource audit errors=[] (101 battles, 7407/7407 unit visuals, 5482/5482 buildings, 877 units / 3519 motions, BILE 12/12); 109/109 project Swift files parse; preflight 26/26; SOURCE_LEAN 6321 unchanged; Native Resources unchanged; frozen battle visual-sensitive changes 0.

Not claimed: Xcode/iPhoneOS semantic build or real-device visual/touch acceptance. HQ/tutorial/options remain explicit later Native UI work.
