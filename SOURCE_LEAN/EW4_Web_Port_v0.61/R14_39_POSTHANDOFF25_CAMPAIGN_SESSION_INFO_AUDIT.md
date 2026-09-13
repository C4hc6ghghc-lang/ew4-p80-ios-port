# R14-39 Post-Handoff 25 — Campaign Session + native CampaignInfo audit

Date: 2026-09-10
Parent: P24 Native UnitInfo + Campaign Growth Chain Frozen

## Production campaign-session core

`native_campaign_session_core.js` is now the production owner of campaign meta persistence semantics used by `app.js`:

- progress level / best rating
- legacy pre-P21 Star migration
- score-delta-only Star awards
- one-shot war-zone completion awards
- normalized campaign meta round-trips

Legacy migration is deliberately one-shot: if a persisted `campaignStars` field exists, even if it is zero, historical ratings are not converted again.

## Long-session integration

The P25 six-zone long-session regression walks all 73 non-hidden campaign stages in the real `battles_runtime.json` order. It performs:

- 73 first clears at native best-turn rating
- 73 deliberately worse replays with no duplicate score Stars
- 292 BattleSave schema-6 JSON save/load lifecycle cycles
- 500 campaign-meta JSON reload cycles
- all 6 zone completion rewards and duplicate-prevention checks
- one live technology upgrade opportunity in each zone
- Battle Tech Snapshot stability through save/load

## Native form_campaigninfo restored

Original `layout-568h.xml` evidence:

- 155x83 form
- background `button_choosebattlezoneinfo.png` at x=-9/y=-4/h=70 with native extend behavior
- arrow `arrow_choosebattlezoneinfo.png` at x=60/y=56
- title 139x19
- age at y=21
- horizontal nation list x=4/y=34/w=150/h=15
- confirm `button_confrim.png` x=110/y=28/w=31/h=32

Original `def_battleline.xml` is parsed at runtime rather than replacing it with invented data. All 6 original rows reproduce:

1. imperialeagle — 1793..1820 — fra
2. coalition — 1792..1815 — aus,pru,rus,gbr
3. romanempire — 1807..1822 — hre,aus,pru
4. eastern — 1798..1820 — tur,rus
5. america — 1775..1822 — usa
6. neversets — 1775..1814 — gbr

Campaign pins now use the native controller path:

`tap zone pin -> form_campaigninfo -> confirm -> form_compaignlist`

The six campaign-pin coordinates in the current UI are independently confirmed to equal `form_selcampaign` XML exactly, so that screen is not a missing geometry rebuild.

## Fidelity boundary

The original `.so` positioning function for the floating `form_campaigninfo` was not preserved in the lean package. The current popup is anchored to the exact original pin coordinates and clamped to the 568x320 viewport; the 155x83 inner layout/assets/data are native-backed, but exact native popup offset still requires stronger `.so` or true-device visual evidence.

## Residual single-player controller census

Do not treat every layout name absent as missing: several controllers are implemented without retaining the literal native form id.

High-value remaining fidelity work:

1. Campaign two-country branch selection: current logic is functional but does not yet use the original 234x150 `form_selcountry` two-card controller.
2. `form_save`: 352x235 shell and 1 autosave + 6 manual slots work, but the visible inner labels/content still include Web-specific presentation; restore only from XML/controller evidence.
3. True-device calibration: Dock `transportship1/2`, particle z-order, font metrics, touch/pinch feel and popup offsets.

Low/non-core priority unless explicitly requested: multiplayer forms, service/ad/rewarded-video forms, debug forms and external-service dialogs.
