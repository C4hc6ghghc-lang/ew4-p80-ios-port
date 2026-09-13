'use strict';
const fs=require('fs'),assert=require('assert');
const fx=JSON.parse(fs.readFileSync('assets/data/native_simple_effects.json','utf8'));
const data=JSON.parse(fs.readFileSync('assets/data/native_effects_audio.json','utf8'));
const core=require('./native_effect_audio_core.js');
const app=fs.readFileSync('app.js','utf8');
assert.deepStrictEqual(fx.groups['effect_mgunfire.xml'],['effect_mgunfire__gunflash1','effect_mgunfire__gunflashsmoke1']);
for(const id of fx.groups['effect_mgunfire.xml']){const e=fx.effects[id];assert(e);assert.equal(e.source_xml,'effect_mgunfire.xml');assert.equal(e.blend,'add');assert.equal(e.emitter_life,0.8);}
assert.deepStrictEqual(fx.effects['effect_mgunfire__gunflash1'].atlas_rect,{x:42,y:355,w:60,h:30,refx:3,refy:14});
assert.deepStrictEqual(fx.effects['effect_mgunfire__gunflashsmoke1'].atlas_rect,{x:1,y:396,w:60,h:60,refx:28,refy:30});
const r=core.scheduledCues(data,'machine gun 2 right',1);assert.equal(r.length,3);assert(r.every(x=>x.effect==='effect_mgunfire.xml'&&x.delayMs===500));assert.deepStrictEqual(r.map(x=>[x.x,x.y,x.rot]),[[11.5,-33,0],[39,-17.5,0],[19,6,0]]);
const l=core.scheduledCues(data,'machine gun 1 left',1);assert.deepStrictEqual(l.map(x=>[x.x,x.y,x.rot]),[[-13.5,-28,180],[-28.5,0,180]]);
assert(app.includes('spawnNativeAttackTimelineEffect(cue.effect,u,cue)'));
assert(app.includes('function spawnNativeUnitLocalEffect(effectId,u,offsetX=0,offsetY=0,rotation=0)'));
assert(app.includes("const ids=NATIVE_SIMPLE_EFFECTS_DATA?.groups?.[effectFile]||[]"));
assert(app.includes('unitLocal:true'));
console.log('native machine-gun visual timeline PASS: original offsets/rotation + dual emitters wired');
