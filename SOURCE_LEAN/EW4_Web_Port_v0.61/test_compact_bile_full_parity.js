const fs=require('fs'),path=require('path'),assert=require('assert');
const C=require('./compact_bile_runtime.js');
const base=path.join(__dirname,'assets','bile_runtime');
const core=JSON.parse(fs.readFileSync(path.join(__dirname,'assets','data','native_animation_core265.json'),'utf8'));
const fixDoc=JSON.parse(fs.readFileSync(path.join(__dirname,'R14_39_MACHINEGUN_FINISH_FIXES.json'),'utf8'));
const cache=new Map();
function bile(res){
  if(cache.has(res)) return cache.get(res);
  const b=new C.Bile(
    fs.readFileSync(path.join(base,res+'.bin')),
    fs.readFileSync(path.join(base,res+'.xml'),'utf8')
  );
  cache.set(res,b);return b;
}
function near(a,b,eps=2e-3){return Math.abs(a-b)<=eps}
function unionNear(a,b,eps=2e-3){return a.length===4&&b.length===4&&a.every((v,i)=>near(v,b[i],eps))}
assert.strictEqual(core.unit_count,265);
assert.strictEqual(core.unique_asset_count,1076);
assert.strictEqual(Object.keys(core.assets).length,1076);
let matched=0;
for(const [assetId,a] of Object.entries(core.assets)){
  const b=bile(a.resource);
  const info=b.motionInfo(a.motion_name);
  assert.strictEqual(info.frameCount,a.frame_count,`${assetId} frame_count`);
  assert(near(info.fps,a.fps,1e-5),`${assetId} fps ${info.fps} vs ${a.fps}`);
  assert(unionNear(info.worldUnion,a.world_union),`${assetId} world_union compact=${JSON.stringify(info.worldUnion)} core=${JSON.stringify(a.world_union)}`);
  matched++;
}
assert.strictEqual(fixDoc.count,18);
assert.strictEqual(fixDoc.fixes.length,18);
for(const fix of fixDoc.fixes){
  const a=core.assets[fix.asset];
  assert(a,`missing repaired asset ${fix.asset}`);
  assert(unionNear(a.world_union,fix.new_world_union),`${fix.unit} must use corrected new_world_union`);
  assert(!unionNear(a.world_union,fix.old_world_union),`${fix.unit} unexpectedly still uses old_world_union`);
}
console.log(`compact BILE full parity PASS · ${matched}/1076 assets · Machine Gun Finish corrected 18/18`);
