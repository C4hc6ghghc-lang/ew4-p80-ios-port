const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8');
const manifest=JSON.parse(fs.readFileSync('assets/sprite_manifest.json','utf8'));
const expected=[
 [15,22],[19,23],[17,25],[15,23],[19,21],[25,16],[24,25],[20,24],[23,22],[22,19],[25,14],
 [27,15],[20,18],[24,23],[22,18],[26,19],[27,18],[22,17],[18,18],[23,19],[24,17],[16,16]
];
for(let i=0;i<22;i++){
  const m=manifest[`mark_unit_${i}.png`];
  assert(m,`native low-zoom marker ${i} missing`);
  assert.deepStrictEqual([m.w,m.h],expected[i],`marker ${i} atlas order/dimensions drifted`);
  assert.strictEqual(m.atlas,'buildings_hd');
}
assert(app.includes('function drawNativeLowZoomUnit(u)'),'low-zoom marker renderer missing');
assert(app.includes('if(z<CAMERA_DETAIL_ZOOM)return;'),'native tactical model suppression below 0.5 missing');
assert(app.includes('if(c.zoom<CAMERA_DETAIL_ZOOM)orderedUnits.forEach(drawNativeLowZoomUnit);'),'native post-effect strategic marker pass missing');
assert(app.includes('ctx.drawImage(im,p.x-m.refx,p.y-m.refy,m.w,m.h)'),'strategic marker must remain intrinsic screen-space size');
assert(!/if\(z<CAMERA_DETAIL_ZOOM\)[^\n]*unitVisualZoom/.test(app),'low zoom must not render scaled tactical BILE model');
const upper=app.indexOf('if(S.selected&&!S.selected.dead)');
const effects=app.indexOf('drawNativeSimpleEffects();',upper);
const low=app.indexOf('orderedUnits.forEach(drawNativeLowZoomUnit)',effects);
assert(upper>=0&&effects>upper&&low>effects,'native z-order must be SelectUpper -> global effects -> low-zoom markers');
console.log('native low-zoom strategic marker LOD: PASS');
