# HANDOFF — R14-39 POSTHANDOFF26 native form_selcountry + form_save Frozen

Date: 2026-09-10
Parent: P25 Campaign Session + native CampaignInfo Frozen
Status: FROZEN / trusted checkpoint

## Completed in P26

1. Restored Campaign two-country branch selection to original 234x150 `form_selcountry` instead of reusing the Conquest full-screen picker. Left/right 85x67 cards, selection overlay, original nation flags/decorations, bottom line/flower, close/OK path and default-left selection are implemented from `layout-568h.xml`.
2. Preserved the existing native branch resolver and verified both real branch pairs: Pru/Aus `campaign3_08 <-> 08b` and Tur/Rus `campaign4_10 <-> 10b`.
3. Restored `form_save` inner presentation from the original 352x235 XML while leaving BattleSave schema 6 and all read/write semantics untouched. The 1 autosave + 6 manual groups use original coordinates; Web-only slot-number/round metadata was removed in favor of battle title + date/time + player nation flag.
4. Added missing native UI assets to Service Worker CORE and bumped cache generation to P26.
5. Fresh single-player census found the next concrete non-device functional omission: the main-menu Achievements button exists visually but has no runtime handler; original `form_achivement` remains to be reconstructed.

## Verification

- Independent Node `test_*.js`: 106/106 PASS.
- Service Worker CORE referenced files: 305/305 present.
- P25 six-zone long-session persistence regression: PASS (73 first clears + 73 worse replays; 292 BattleSave save/load cycles; 500 Campaign-meta reloads; 6/6 one-shot zone rewards).
- P21 protected files remain byte-identical to P25 parent:
  - `native_upgrade_core.js`
  - `battle_save_core.js`
  - `assets/data/native_warzone_tech.json`
  - `assets/data/def_warzonetech.xml`
- `node --check app.js`: PASS.
- `node --check sw.js`: PASS.

## Do not overclaim

- This is not a real iPhone playthrough.
- HD asset-to-logical scaling and font metrics for SelCountry/Save still need true-device visual comparison.
- Do not reopen P21-P25 frozen systems without a reproducible regression or stronger original evidence.

## Recommended next

1. Reverse-engineer and restore the main-menu `form_achivement` flow; the button is currently inert, so this is now a real functional gap rather than cosmetic residue.
2. Continue residual single-player controller census, but treat missing literal form names cautiously because several controllers are already implemented under Web IDs.
3. True-device iPhone calibration: Dock `transportship1/2`, particle z-order, CampaignInfo offset, font/marker alignment and touch/pinch feel.
