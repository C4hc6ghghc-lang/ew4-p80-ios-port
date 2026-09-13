'use strict';
const assert=require('assert');
const fs=require('fs');
const targets=JSON.parse(fs.readFileSync('assets/data/native_trigger_targets.json','utf8'));
const native=require('./native_event_core.js');
const app=fs.readFileSync('app.js','utf8');

assert.equal(targets.coverage.capture_total,33);
assert.equal(targets.coverage.capture_high_confidence,31);
assert.equal(targets.coverage.capture_unresolved,2);
assert.equal(targets.coverage.death_total,25);
assert.equal(targets.coverage.death_high_confidence,23);
assert.equal(targets.coverage.death_unresolved,2);

function find(kind,battle,seq){return (targets[kind]?.[battle]||[]).find(x=>+x.sequence===+seq)}
assert.deepEqual({q:find('capture','campaign1_01.btl',1).q,r:find('capture','campaign1_01.btl',1).r},{q:21,r:39});
assert.deepEqual({q:find('capture','campaign4_08.btl',1).q,r:find('capture','campaign4_08.btl',1).r},{q:68,r:9});
assert.equal(find('death','campaign1_02.btl',1).army_name,'Heavy Artillery');
assert.equal(find('death','campaign6_10.btl',1).army_name,'Battleship');
assert.equal(native.moraleForAction(3),-3);
assert.equal(native.eventMoraleBase({nativeMoraleBase:-3,nativeMoraleUntilRound:4},1),-3);
assert.equal(native.combinedMorale(-3,0,false),-3);
assert.equal(native.combinedMorale(-3,0,true),0);

assert(app.includes("fireNativeCaptureEventsForObject(o)"));
assert(app.includes("fireNativeDeathEventsForUnit(b)"));
assert(app.includes("applyNativeScriptEvent(e,'占领触发')"));
assert(app.includes("applyNativeScriptEvent(e,'击毁触发')"));

const unresolvedC=targets.unresolved.capture.map(x=>`${x.battle}:${x.sequence}`).sort();
const unresolvedD=targets.unresolved.death.map(x=>`${x.battle}:${x.sequence}`).sort();
assert.deepEqual(unresolvedC,['campaign3_03.btl:2','campaign3_13.btl:4']);
assert.deepEqual(unresolvedD,['campaign3_14.btl:2','campaign4_09.btl:3']);
console.log('native entity triggers PASS',targets.coverage);
