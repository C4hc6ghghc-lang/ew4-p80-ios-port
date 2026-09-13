# P49 Native Campaign + Conquest Outer Flow checkpoint

P49 translates the mature P39 Campaign/Conquest **outer battle flow** into Swift Native without touching frozen battlefield presentation.

## Campaign

- Uses the existing NativePlayerProfile for Campaign meta; no second save universe was created.
- Legacy missing-Stars profiles migrate once from historical best ratings; an explicit Stars=0 remains authoritative 0.
- Best-rating delta, Campaign Stars, secret unlocks and six zone-completion rewards are one-shot/deterministic.
- Stage rows, variants and hidden-stage selection are typed Native Core parity.
- `native_campaign_targets.json` is typed; pristine BTL target snapshots prevent restored saves from redefining authored objectives.
- Runtime end checks happen only at authored boundaries: damage impact completion, captured-object movement completion, or settlement before RoundTurn.
- Victory marks gameplay ended, writes rating/Stars/secret to the shared profile, presents the P48 Result, then Continue applies mature zone routing/reward semantics.

## Conquest

- NativeBattleScene can open true `.conquest` mode with an explicit player owner.
- Extinction delegates to the already-frozen rule: land army gone + non-port land facilities lost + all ports lost; navy/fort remnants do not delay defeat.
- Fresh defeated owners are announced once; final result also waits for authored visual boundaries.
- Europe/America normal achievement and Asia fast-win Challenge scoring include the mature round/resource/HQ/Campaign-star contributions.
- Stored achievement values only improve; Continue either records normal score or routes an eligible fast win to a coordinator Challenge choice.
- P49 does **not** fake original Conquest selection/Challenge/Summary UI. Those renderers and app-level outer navigation are P50 work.

## Verification

- Native tests: **163/163 PASS** (154 Swift Testing + 9 XCTest).
- Mature P39 JS: **126/126 PASS**.
- Resource audit: `errors=[]`, 101 battles, 7407/7407 units, 5482/5482 building sprites, 877 animation units, 3519 motions, BILE 12/12.
- Project Swift syntax parse: **101/101 PASS**, generated build sources excluded.
- IPA preflight: **26/26 PASS**.
- P48 -> P49 SOURCE_LEAN: 6321 existing files, changed 0 / missing 0 / new 0.
- Frozen sensitive Native existing files changed: 0; Native Resources changed: 0.

No Xcode/iPhoneOS Release build or real-device acceptance is claimed from this Linux environment.
