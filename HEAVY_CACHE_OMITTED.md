# Heavy expanded animation cache intentionally omitted

The takeover package omits every `assets/unit_anim_native/assets/**/runtime_sheet.png` from the current r14-39 development tree.

Reason: these files are pre-expanded development sprite sheets and total hundreds of MiB. Keeping them in the takeover archive would violate the user's 450 MB final-build ceiling and would encourage the wrong production architecture.

What is still included:

- every non-PNG per-motion manifest under `assets/unit_anim_native/assets/`;
- `assets/data/native_animation_core265.json` and older core metadata;
- `assets/bile_runtime/` containing original BILE source data;
- `compact_bile_runtime.js` and its tests;
- the authoritative original APK;
- `OMITTED_RUNTIME_PNG_SHA256.txt`, containing path + SHA256 for all omitted 1076 sheets;
- corrected Machine Gun Finish candidate sheets in `REFERENCE/machinegun_finish_fix/`.

The full tree passed 26/26 tests before these cache PNGs were removed for transport. Use `TEST_RESULTS_FULL_TREE_26_OF_26_PASS.txt` as the pre-strip regression record.

Production direction: render/compose from compact BILE source at runtime or via a much more compact production representation. Do not restore all expanded sheets into the final Codex build unless temporarily required for comparison/debugging.
