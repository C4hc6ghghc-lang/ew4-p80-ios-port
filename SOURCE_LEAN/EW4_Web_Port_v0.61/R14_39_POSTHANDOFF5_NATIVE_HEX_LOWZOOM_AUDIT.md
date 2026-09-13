# r14-39 Post-Handoff 5 — Native hex geometry + low-zoom status audit

This batch deliberately resolves the two highest-risk foundation gaps left by Patch 4: the exact battle-grid coordinate system and the missing strategic-zoom HP/relation composition.

## 1. Exact native cell geometry is now closed

### Native map construction evidence

The x86_64 `libeuropean-war-4.so` map-grid constructor path is:

- map setup loop: `0x83a60 .. 0x83baf`
- cell setup wrapper: `0xaadc0`
- cell constructor: `0x4cf30`

For each row/column, native setup uses:

- column step: **64**
- row step: **54**
- even-row raw x anchor: `col*64 - 32`
- odd-row raw x anchor: `col*64`
- raw y anchor starts at `-54` and advances by 54 per row
- wrapper adds half width `64/2 = 32` and half logical sprite height `72/2 = 36`

The final canonical point stored in each CEntityMap cell at `+0x0c/+0x10` is therefore:

```text
x = col*64 + (row odd ? 32 : 0)
y = row*54 - 18
```

This proves the prior Web `x=q*64, y=r*53+(q odd ? 26.5 : 0)` anchor was a historical approximation, not an equivalent native representation.

### Native hit-test evidence

`0x84be0` is the real world-to-cell partition used by battle click wrappers. It uses:

- 64-wide columns
- 54 row spacing
- parity of **row**, not column
- 32 horizontal odd-row offset
- an 18-pixel top-corner region with exact sloped-edge correction

`native_hex_core.js::worldToCell()` is a direct high-level port of that partition, including truncation behavior for the integer stages.

### Native battle rectangle evidence

`0x83bc0` computes the battle sub-rectangle from BTL origin/extent. Its top-left world anchor is:

```text
x = origin_x*64 - (origin_y even ? 32 : 0)
y = (origin_y-1)*54
```

The existing authored `centerx/centery` metadata is now applied relative to this native battle-pixel origin instead of the former 64/53 approximation.

### Runtime migration

The Web battle foundation now uses one shared module for:

- cell center
- exact world→cell hit-test
- 64x72 pointy-hex outline implied by the native partition
- odd-row six-neighbor topology
- odd-row cube distance
- battle-pixel origin / initial camera center

Rendering, tapping, movement, attack range, aura distance and pathfinding therefore no longer disagree about which stagger convention they use.

Depth order now follows row then column; the former `r + (q&1)*.5` odd-column compensation is removed.

### Exhaustive BTL validation

`test_native_hex_battle_roundtrip.js` checks every parsed battle entity:

- 101 battles
- 7,407 units
- 8,001 map objects
- 15,408 q/r -> native world point -> native hit-test round trips
- **0 mismatches**

## 2. Low-zoom strategic HP/relation composition

Patch 4 proved `mark_unit_0..21`. This batch closes the shared status layer around it.

Native resource construction around the strategic renderer loads, consecutively:

- `hpbar_blue.png`
- `hpbar_red.png`
- `hpbar_green.png`
- `hpbar_black.png`
- `hpbar_hp.png`

`0x50fc0 -> 0x5f050` draws the indexed relation ring, a dynamic HP primitive, then the army-type marker. The relation resource table corresponds to the original overview convention: own green, ally blue, hostile red, neutral black.

The HP primitive recovered from `0x5f050` uses:

- start angle: ~171 degrees (`2.9845130443573` rad)
- full-health sweep: ~198 degrees (`3.455751993850178` rad)
- sweep proportional to current/max HP
- exact piecewise integer color path: red -> yellow -> spring-green; full HP is **#00ff80**, not guessed pure green

The Web low-zoom pass now renders:

`relation ring -> dynamic HP arc -> mark_unit_<army id>`

in screen space, after the global particle pass, preserving Patch 4's proven native layer ordering.

## 3. Save/caching compatibility

- New battle saves carry `cameraGeometry = native-odd-r-64x54-v1`.
- Legacy battle saves keep all gameplay state, but their old approximation-space camera pixel pose is not reused; the camera is recentered using the battle's native geometry. This prevents an old save from opening at a shifted/invalid visual location after the coordinate migration.
- Save normalization now clamps zoom to the already-proven native **0.2..1.0** range instead of the stale pre-Patch-4 `.45..1.8` range.
- Service Worker cache advances to `posthandoff5-nativehexstatus` and now precaches both `native_hex_core.js` and the previously omitted `native_lowzoom_core.js`.

## Remaining uncertainty

1. The exact native *iteration order* of six neighbors for equal-cost path tie-breaking is not yet independently disassembled. The topology itself is fixed by the proven odd-row geometry, so reachability/range is correct; only which equally optimal visual route is chosen can still differ.
2. `centerx/centery` are strongly evidenced as authored local battle-camera offsets and are now applied to the proven native battle rectangle origin, but their specific setter call has not yet been traced end-to-end from XML parser to CEntityCamera. This is a camera-start framing uncertainty, not a cell-position/hit-test uncertainty.
3. No claim of final iPhone visual parity is made until real-device gesture/LOD validation is performed.
