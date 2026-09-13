# P66 Native Tutorial / Regroup CN + Geometry Fidelity

P66 is a narrow evidence-led parity pass over `form_tutorials` and `form_regroupconfirm`.

## Tutorial corrections
- `NativeOriginalTutorialScene` no longer looks up nonexistent `tutorials1` / `tutorials2` string keys.
- It now consumes the original XML bindings `btn_basic`, `btn_classic`, and `btn_notice` from frozen `strings_cn.json`.
- Tutorial buttons now use original `btn_common_green.png` rather than the Native-only blue-button approximation.
- Tutorial button and panel rectangles are centralized in `NativeOriginalFormGeometryCore.Tutorial` from `original_layout-568h.xml`.
- Launch routing is unchanged: Basic still launches `tutorials1.btl`; Advanced still launches `tutorials2.btl`.

## Regroup confirmation corrections
- The confirmation form now uses original `title_notice = 注  意`, `text_regroupnotice`, `text_regroup`, `btn_confirm = 确认`, and `btn_cancel = 取消`.
- Original XML order is restored: **confirm on the left, cancel on the right**.
- Visual button rectangles and touch hitboxes share `NativeOriginalFormGeometryCore.RegroupConfirm`, eliminating the P65 reversed-button / stale-hitbox mismatch.
- Original 320x222 form, warning/info rows, gray board, split lines, and 75x30 button positions are recovered from `original_layout-568h.xml`.
- Regroup calculation, source-consumption semantics, equipment deletion semantics, and profile mutation rules are unchanged.

## Deliberately not folded into P66
The original `form_playnotice` contains a scrollable 390x186 `HtmlBox` with the full frozen `html_notice` text. Current Native tutorial notice still renders only the first 11 lines and closes on any touch; therefore tips 12-24 are not reachable. That is a proven behavior/content gap and is the highest-priority isolated follow-up after P66. It was not mixed into this already-verified button/string pass.

No Native resource bytes changed. No SOURCE_LEAN bytes changed.
