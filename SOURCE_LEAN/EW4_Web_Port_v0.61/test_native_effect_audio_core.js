const fs=require('fs'),assert=require('assert'),core=require('./native_effect_audio_core.js');
const data=JSON.parse(fs.readFileSync('assets/data/native_effects_audio.json','utf8')),army=JSON.parse(fs.readFileSync('assets/data/army_stats.json','utf8'));
assert.equal(data.timeline_count,143,'def_effectsanim timeline count');
const seen=new Map();for(const c of Object.values(army))for(const k of Object.keys(c)){const [name,g]=k.split('|');if(!seen.has(name))seen.set(name,new Set());seen.get(name).add(+g)}
for(const [name,grades] of seen)for(const g of grades)for(const dir of ['left','right']){const key=core.resolveTimeline({army_name:name,grade:g},dir,'fra');assert(key,`${name} ${g} resolver`);assert(data.timelines[key],`${name} ${g} ${dir} -> ${key}`);}
assert.equal(core.resolveTimeline({army_name:'Armored Car',grade:1},'left'),'armored chariot 2 left');
assert.equal(core.resolveTimeline({army_name:'Militia',grade:2},'right','ind'),'militia ind 3 right');
assert.deepEqual(core.audioCues(data,'militia 1 right').map(x=>[x.at,x.sound]),[[0.92,'sfx_fire.wav'],[1.04,'sfx_fire.wav'],[1.17,'sfx_fire.wav']]);
assert.deepEqual(core.audioCues(data,'rocket 1 right').map(x=>[x.at,x.sound]),[[1.6,'sfx_rocket.wav'],[1.8,'sfx_rocket.wav'],[2,'sfx_rocket.wav']]);
console.log('native effect audio core PASS: 143 timelines; all current army grades resolve both directions');
