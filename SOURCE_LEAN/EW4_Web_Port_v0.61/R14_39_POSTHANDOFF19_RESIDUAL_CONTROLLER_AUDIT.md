# R14-39 Post-Handoff 19 — Residual Native Controller Audit

Date: 2026-09-09

## Scope frozen in P19

P19 is deliberately a bounded residual-controller pass. It does **not** claim every layout form is now frozen. It freezes only controller work with direct original-layout/native evidence and production tests.

### 1. MOD general dismissal (non-original feature)
- Original EW4 has no dismissal scene/button; dismissal remains clearly a player MOD layered only onto HQ general management.
- Only HQ-owned non-princess generals are dismissible. All eight princesses remain permanent.
- Dismissal requires explicit confirmation.
- Equipped items are preflight-returned through the real 28-slot ItemBank. If the inventory cannot accept all returned equipment, dismissal is blocked atomically.
- On commit, ownership, rank/nobility/progress/generalStats are cleared and equipment override becomes `[null,null]`, preventing base equipment resurrection on re-recruit.

### 2. Native `form_roundturn`
Original `layout-568h.xml` geometry: 320x175. P19 restores the high-frequency end-of-player-round summary instead of jumping directly into the next controller.
- money / industry income
- food add / food delete
- current round
- original best / win round thresholds
- up to six player generals
- original RoundTurn open-SFX path
- round dialogue/autosave continues only after the panel closes
- all required RoundTurn assets are in the PWA pre-cache

### 3. Native Exchange / RecruitGeneral shell
- `form_exchange`: 440x259 geometry.
- Original tutorial/native aliases `btn_buy_1..4` and native sell aliases `btn_sell_1..4` are represented by actual controls.
- Existing recovered commerce quote/rate math remains authoritative; P19 changes the Scene shell/controller wiring, not the proven commerce math.
- `form_recruitgeneral`: 300x275 tavern geometry with four native-sized general rows instead of a horizontal Web card strip.
- Existing P14 `SceneShop` semantics remain unchanged.

## Important non-scope / next-pass item
`form_stageintro` (360x219) is **not** frozen in P19. The original campaign list already has its own `group_intro`; `form_stageintro` is a separate Scene after stage confirmation. Layout alone does not prove whether its close/transition occurs before or after general deployment. Do not replace the current campaign transition by guessing. Recover `CSceneStageIntro` transition timing from native code first.

## Verification
- app.js syntax: PASS
- P19 dismissal test: PASS
- P19 RoundTurn test including offline assets: PASS
- P19 native Exchange / RecruitGeneral geometry test: PASS
- P15 tutorial integration remains PASS with all 273/273 commands and exact buy-button aliases.
- Full independent JS tree: **93 / 93 PASS**.

## Do not regress
- Do not make princesses dismissible.
- Do not delete a general when equipped items cannot be safely returned.
- Do not restore the old immediate round transition that bypasses `form_roundturn`.
- Do not break tutorial `btn_buy_1..4` aliases while changing Exchange UI.
- Do not re-implement P14 shop math or P18 general math in this controller pass.
- Do not claim StageIntro is original until its native transition order is proved.
