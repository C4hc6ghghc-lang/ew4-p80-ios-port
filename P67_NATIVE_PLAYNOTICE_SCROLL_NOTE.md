# P67 Native Play Notice Scroll Fidelity

P67 is a narrow behavior/content parity pass over original `form_playnotice`.

## Recovered original contract
- `form_playnotice`: 400x225 user window.
- `group_conquest`: 390x186 framed content viewport.
- Original `HtmlBox`: `maxrows=999`, `rowblank=20`, `text=html_notice`, `scrollback=scrollbar_gray.png`, `scrollbar=scrollbar_darkgray.png`.
- Frozen `html_notice` decodes to 24 non-empty help lines.

## Native corrections
- Added `NativeOriginalPlayNoticeCore` for deterministic line parsing, content height, max-scroll clamping, and scrollbar thumb metrics.
- Added recovered Play Notice geometry to `NativeOriginalFormGeometryCore.Tutorial`.
- `NativeOriginalTutorialScene` no longer truncates with `prefix(11)`; all 24 frozen help items enter the scrollable content layer.
- Restored a 390x186 clipped `SKCropNode` viewport and original gray/dark-gray scrollbar assets.
- With 24 lines at 20px spacing, content height is 480px and max scroll is 294px.
- Dragging the content scrolls the help text; dragging the scrollbar drives the same clamped scroll state.
- Touching content or scrollbar no longer dismisses the overlay. Only the original close button dismisses it.
- Tutorial battle launch routing remains unchanged (`tutorials1.btl`, `tutorials2.btl`).

## Scope
No gameplay rules, battle scripts, AI, saves, economy, recruitment, shop, items/defense, map/LOD/unit presentation, HUD, camera, Native Resources, or SOURCE_LEAN bytes changed.
