# Apply EW4 r14-39 Post-Handoff 8

Required base: cumulative Post-Handoff 7 tree.

This delta adds native-style AI move/attack camera focus/wait with fast-forward presentation bypass, and corrects movement-path equal-cost tie-break ordering to the native CEntityMap direction order:

`East -> South-East -> South-West -> West -> North-West -> North-East`.

Service Worker cache target: `ew4-port-v061-r14-39-posthandoff8-aiactionfocus`.

After overlay, run every `test_*.js`; expected checkpoint: **69/69 PASS**.

Additional fixed checks:
- compact BILE: **1076/1076 PASS**;
- Machine Gun Finish corrected set: **18/18 PASS**.
