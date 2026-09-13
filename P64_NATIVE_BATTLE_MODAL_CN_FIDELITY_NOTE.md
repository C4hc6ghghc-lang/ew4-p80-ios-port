# P64 Native Battle Modal CN Fidelity Note

P64 is a narrow Release-visible original-Chinese-string authority pass for the battle modal family. It does not add gameplay and does not reopen frozen map/LOD/unit/HUD/camera/AI presentation systems.

## Proven original authority
`Resources/Data/original_layout-568h.xml` binds:
- `form_pause` -> `title_pause`, `text_round_word`, `btn_save`, `btn_option`, `btn_restart`, `btn_exit`.
- `form_roundturn` -> `title_roundturn`, `text_economy`, `text_round`, `text_foodsuply`.
- `form_save` -> `title_savegame`, `text_autosave`; load mode uses frozen `title_loadgame`.

`Resources/Data/strings_cn.json` freezes the corresponding CN values, including `text_foodsuply = 食物补给` and pause actions `保存 / 设定 / 重新开始 / 退出`.

## Landed
- `NativeOriginalBattleModalRenderer` now loads `strings_cn.json` from `NativeResourceStore` and consumes the original keys for pause, round-turn and save/load surfaces.
- Removed renderer-local near-match wording from those proven fields, including the incorrect round-turn header `军　粮` and spaced pause labels such as `存　档 / 设　定 / 退　出`.
- Empty save-slot label now consumes `text_empty`.
- The unproven custom `本回合无参战将领` placeholder is intentionally left untouched because it has no direct frozen string key; P64 does not mass-edit uncertain copy.
- Added `P64BattleModalStringFidelityTests.swift` with frozen-value, XML-binding and renderer-consumption contracts.

## Verification
- Native: **243/243 PASS** = 234 Swift Testing + 9 XCTest.
- Mature JS: **126/126 PASS**.
- NativeCore source+test Swift parse: **169/169 PASS**; entire project Swift tree: **171/171 PASS**.
- SOURCE_LEAN: **6321/6321 unchanged**.
- Native Resources: **1751/1751 byte-provenanced**.
- Runtime resource audit: `errors=[]`; 101 battles; 7407/7407 unit visuals; 5482/5482 eligible building sprites; 877 animation units / 3519 motions; BILE 12/12.
- IPA preflight: **26/26 PASS**; scope guard PASS; script syntax PASS.

## P63 -> P64 product scope
- Product Swift: **0 added / 1 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.
