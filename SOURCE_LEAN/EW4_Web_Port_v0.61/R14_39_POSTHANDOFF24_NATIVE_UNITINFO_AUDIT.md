# R14-39 POSTHANDOFF24 — Native `form_unitinfo` controller audit

Date: 2026-09-10
Parent: POSTHANDOFF23 Native Defense + Pause Frozen

## Why this pass exists

The P23 Web `form_unitinfo` matched the original 330x187 shell geometry, but its controller semantics were still partly invented: it used battle READY artwork, printed a Web-only unit-name label in the upper-left group, showed custom morale/training/defense cells, and reused the lower `group_desc` as an equipment list.

## Original evidence

`assets/data/original_layout-568h.xml` defines:
- `form_unitinfo`: 330x187.
- `group_unit`: 2,30 / 78x78, with `image_unit`, `image_side`, three `image_back_%d` + `image_icon_%d` formation layers, money and industry.
- `group_ability`: 80,33 / 165x72, 4 columns, 24px rows.
- `group_info`: 249,30 / 78x78, `tmp_commander` and `btn_info`.
- `group_desc`: 4,110 / 323x74, `intitle` + `text_desc`.

x86_64 native-controller disassembly for the `form_unitinfo` constructor/update path (function beginning near 0x47960 in the preserved original `libeuropean-war-4.so`) establishes the missing semantics:
- `image_unit` is populated from the original `recruit_*.png` / fort build-art lookup, not from battle READY motion frames.
- `image_back_%d` is populated with `buildmaker.png`; `image_icon_%d` is populated from the unit-family marker lookup, with 1/2/3 formation layers controlled by unit grade.
- `grid_ability` is populated with the original attack, soldier-number, HP, food, range and movement marker resources. The original row/column calls resolve to attack+formation, HP+food, range+move.
- `intitle` is dynamically assigned `name_%s` for the unit type.
- `text_desc` is dynamically assigned `desc_%s` for the unit type.

The XML's default `text_equipitem` on `intitle` is therefore only a layout default; treating `group_desc` as an equipment-list controller was incorrect.

## Implemented

- Restored original family-specific recruit/build art for all 22 unit classes.
- Restored original family-specific formation markers and `buildmaker.png` 1/2/3-grade layering.
- Removed the Web-only upper-left unit-name label.
- Rebuilt the 3x4 ability area as the proven native structure:
  - attack marker / min-max / line marker / formation count;
  - HP marker / current-max / food marker / consumption;
  - range marker / min-max / movement marker / movement.
- Removed custom morale, training-level and training-defense cells from this native form.
- Restored `group_desc` to dynamic native unit name + original `desc_%s` text.
- Removed equipment-list rendering from `form_unitinfo`; equipment remains handled by the dedicated deploy/item/general paths.
- Added all newly runtime-referenced UnitInfo assets to the Service Worker CORE list.
- Cache bumped to `ew4-port-v061-r14-39-posthandoff24-unitinfo`.

## Scope guard

This pass does not change combat rules, campaign tech, Stars, recruitment prices, BattleSave schema, UseItem behavior, general equipment state, or player modifications. It is a native-controller/UI-fidelity correction only.
