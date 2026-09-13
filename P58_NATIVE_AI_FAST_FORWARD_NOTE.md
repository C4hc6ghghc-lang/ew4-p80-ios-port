# P58 — Native AI fast-forward closure

Baseline: uploaded P57 clean audited checkpoint.

P58 is intentionally a narrow presentation/control-layer change. It does **not** add gameplay or alter the AI simulation. The Native battle scene now mirrors the mature Web contract where the round button can be pressed during AI to accelerate enemy presentation.

Key caps recovered from the mature mainline: movement <= 80 ms, attack impact <= 90 ms, inter-step AI delay 10 ms while fast-forward is active. Pair-focus is bypassed in fast-forward so presentation speed does not change decisions, action count or RNG.

Regression protection added:
- core tests for 90 ms attack-impact compression and short-impact preservation;
- a source-contract test proving the SpriteKit battle scene keeps the same incremental AI driver while wiring the fast-forward flag, camera bypass and fast presentation paths.

P57 parse-count correction: after deleting build/cache material, the uploaded archive contains 162 actual Swift source files, not 164. P58 reports and verifies the concrete packaged count: 162/162 parse PASS.
