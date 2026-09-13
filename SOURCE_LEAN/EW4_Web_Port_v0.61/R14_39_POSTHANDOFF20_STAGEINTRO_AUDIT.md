# R14-39 Post-Handoff 20 — Native SceneStageIntro Audit

## Native evidence / integration result
- `form_stageintro` geometry restored at 360x219.
- Native lifecycle is tied to fresh Campaign `SceneGame` initialization rather than being a generic deploy-panel overlay.
- Web integration therefore gates it with `!restored && mode === "campaign"`.
- Closing StageIntro runs the first-round continuation exactly once.
- `resetNativeStageIntro()` is deliberately side-effect free: it hides the overlay and nulls the continuation without invoking it. This is called at the start of every `openBattle()` to prevent stale continuation execution across restart/load/new battle.
- Tutorial and Conquest flows remain unchanged.

## Runtime contract
`fresh campaign -> openNativeStageIntro -> close -> beginNativeCampaignBattleAfterIntro -> round 1 dialogue/autosave`

`restore/restart/new openBattle while stale overlay exists -> resetNativeStageIntro -> no old continuation`

## Offline
P20 uses Service Worker cache `posthandoff20-stageintro`; original StageIntro decoration assets are precached.

## Verification
- `test_native_stageintro_p20.js` PASS.
- Full independent suite: 94/94 PASS.
