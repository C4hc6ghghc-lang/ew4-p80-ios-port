# R14-39 Post-Handoff 26 — native Campaign country selector + native save presentation audit

Date: 2026-09-10
Parent: P25 Campaign Session + native CampaignInfo Frozen

## Native `form_selcountry` restored

Original `layout-568h.xml` evidence:

- user window: **234x150**
- left country card: x=17, y=36, 85x67
- right country card: x=132, y=36, 85x67
- selection group defaults to the left card at x=17/y=36
- per-card original structure: `common_lineframe_bold.png`, mirrored `pattern_save.png`, nation flag, `general_nameboard.png`, nation text
- selected overlay: `item_selected_ex.png` + `button_lottery_generals.png`
- bottom line y=119 / h=2; bottom flower y=125
- native form declares both close and OK buttons

Production flow now remains inside `form_compaignlist` instead of reusing the Conquest full-screen country picker:

`battle confirm -> form_selcountry -> left/right card -> confirm -> resolveVariant -> StageIntro -> battle`

The original default-left selection behavior is preserved. The two real Campaign branch pairs are regression-tested end-to-end at the data/controller level:

- `campaign3_08.btl` (Prussia) <-> `campaign3_08b.btl` (Austria)
- `campaign4_10.btl` (Ottoman) <-> `campaign4_10b.btl` (Russia)

The existing `EW4NativeCampaign.resolveVariant()` remains the source of truth; no duplicate branch table was invented.

## Native `form_save` inner presentation restored

Existing BattleSave schema-6 serialization/load behavior was deliberately left untouched. Only the native controller presentation was corrected from original XML evidence.

Original geometry reproduced:

- window 352x235
- autosave decoration group x=119/y=31/w=114/h=201
- autosave slot group x=119/y=88/w=114/h=87
- manual groups:
  - slot 1 x=4/y=31
  - slot 2 x=4/y=98
  - slot 3 x=4/y=165
  - slot 4 x=235/y=31
  - slot 5 x=235/y=98
  - slot 6 x=235/y=165
- each manual group 114x67
- original title board `general_nameboard.png`
- original gray autosave framing `save_grayboard.png`
- original 30x30 `button_ok_gray_noshadow.png`

The Web-only visible hierarchy `存档 1/2/...` + `battle title · round` was removed. Slots now present the native-shaped hierarchy:

- save/battle title in the title board
- date/time in `text_date` position
- player nation flag in `image_flag` position
- center `text_autosave` label outside the autosave slot

No BattleSave payload field, schema, read/write key, campaign-tech snapshot or load semantics were changed.

## Offline cache

P26 cache adds the original assets that these forms now depend on but which were not previously guaranteed in CORE, including:

- `common_lineframe_bold.png`
- `button_lottery_generals.png`
- `save_grayboard.png`
- `button_ok_gray_noshadow.png`
- `common_boldline.png`
- the four flags required by the two Campaign branch selectors (`pru/aus/tur/rus`)

CORE presence is 305/305.

## Regression / fidelity boundary

- full source test files: 106/106 PASS
- P25 six-zone persistence stress remains PASS: 73 first clears + 73 worse replays; 292 BattleSave cycles; 500 Campaign-meta reloads; 6 one-shot zone rewards
- P21 protected Campaign Upgrade / save files remain byte-identical

Remaining visual fidelity still needs true-device comparison for font metrics and HD-to-logical asset sizing. The controller geometry and source assets are native-backed; do not call exact iPhone pixel parity until a real device is compared.

## New residual census result

After P26, the two high-value residuals explicitly named by P25 (`form_selcountry`, `form_save`) are closed at the code/controller level.

A new functional omission surfaced during the fresh census: the main-menu **Achievements** button (`btn_achi`) is visually present but has no runtime handler, while original `form_achivement` is a substantial single-player form. This is now the highest-value known non-device single-player gap. Do not confuse literal-name absences with missing implementations: Pause, Talk and VictoryText are already implemented under Web IDs.
