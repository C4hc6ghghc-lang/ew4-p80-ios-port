# EW4 Web Port v0.61 — r14-39 original maptext audit

## Original source restored
The original APK map-label layer is now preserved under `assets/maptext_native/`:
- `maptext.bin`
- `maptext.xml`
- `maptext.png`
- `maptextpos_europe.xml`
- `maptextpos_america.xml`

All five files are copied byte-for-byte from the authoritative APK. `SHA256SUMS.txt` records the source hashes.

## Structure
- `maptext.bin`: BILE v3, **338** static composition items
- `maptext.xml`: **178** texture-atlas image elements
- Europe placements: **102** records
- America placements: **41** records
- Placement `libName` resolution: **143/143 PASS**, 0 missing

The map labels therefore do not need to be retyped or recreated with a Web font. They are original raster/BILE assets.

## Geometry
`left/top/width/height` from each `maptextpos_*` record are treated as the authoritative final world-space placement bounds. `tx/ty` is retained as original metadata but is not assumed to be the rectangle center; several original records (e.g. Tunisia/Crimea/Atlantic Ocean) prove that assumption false.

The static BILE item's own geometric bounds are mapped into the recorded placement box using independent X/Y scales. This preserves the original intentionally stretched regional labels.

## Runtime integration
The battle map now lazily loads the maptext BILE source for the active world and draws it in the same world transform as the original Europe/America background image. Placement-box culling avoids drawing labels outside the current camera view.

No arbitrary Web LOD threshold has been introduced. The placement XML contains no per-label zoom threshold. Exact native hide/show behavior, if any exists outside these resources, remains a controller-fidelity question for later native verification rather than being invented here.

## Raster validation
Skia direct-raster smoke succeeded for representative labels including Canada, Scotland, Tunisia, and Crimea using the original `maptext.png` atlas and BILE composition data.
