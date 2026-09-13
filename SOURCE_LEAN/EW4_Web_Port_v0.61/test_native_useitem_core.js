'use strict';
const assert=require('assert');
const use=require('./native_useitem_core.js');
const items={
  11:{id:11,function:7,value:0},12:{id:12,function:6,value:0},13:{id:13,function:8,value:65},14:{id:14,function:8,value:130},15:{id:15,function:8,value:200}
};
assert.deepEqual(use.USE_ITEM_IDS,[11,12,13,14,15]);
let u={hp:100,max_hp:100};
assert.equal(use.canUse(items[13],u,0),false);
u.hp=60;assert.equal(use.canUse(items[13],u,0),true);
let r=use.apply(items[13],u,{round:4,currentMorale:0});assert.equal(r.ok,true);assert.equal(r.healed,40);assert.equal(u.hp,100);assert.equal(r.effect,'effect_recover');assert.equal(r.sfx,'sfx_supply.wav');
u={hp:50,max_hp:100};r=use.apply(items[14],u,{round:4});assert.equal(u.hp,100);assert.equal(r.healed,50);
u={hp:50,max_hp:300};r=use.apply(items[15],u,{round:4});assert.equal(u.hp,250);assert.equal(r.healed,200);
u={hp:100,max_hp:100};assert.equal(use.canUse(items[11],u,-1),true);assert.equal(use.canUse(items[11],u,0),false);r=use.apply(items[11],u,{round:7,currentMorale:-1});assert.equal(u.nativeMoraleBase,0);assert.equal(u.nativeMoraleUntilRound,10);assert.equal(r.kind,'wine');
u={hp:100,max_hp:100};assert.equal(use.canUse(items[12],u,0),true);assert.equal(use.canUse(items[12],u,1),false);r=use.apply(items[12],u,{round:7,currentMorale:0});assert.equal(u.nativeMoraleBase,1);assert.equal(u.nativeMoraleUntilRound,10);assert.equal(r.kind,'spirit');
assert.equal(use.canUse({id:53,function:17},u,0),false);
console.log('native use-item core tests passed');
