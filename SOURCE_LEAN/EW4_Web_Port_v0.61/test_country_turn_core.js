'use strict';
const assert=require('assert');
const C=require('./country_turn_core.js');
const DB=require('./assets/data/battles_runtime.json');
const conquest=DB.battles.find(x=>x.file==='conquest1.btl');
assert(conquest,'conquest1 missing');
assert.deepEqual(C.countryResources(conquest.countries[0]),{money:100,industry:20,food:500},'France conquest country ledger must come from BTL country record');
assert.deepEqual(C.countryResources(conquest.countries[1]),{money:100,industry:200,food:500},'Britain country ledger mismatch');
const ledgers=C.buildLedgers(conquest,{mode:'conquest',playerOwner:3});
assert.deepEqual(ledgers['3'],{money:50,industry:70,food:500},'selected Russia must use its own conquest ledger');
assert.equal(C.relation(conquest,0,2,{mode:'conquest',playerOwner:0}),'ally','France and Italy share conquest relation group 2');
assert.equal(C.relation(conquest,0,1,{mode:'conquest',playerOwner:0}),'hostile','France and Britain are opposing conquest relation groups');
assert.equal(C.relation(conquest,0,14,{mode:'conquest',playerOwner:0}),'neutral','Piedmont conquest relation group 4 must remain neutral');
const units=conquest.units.map(u=>({...u,dead:false}));
const order=C.aiTurnOrder(conquest,units,0,'conquest');
assert(order.includes(1)&&order.includes(2)&&order.includes(3),'multi-country conquest AI order must retain active countries');
assert(!order.includes(0),'player country must not appear in AI order');
assert(!order.includes(14)&&!order.includes(15)&&!order.includes(16)&&!order.includes(17),'known conquest neutrals must not auto-act');

// Campaign relation_hint is structurally different and must never be mistaken for conquest alliance groups.
const cph=DB.battles.find(x=>x.file==='campaign2_06.btl');
assert(cph,'campaign2_06 missing');
assert.equal(cph.countries[0].relation_hint,cph.countries[1].relation_hint,'Copenhagen provides the same-hint counterexample');
assert.equal(C.relation(cph,0,1,{mode:'campaign',playerOwner:0}),'hostile','campaign same-hint Denmark must still be hostile to player Britain');
assert.equal(C.relation(cph,1,8,{mode:'campaign',playerOwner:0}),'ally','separate non-player campaign countries are kept in one conservative enemy bloc until native campaign diplomacy is decoded');
const cphOrder=C.aiTurnOrder(cph,cph.units.map(u=>({...u,dead:false})),0,'campaign');
assert(cphOrder.includes(5),'campaign relation_hint=4 country must not be silently skipped by conquest-neutral logic');
console.log('country turn core PASS',JSON.stringify({conquestOwners:order.length,russia:ledgers['3'],campaignOwners:cphOrder.length,campaignSameHint:'not-used-as-alliance'}));
