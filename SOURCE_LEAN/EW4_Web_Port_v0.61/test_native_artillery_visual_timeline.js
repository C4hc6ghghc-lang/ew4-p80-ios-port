'use strict';
const fs=require('fs'),assert=require('assert');
const fx=JSON.parse(fs.readFileSync('assets/data/native_simple_effects.json','utf8'));
const data=JSON.parse(fs.readFileSync('assets/data/native_effects_audio.json','utf8'));
const core=require('./native_effect_audio_core.js');
const app=fs.readFileSync('app.js','utf8');

assert.deepStrictEqual(fx.groups['effect_lightgun.xml'],['effect_lightgun__cloud1','effect_lightgun__cloud2','effect_lightgun__ray0000','effect_lightgun__fiery1']);
assert.deepStrictEqual(fx.groups['effect_gunnery.xml'],['effect_gunnery__cloud1','effect_gunnery__cloud2','effect_gunnery__ray0000','effect_gunnery__fiery1']);
assert.deepStrictEqual(fx.groups['effect_gunnery1.xml'],['effect_gunnery1__cloud1','effect_gunnery1__cloud2','effect_gunnery1__ray0000']);

for(const [group,count] of [['effect_lightgun.xml',4],['effect_gunnery.xml',4],['effect_gunnery1.xml',3]]){
  assert.equal(fx.groups[group].length,count);
  for(const id of fx.groups[group]){assert(fx.effects[id]);assert.equal(fx.effects[id].source_xml,group);}
}
assert.deepStrictEqual(fx.effects['effect_lightgun__cloud1'].atlas_rect,{x:327,y:97,w:64,h:64,refx:31,refy:25});
assert.deepStrictEqual(fx.effects['effect_lightgun__ray0000'].atlas_rect,{x:1,y:457,w:120,h:38,refx:12,refy:18});
assert.equal(fx.effects['effect_gunnery__cloud1'].gravity_max,350);
assert.equal(fx.effects['effect_gunnery1__cloud1'].particle_width,15);
assert.equal(fx.effects['effect_gunnery__ray0000'].blend,'add');

const cases={
 'light artillery 1 right':{at:1.7,effect:'effect_lightgun.xml',x:20,y:-13.5,rot:-2},
 'light artillery 2 left':{at:1.6,effect:'effect_lightgun.xml',x:-26,y:-13.5,rot:182},
 'heavy artillery 1 right':{at:1.5,effect:'effect_gunnery.xml',x:25,y:-20,rot:0},
 'heavy artillery 2 left':{at:1.6,effect:'effect_gunnery.xml',x:-24,y:-21.5,rot:220},
 'siege artillery 1 right':{at:1.45,effect:'effect_gunnery1.xml',x:20,y:-24,rot:0},
 'siege artillery 2 left':{at:1.5,effect:'effect_gunnery1.xml',x:-18,y:-21.5,rot:250}
};
for(const [name,want] of Object.entries(cases)){
  const c=core.scheduledCues(data,name,1);assert.equal(c.length,1,name);const got=c[0];
  for(const k of ['at','effect','x','y','rot'])assert.equal(got[k],want[k],`${name} ${k}`);
  assert.equal(got.sound,'sfx_naval_gun.wav');assert.equal(got.delayMs,want.at*1000);
}
// A timeline cue rotation is the rotation of the whole native effect, not only
// the particle sprite. Artillery smoke has non-zero speed, so velocity angles
// must rotate with the effect container as well.
assert(app.includes('angle_min:(+base.angle_min||0)+rot'));
assert(app.includes('angle_max:(+base.angle_max||0)+rot'));
assert(app.includes('rotangle_min:(+base.rotangle_min||0)+rot'));
assert(app.includes('spawnNativeAttackTimelineEffect(cue.effect,u,cue)'));
console.log('native artillery visual timeline PASS: light/heavy/siege original effects + timing/offset/rotation wired');
