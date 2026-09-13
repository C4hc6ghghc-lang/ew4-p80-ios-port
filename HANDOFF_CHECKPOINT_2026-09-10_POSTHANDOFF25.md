# HANDOFF — R14-39 POSTHANDOFF25 Campaign Session + CampaignInfo Frozen

Date: 2026-09-10
Parent: P24 Native UnitInfo + Campaign Growth Chain Frozen
Status: FROZEN / trusted checkpoint

## Completed in P25

1. Added `native_campaign_session_core.js` and moved production Campaign meta semantics into it rather than keeping them trapped in DOM/localStorage glue in `app.js`.
2. Added repeated persistence stress using real campaign data: 73 first clears + 73 worse replays, 292 BattleSave schema-6 JSON save/load cycles, 500 Campaign meta reload cycles, and all 6 one-shot zone completion rewards.
3. Restored original `form_campaigninfo` controller shell and data path. `native_campaign_line_core.js` parses the original `def_battleline.xml` 6/6; campaign pins now go pin -> info -> confirm -> battle list instead of skipping the native intermediate controller.
4. Verified the six campaign-pin positions already match `form_selcampaign` XML exactly; do not rebuild that geometry.
5. Added `R14_39_POSTHANDOFF25_CAMPAIGN_SESSION_INFO_AUDIT.md` with residual controller census and fidelity boundary.

## Verification

- Independent Node `test_*.js`: 104/104 PASS.
- Service Worker CORE referenced files: 296/296 present.
- P21 campaign-upgrade guard files remain byte-identical to P24 parent:
  - `native_upgrade_core.js`
  - `battle_save_core.js`
  - `assets/data/native_warzone_tech.json`
  - `assets/data/def_warzonetech.xml`
- `node --check app.js`: PASS.
- `node --check native_campaign_session_core.js`: PASS.
- `node --check native_campaign_line_core.js`: PASS.

## Do not overclaim

- This is not a real iPhone playthrough.
- The six-zone long-session regression is a strong deterministic persistence/runtime integration test, not hours of live touch-driven play.
- `form_campaigninfo` inner geometry/assets/data are native-backed. Exact dynamic popup offset is inferred from the exact pin anchors because the original `.so` positioning routine is not present in this lean package; true-device comparison remains pending.

## Recommended next

1. Restore Campaign two-country branch selection to original 234x150 `form_selcountry` instead of the current generic Web list.
2. Audit/restore `form_save` inner controller presentation; preserve its already-working schema-6 save/load behavior.
3. Continue true-device iPhone calibration, especially Dock `transportship1/2`, particle z-order, touch/pinch, font/marker alignment and CampaignInfo popup offset.
