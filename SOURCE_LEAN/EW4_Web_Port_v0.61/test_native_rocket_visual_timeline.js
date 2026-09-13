'use strict';
const fs=require('fs'),assert=require('assert');
const fx=JSON.parse(fs.readFileSync('assets/data/native_simple_effects.json','utf8'));
const data=JSON.parse(fs.readFileSync('assets/data/native_effects_audio.json','utf8'));
const core=require('./native_effect_audio_core.js');
const app=fs.readFileSync('app.js','utf8');

assert.deepStrictEqual(fx.groups['effect_rocket1.xml'],['effect_rocket1__cloud','effect_rocket1__firecloud']);
assert.equal(fx.effects['effect_rocket1__cloud'].source_xml,'effect_rocket1.xml');
assert.equal(fx.effects['effect_rocket1__cloud'].image,'cloud.png');
assert.deepStrictEqual(fx.effects['effect_rocket1__cloud'].atlas_rect,{x:327,y:97,w:64,h:64,refx:31,refy:25});
assert.equal(fx.effects['effect_rocket1__cloud'].angle_min,140);
assert.equal(fx.effects['effect_rocket1__cloud'].angle_max,160);
assert.equal(fx.effects['effect_rocket1__cloud'].speed_min,15);
assert.equal(fx.effects['effect_rocket1__cloud'].speed_max,40);
assert.equal(fx.effects['effect_rocket1__firecloud'].blend,'add');
assert.equal(fx.effects['effect_rocket1__firecloud'].particle_width,7);
assert.deepStrictEqual(fx.effects['effect_rocket1__firecloud'].atlas_rect,{x:1,y:294,w:60,h:60,refx:31,refy:26});

const cases={
 'rocket 1 right':{x:25,y:-23,rot:0},
 'rocket 1 left':{x:-25,y:-23,rot:220},
 'rocket 2 right':{x:12,y:-20,rot:0},
 'rocket 2 left':{x:-12,y:-20,rot:220}
};
for(const [name,want] of Object.entries(cases)){
  const cues=core.scheduledCues(data,name,1);
  assert.equal(cues.length,3,name);
  assert.deepStrictEqual(cues.map(c=>c.at),[1.6,1.8,2.0]);
  assert.deepStrictEqual(cues.map(c=>c.delayMs),[1600,1800,2000]);
  for(const cue of cues){
    assert.equal(cue.effect,'effect_rocket1.xml');
    assert.equal(cue.sound,'sfx_rocket.wav');
    assert.equal(cue.x,want.x);assert.equal(cue.y,want.y);assert.equal(cue.rot,want.rot);
  }
}
assert(app.includes('for(const cue of cues)'));
assert(app.includes('spawnNativeAttackTimelineEffect(cue.effect,u,cue)'));
console.log('native rocket visual timeline PASS: original triple cue 1.6/1.8/2.0 + offsets/220deg left rotation + two native emitters wired');
