# P68 Native Regroup Confirm Preview Note

P68 closes the proven `form_regroupconfirm` interior-preview gap left after P66/P67. The source commander and its two real current equipment slots are now rendered inside the original XML regions. No regroup gameplay semantics changed.

Evidence: `original_layout-568h.xml` `form_regroupconfirm`; mature controller `openRegroupConfirm()` source/equipment binding; existing 78x98 commander presentation CSS; frozen Native Items/Portraits resources.

Verification: Native 256/256, mature JS 126/126, NativeCore parse 174/174, full Native Swift parse 176/176, SOURCE_LEAN 6321/6321 unchanged, Native Resources 1751/1751 provenanced, runtime resource audit errors=[], IPA preflight 26/26, equipment artwork 48/48.
