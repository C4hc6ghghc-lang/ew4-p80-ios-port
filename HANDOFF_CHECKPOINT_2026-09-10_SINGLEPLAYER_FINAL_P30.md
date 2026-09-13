# P30 SINGLEPLAYER FINAL — 2026-09-10

Parent: P29 Native Conquest Achievement Frozen.

This checkpoint closes the local single-player census and is intended to be the final code/data baseline before optional iPhone visual/touch calibration.

Critical correction over P29: fast Conquest does not automatically overwrite the normal continent record with Asia. Native caller proof shows `form_complete(group_challenge)` first; `btn_chal_asia` calls the Asia override path before the max-only write, while the Europe/America button writes the pending normal result directly. P30 restores this choice and the subsequent `group_conquest` completion page.

Also added/finalized in P30: exact conquest extinction core, native country failure modal, loading gate, all-country extinction matrix and final original UI/audio/MOD reconciliation.

Final pre-freeze contract: 115/115 PASS, SW CORE 340/340, audio 43/43 APK-byte-identical, animation 877/877 & 3519/3519, compact BILE 1076/1076, six-zone long session PASS, all-country conquest matrix PASS, P21 protected cores MATCH.

External IAP/ads/multiplayer/platform/website/email services are explicitly excluded and must not be faked.
