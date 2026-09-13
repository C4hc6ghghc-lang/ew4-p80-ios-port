const fs=require('fs'),path=require('path'),assert=require('assert');
const C=require('./compact_bile_runtime.js');
const base=path.join(__dirname,'assets','bile_runtime');
const manifest=JSON.parse(fs.readFileSync(path.join(base,'manifest.json'),'utf8'));
assert.strictEqual(manifest.format,'EW4_COMPACT_BILE_RUNTIME_V1');
assert.strictEqual(manifest.unit_count,877);
assert.strictEqual(manifest.motion_count,3519);
assert.strictEqual(Object.keys(manifest.resources).length,12);
assert(manifest.raw_total_bytes<11*1024*1024);
const dm=C.parseDefMotion(fs.readFileSync(path.join(base,'def_motion.xml'),'utf8'));
assert.strictEqual(dm.unitCount,877);assert.strictEqual(dm.motionCount,3519);
const core=JSON.parse(fs.readFileSync(path.join(__dirname,'assets','data','native_animation_core265.json'),'utf8'));
const cache=new Map();
function bile(res){if(cache.has(res))return cache.get(res);const b=new C.Bile(fs.readFileSync(path.join(base,res+'.bin')),fs.readFileSync(path.join(base,res+'.xml'),'utf8'));cache.set(res,b);return b}
function near(a,b,eps=2e-3){return Math.abs(a-b)<=eps}
function checkUnitMotion(unitName,type,index=0,dir='all'){
  const u=dm.units[unitName];assert(u,`unit ${unitName}`);const m=C.selectMotion(u,type,index,dir),b=bile(u.res),idx=b.nameToItem[m.name];assert.notStrictEqual(idx,undefined,`${unitName}/${type} item`);const info=b.motionInfo(m.name);
  const cu=core.units[unitName];assert(cu,`core unit ${unitName}`);const cm=cu.motions.find(x=>x.type===type&&+x.index===+index&&x.direction===dir) || cu.motions.find(x=>x.type===type&&+x.index===+index);assert(cm,`core motion ${unitName}/${type}`);const a=core.assets[cm.asset];assert(a);assert.strictEqual(info.frameCount,a.frame_count);assert(near(info.fps,a.fps,1e-5));assert.strictEqual(u.x,cu.native_anchor.x);assert.strictEqual(u.y,cu.native_anchor.y);for(let i=0;i<4;i++)assert(near(info.worldUnion[i],a.world_union[i]),`${unitName}/${type} union[${i}] ${info.worldUnion[i]} vs ${a.world_union[i]}`);
}
// Cover infantry, cavalry alternate attack, cyclic siege-artillery Finish, and Rocket Reload.
checkUnitMotion('Militia 1','ready');
checkUnitMotion('Militia 1','attack');
checkUnitMotion('Light Cavalry fra 1','attack');
checkUnitMotion('Guards Cavalry aus 2','attack',1,'all');
checkUnitMotion('Siege Artillery rus 1','finish');
checkUnitMotion('Rocket aus 2','reload');
console.log(`compact BILE runtime PASS · ${dm.unitCount} units / ${dm.motionCount} motions / ${(manifest.raw_total_bytes/1048576).toFixed(2)} MiB raw source pack`);
