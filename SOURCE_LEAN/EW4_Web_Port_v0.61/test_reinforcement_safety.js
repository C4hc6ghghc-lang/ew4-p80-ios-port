'use strict';
const assert=require('assert');
const DB=require('./assets/data/battles_runtime.json');
const N=require('./assets/data/battle_native_triggers.json');
const CPH=DB.battles.find(x=>x.file==='campaign2_06.btl');
assert(CPH,'campaign2_06 missing');
const raw4=CPH.units.filter(u=>Array.isArray(u.raw)&&u.raw[4]===4);
assert.equal(raw4.length,0,'raw[4] must not be reintroduced as Copenhagen round-4 spawn timer');
const positionHighByteMatches=CPH.units.filter(u=>Array.isArray(u.raw)&&u.raw[9]===4);
assert(positionHighByteMatches.length>0,'expected Copenhagen units whose decoded position high byte happens to equal 4');
for(const u of positionHighByteMatches){
  const pos=(u.raw[8]||0)+((u.raw[9]||0)<<8);
  assert(Number.isInteger(pos)&&pos>0,'raw[8..9] is a uint16 map-position field, not a round timer');
}
const french=CPH.units.filter(u=>u.owner===8);
assert.equal(french.length,3,'Copenhagen French reinforcement-country units must remain present in decoded initial BTL table');
assert(french.every(u=>u.raw[4]===0),'Copenhagen French ships do not carry a raw[4] round timer');
const allUnits=DB.battles.flatMap(b=>b.units||[]);
assert(allUnits.length>7000&&allUnits.every(u=>u.raw[31]===1),'raw[31] is corpus-wide constant 1 and cannot be a reinforcement active flag');
const cphEvent=N.battles['campaign2_06.btl'].events.find(e=>+e.event_id===2066);
assert(cphEvent&&+cphEvent.trigger_type===2&&+cphEvent.param_a===4&&+cphEvent.param_b===4,'Copenhagen reinforcement dialogue must remain a verified round-4 dialogue-only event');
const moraleNarrative=N.battles['campaign4_03.btl'].events.find(e=>+e.event_id===4035);
assert(moraleNarrative&&+moraleNarrative.trigger_type===2&&+moraleNarrative.param_a===1&&+moraleNarrative.param_b===11&&moraleNarrative.country==='tur','campaign4_03 reinforcement-worded event must remain the verified Turkish morale action at round 11');
assert((moraleNarrative.dialogue?.text||'').includes('援军'),'safety counterexample text changed unexpectedly');
console.log('reinforcement safety PASS',JSON.stringify({copenhagenRaw4Round4:raw4.length,positionHighByteEquals4:positionHighByteMatches.length,frenchUnitsAlreadyDecoded:french.length,raw31ConstantUnits:allUnits.length,campaign4_03_action:moraleNarrative.param_a}));
