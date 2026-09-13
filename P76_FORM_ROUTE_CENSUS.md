# P76 XML Form → Native Route Census

Authoritative input: `original_layout-568h.xml` from frozen SOURCE_LEAN.

- Layout declarations: **58**
- Unique form IDs: **57**
- Duplicate declaration: **`form_servicedialog`**
- Covered/equivalent offline single-player forms: **39**
- Intentionally excluded debug/platform/multiplayer/IAP/ad/service forms: **15**
- Deferred non-blocking forms: **2**
- Restored shell intentionally unbound without trigger evidence: **1**

## Bottom line

**No new high-value offline single-player route break was proven after P75.** The census therefore supports switching from repeated feature/parity construction to Xcode/iPhoneOS acceptance. The one explicit local presentation gap is `form_loading`: Native iOS currently starts from a black placeholder and then enters Main Menu, while the original has a loading/tips screen. This is startup cosmetic/acceptance work, not a gameplay blocker.

`form_messagebox` is a generic shell with no proven mature local trigger in the current evidence. `form_claim` is already restored as a reusable 200×100 component but remains intentionally unbound because no offline evidence proves an Achievement claim route.

## Covered / equivalent offline single-player forms

- `form_mainmenu` — NativeOriginalMainMenuScene; primary offline routes wired.
- `form_selcampaign` — NativeOriginalOuterMenuScene campaign selection.
- `form_selconquest` — NativeOriginalOuterMenuScene conquest selection.
- `form_campaigninfo` — P73 restored pin -> CampaignInfo -> confirm -> campaign list.
- `form_compaignlist` — NativeOriginalOuterMenuScene campaign list.
- `form_conquestlist` — NativeOriginalOuterMenuScene conquest list.
- `form_selcountry` — Native conquest country selection/save flow.
- `form_recruitunit` — P60 original recruit content/layout + resource-backed unit art.
- `form_regroup` — P69 main regroup parity structure.
- `form_getgeneral` — NativeOriginalAcademyScene military-academy acquisition surface.
- `form_getgeneraltips` — Academy acquired-general tip restored in NativeOriginalAcademyScene.
- `form_generalinfo` — Shared NativeOriginalGeneralInfoSurface.
- `form_unitinfo` — NativeOriginalBattleUnitInfoRenderer.
- `form_failure` — NativeOriginalBattleResultRenderer failure surface.
- `form_pause` — NativeOriginalBattleModalRenderer pause flow.
- `form_stageintro` — NativeOriginalStageIntroRenderer.
- `form_exchange` — NativeOriginalMarketRenderer / commerce core.
- `form_shop` — HQ/battle shop flow; selection -> info -> confirmation and scroll parity.
- `form_deployitem` — P70 NativeOriginalDeployItemScene parity pass.
- `form_deploygeneral` — P75 battle deploy-general original flow.
- `form_recruitgeneral` — P74 NativeOriginalTavernRenderer parity pass.
- `form_defense` — P61/P62 defense geometry, hitboxes and original art.
- `form_roundturn` — NativeOriginalBattleModalRenderer round settlement.
- `form_victory` — NativeOriginalBattleResultRenderer victory surface.
- `form_talk` — NativeOriginalTalkRenderer.
- `form_option` — NativeOriginalOptionsScene.
- `form_game` — NativeBattleScene runtime.
- `form_save` — NativeOriginalBattleModalRenderer save/load slots.
- `form_upgrade` — Native campaign technology/upgrade flow (P21 lineage).
- `form_useitem` — P61 original consumable art + unified geometry.
- `form_achivement` — P72 NativeOriginalAchievementScene route + P28 math.
- `form_princess` — P75 8-princess deployment child flow.
- `form_complete` — NativeOriginalOuterCompletionRenderer: campaign complete, conquest summary, Asia challenge.
- `form_tutorials` — NativeOriginalTutorialScene.
- `form_playnotice` — P67 full 24/24 scrollable notice box.
- `form_floattext` — Equivalent battle damage/floating presentation in NativeBattleScene; not a separate routed scene.
- `form_victorytext` — NativeOriginalBattleResultRenderer victory-text presentation.
- `form_regroupconfirm` — P66/P68 confirm geometry + source commander/equipment preview.
- `form_generalupgrade` — P71 NativeOriginalGeneralUpgradeScene + HQ rank hotspot.

## Intentionally excluded from PORT_ONLY single-player

- `form_debuginfo` — Debug-only original surface; excluded from Release candidate.
- `form_servicedialog` — Legacy service/customer-support platform surface; excluded from offline PORT_ONLY.
- `form_buymedal` — IAP/medal-purchase surface; excluded; user medals are intentionally unlimited.
- `form_pause_multiplay` — Multiplayer-only.
- `form_multiplayervictory` — Multiplayer-only.
- `form_multiplayermode` — Multiplayer-only.
- `form_localmode` — Legacy multiplayer/local-network setup.
- `form_selhost` — Multiplayer host selection.
- `form_waitingplayer` — Multiplayer waiting room.
- `form_transmitting` — Multiplayer transport/status.
- `form_multiplaymsg` — Multiplayer message surface.
- `form_aboutdialog` — Non-gameplay legacy about/service surface; not required for offline single-player acceptance.
- `form_selunlocktool` — Legacy operator/unlock-tool surface (btn_cmcc); excluded from offline single-player.
- `form_new_game` — Legacy online/promotional/new-game shell containing platform/social/service hooks; excluded from offline PORT_ONLY.
- `form_rewardedvideo` — Rewarded-ad surface; excluded.

## Deferred, non-blocking or evidence-limited

- `form_loading` — Startup-only original loading presentation. Mature Web restores it, but Native iOS currently boots from a black placeholder directly to main menu. Cosmetic/startup acceptance item, not a gameplay-route blocker.
- `form_messagebox` — Generic confirm/cancel shell. No proven mature offline single-player trigger found in current evidence; do not invent a route solely for coverage.
- `form_claim` — Original 200x100 claim visual shell is restored as a reusable Native component, but intentionally not bound to Achievement because no local offline trigger evidence proves that relationship.

## Acceptance consequence

Do **not** create new P-level gameplay work merely to make the census numerically 57/57 routed. The excluded rows are deliberately outside the PORT_ONLY single-player target, and the evidence-limited rows should not be invented. From this checkpoint, the next highest-value milestone is **Xcode Build Succeeded** followed by real-device smoke testing.
