'use strict';
const fs=require('fs'),assert=require('assert');
const pack=JSON.parse(fs.readFileSync('assets/data/native_animation_core265.json','utf8'));
const anim=require('./native_animation_controller.js');
function attackAsset(unitName){
  const m=pack.units[unitName].motions.find(x=>x.type==='attack'&&Number(x.index||0)===0);
  return anim.resolveAsset(pack,m);
}
const militia=attackAsset('Militia 1');
assert.strictEqual(anim.motionSpeed(militia),1);
assert(Math.abs(anim.rawDurationMs(militia)-(militia.frame_count/24*1000))<1e-6);
const mg=attackAsset('Machine Gun 1');
assert.strictEqual(anim.motionSpeed(mg),2.5);
assert.strictEqual(mg.frame_count,72);
assert(Math.abs(anim.rawDurationMs(mg)-1200)<1e-6,'72f @24fps speed2.5 must be 1.2s real time');
assert.strictEqual(anim.frameAtElapsed(mg,400),24,'400ms * 2.5 * 24fps = frame24');
const car=attackAsset('Armored Car 1');
assert.strictEqual(anim.motionSpeed(car),2.5);
assert(Math.abs(anim.rawDurationMs(car)-(85/24*1000/2.5))<1e-6);
for(const [name,u] of Object.entries(pack.units))for(const m of u.motions||[]){
  const a=anim.resolveAsset(pack,m),sp=anim.motionSpeed(a);
  assert(sp>0,`${name}/${m.type} invalid speed`);
  if(Number(m.speed||1)!==1)assert.strictEqual(sp,2.5,`${name}/${m.type}: unexpected non-1 native speed`);
}
console.log('native Motion@speed PASS: live duration/frame math uses native deltaTime*speed semantics');
