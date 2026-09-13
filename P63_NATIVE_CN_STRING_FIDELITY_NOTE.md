# P63 Native CN String Fidelity

P63 is an evidence-led release-visible copy cleanup on top of P62. It does not attempt to force every Native runtime literal into the original string table.

## Why the historical 111 candidates were not bulk-edited
The P57-era full-scope audit recorded 111 Native Chinese/runtime string candidates not trivially found in original CN strings/XML. That list mixes materially different classes: Release-visible labels, dynamic interpolated status text, DEBUG-only diagnostics, and approved modified-game behavior. During P63, the iOS app path was checked and `statusHandler` ultimately feeds a `debugMessage` whose visible `Text(...)` and assignment are both guarded by `#if DEBUG`. Therefore strings such as `Native Market`, `Native Shop`, and `Native battle` are not Release UI defects and were intentionally left alone.

## Frozen original keys restored
The following values are read from `Resources/Data/strings_cn.json`, with original form XML / mature behavior used as authority:

- `title_business` = `交易所`
- `title_deploygeneral` = `指挥部`
- `title_unitinfo` = `信  息`
- `text_victory` = `胜利`
- `text_bestvic` = `重大胜利`
- `text_round_word` = `回合`
- `title_shop` = `商  店`
- `name_Seller` = `商人`
- `text_sellersays` = `欢迎光临！`
- `text_buy` = `购买`
- `text_sell` = `卖出`

These keys now drive the corresponding Native stage-intro, exchange, deploy-general, unit-info, battle-shop, and HQ-shop visible labels instead of renderer-local invented/nearby wording.

## Deliberately unchanged
- DEBUG-only `Native ...` status strings.
- Text tied to explicitly approved player modifications.
- Dynamic runtime text with no proven original literal equivalent.
- Custom labels such as inventory/functional state text where no direct original CN/XML authority was proven during this pass.
- All gameplay and resource assets.

## Regression lock
`NativeOriginalStringFidelityTests.swift` verifies exact frozen CN values and requires the affected renderers to consume the original keys. P63 full Native regression is 240/240 PASS and mature JS remains 126/126 PASS.
