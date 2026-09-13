# Apply EW4 r14-39 Post-Handoff 7

Required base: cumulative Post-Handoff 6 tree.

This delta attaches the proven native camera safe-visibility + pair-midpoint focus/wait presentation to **player** move and attack actions. AI presentation is deliberately not changed in this patch.

Service Worker cache target: `ew4-port-v061-r14-39-posthandoff7-playeractionfocus`.

Run every `test_*.js` after overlay; expected result: **67/67 PASS** on this checkpoint.
