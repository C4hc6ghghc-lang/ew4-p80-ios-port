# r14-39 Post-Handoff 11 — Native Headquarters / DeployGeneral controller audit

Authority: original APK `assets/layout-568h.xml` and x86 `libeuropean-war-4.so`.

## Main-menu Headquarters transition

The main-menu `btn_hq` registration path around native `0xA1164` resolves to callback `0xA1690`.
That callback asks `SceneManager` to enter `SceneDeployGeneral`.
Therefore the old Web-only `#hq` toolbar/card-wall page is not an original EW4 scene and is removed from the active UI/controller path.

## `SceneDeployGeneral` native form/controller

Original `form_deploygeneral` geometry is retained:
- `btn_princess`: x=20 y=30 70x40
- `btn_shop`: x=249 y=30 70x40
- `btn_college`: x=480 y=30 70x40
- `grid_general`: x=30 y=85 508x204, 6 columns
- count icon/text: x=255/290 y=43
- separators: y=73 / 298
- `btn_deploy`: 59x26 at lower-right native form placement

Native callbacks in the `SceneDeployGeneral` registration path around `0x957D0`:
- princess callback `0x95A20` -> `ScenePrincess`
- college callback `0x95A70` -> `SceneGetGeneral`
- shop callback `0x95AD0` -> `SceneShop`
- general-grid callback around `0x95B30` -> `SceneGeneralInfo` / `SceneGeneralUpgrade` depending event/state
- deploy callback `0x95C20`

## Main-menu vs battle context

`btn_deploy` callback `0x95C20` immediately resolves the current battle `Map` / deployment target path and returns when no valid battle target exists. The main-menu Headquarters has no battle Map target, so the shared form must not perform battle assignment there.

Web runtime now uses the same `form_deploygeneral` screen with two explicit contexts:
- `battle`: general cards select a commander and `btn_deploy` assigns to the current unit;
- `hq`: general cards open general information and `btn_deploy` cannot invoke battle assignment.

The old `renderHQ`, `hqFilter`, `#hq-grid`, `.hq-card`, and `.hq-toolbar` Web replacement are removed.

## Princess context

The user override owns/unlocks all eight princesses. In HQ context the native princess deployment slots therefore show them as already dispatched/owned; in battle context the existing princess deployment selector remains available.

## Remaining gap

`btn_shop -> SceneShop` is proven native, but the dedicated Headquarters `SceneShop` controller is not yet claimed complete in this checkpoint. The button remains visually present at its native coordinates and is intentionally not mapped to the battle-facility shop controller. This is the next Headquarters UI/controller item rather than inventing a replacement.
