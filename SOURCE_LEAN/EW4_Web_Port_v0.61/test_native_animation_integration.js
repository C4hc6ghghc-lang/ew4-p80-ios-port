const fs=require('fs'),path=require('path'),assert=require('assert');
const html=fs.readFileSync('index.html','utf8'),app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
const pack=JSON.parse(fs.readFileSync('assets/data/native_animation_core877.json','utf8'));
const anim=require('./native_animation_controller.js');
const compact=require('./compact_bile_runtime.js');
assert(html.includes('native_animation_controller.js'));
assert(app.includes("fetchJSON('assets/data/native_animation_core877.json')"));
assert(app.includes('new EW4NativeAnimation.NativeAnimationPlayer'));
assert(app.includes("a1.x<a0.x?'left':'right'"));
assert(sw.includes('native_animation_core877.json'));
assert.strictEqual(pack.unit_count,877);assert.strictEqual(pack.motion_count,3519);assert.strictEqual(Object.keys(pack.units).length,877);
const base=path.join(__dirname,'assets','bile_runtime'),cache=new Map();
function bile(res){if(cache.has(res))return cache.get(res);const b=new compact.Bile(fs.readFileSync(path.join(base,res+'.bin')),fs.readFileSync(path.join(base,res+'.xml'),'utf8'));cache.set(res,b);return b}
let compactResolved=0;
for(const [name,u] of Object.entries(pack.units)){
  assert(u.motions.some(m=>m.type==='ready'),`${name} ready`);assert(u.motions.some(m=>m.type==='attack'),`${name} attack`);
  for(const m of u.motions){const a=pack.assets[m.asset];assert(a,`${name}/${m.type} asset`);assert(a.compact_only===true);const b=bile(a.resource),idx=b.nameToItem[a.motion_name];assert.notStrictEqual(idx,undefined,`${name}/${a.motion_name}`);assert.strictEqual(b.items[idx].frames,a.frame_count);compactResolved++;}
  for(const direction of ['left','right']){const c=anim.buildAttackChain(pack,name,{direction,weapon:'',targetClass:'infantry'});assert(c[0].kind==='attack');assert(c.at(-1).kind==='ready');}
}
assert.strictEqual(compactResolved,3519);
for(const u of ['Militia 1','Machine Gun fra 2','Guards Cavalry aus 2','Rocket gbr 2','Battleship','Ironclad','Large Fortress'])assert(pack.units[u],u);
console.log(`native animation integration PASS: 877 units / 3519 motions / ${pack.unique_asset_count} compact assets / direct BILE production runtime`);
