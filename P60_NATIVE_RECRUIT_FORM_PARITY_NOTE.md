# P60 Native Recruit Form Parity Note

Scope: close the remaining `form_recruitunit` Native content-layer gap without changing recruitment rules.

## Evidence used
- Frozen `SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml`:
  - form 441x185
  - `lbox_unit` x2 y37 440x65, 72px item stride, 1px interval
  - `grid_info` x2 y109 152x72, 4 columns, 24px rows
  - `group_desc` x155 y109 284x72; text body x2 y19 280x51
  - `build_frame.png`, `item_selected_ex.png`/selection behavior evidence
- Mature P39 recruit controller/CSS for the 4x3 information semantics, repeated-tap formation selection and content arrangement.
- Frozen pre-P32 original recruit-art mapping for unit/marker sprite families.

## P60 changes
- Centralized recovered recruit-form geometry in `NativeOriginalFormGeometryCore.Recruit`.
- Added `NativeOriginalRecruitArtCore` as one shared mapping source for recruit cards and battle unit-info art.
- Replaced simplified Native recruit list cards with recovered 72x65 frame/selection geometry and original recruit art.
- Restored the 4x3 `grid_info` presentation: HP, attack interval, movement, food, range, money, industry and current/max formation; final four cells remain unused as in the mature reconstruction.
- Restored `group_desc` to title plus the original 280x51 description body instead of consuming description space with resource costs.
- Recruitment economy, card lookup, unit grade selection, round locks, player stat overrides and battle rules were not changed.

## Deliberate limit
The already-shipped Native outer screen placement/close/OK screen coordinates are preserved. The XML proves local form geometry, but this Linux audit does not establish iPhone SpriteKit top-level window placement more strongly than the existing Native adaptation. Do not claim real-device pixel parity until Xcode/iPhoneOS testing.
