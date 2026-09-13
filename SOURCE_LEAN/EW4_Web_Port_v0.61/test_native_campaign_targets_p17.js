'use strict';
const assert=require('assert');
const fs=require('fs');
const C=require('./native_campaign_core.js');
const raw=JSON.parse(fs.readFileSync('./assets/data/battles_runtime.json','utf8'));
const battles=raw.battles;
const manifest=JSON.parse(fs.readFileSync('./assets/data/native_campaign_targets.json','utf8'));
const get=f=>battles.find(b=>b.file===f);
const rows=z=>battles.filter(b=>new RegExp(`^campaign${z}_[0-9]+\\.btl$`).test(b.file)).sort((a,b)=>a.file.localeCompare(b.file,undefined,{numeric:true}));
function makeState(file,playerOwner=null){const b=get(file);return{battle:b,playerOwner:playerOwner==null?+b.player_owner_default:+playerOwner,units:b.units.map(u=>({...u,dead:false})),objects:b.objects.map(o=>({...o})),ownership:[...b.ownership]}}
function ownerAtFor(state,q,r){const b=state.battle,h=b.header,x=+q-h.origin_x,y=+r-h.origin_y;if(x<0||y<0||x>=h.width||y>=h.height)return 255;const idx=y*h.width+x-(b.owner_index_bias??0);return idx>=0?(state.ownership[idx]??255):255}
function setOwnerAt(state,q,r,owner){const b=state.battle,h=b.header,x=+q-h.origin_x,y=+r-h.origin_y,idx=y*h.width+x-(b.owner_index_bias??0);assert(idx>=0&&idx<state.ownership.length);state.ownership[idx]=owner}

assert.deepEqual(manifest.totals,{battles:101,map_type1:349,map_type2:5,unit_type1:185,unit_type2:6});
assert.equal(manifest.evidence.map_target_byte,10);assert.equal(manifest.evidence.unit_target_byte,19);

// Regression fence: legacy object raw[14] is a facility flag, never a strategic-target source.
const b410=get('campaign4_10.btl');const shopLike=b410.objects.find(o=>Array.isArray(o.raw)&&+o.raw[14]===2);assert(shopLike,'fixture must contain legacy raw[14]=2 facility');
let state=makeState('campaign4_10.btl');let allTargets=[...C.targetEntities(state,manifest,1,(q,r)=>ownerAtFor(state,q,r)),...C.targetEntities(state,manifest,2,(q,r)=>ownerAtFor(state,q,r))];
assert(!allTargets.some(t=>t.kind==='map'&&+t.recordIndex===+shopLike.index),'facility parser index must not masquerade as native target record');

// Native side relation: same side allies; side1/2 oppose; side3 is a third hostile faction; side4 is neutral.
const s118=C.battleSpec(manifest,get('campaign1_18.btl'));
assert.equal(C.campaignRelation(s118,0,2),'ally'); // side1 + side1
assert.equal(C.campaignRelation(s118,0,1),'hostile'); // side1 vs side2
assert.equal(C.campaignRelation(s118,0,5),'hostile'); // side1 vs side3
assert.equal(C.campaignRelation(C.battleSpec(manifest,get('campaign1_01.btl')),0,4),'neutral'); // side4

// All 11 type2 triggers correspond one-for-one to the 11 native hidden stages.
const expectedSecretParents={
  'campaign1_04.btl':'campaign1_05.btl','campaign1_17.btl':'campaign1_18.btl',
  'campaign2_04.btl':'campaign2_05.btl','campaign2_13.btl':'campaign2_14.btl',
  'campaign3_11.btl':'campaign3_12.btl','campaign3_13.btl':'campaign3_14.btl',
  'campaign4_10.btl':'campaign4_11.btl','campaign4_10b.btl':'campaign4_12.btl',
  'campaign5_04.btl':'campaign5_05.btl','campaign5_08.btl':'campaign5_09.btl','campaign6_08.btl':'campaign6_09.btl'
};
const type2Files=Object.entries(manifest.battles).filter(([,b])=>[...(b.map_targets||[]),...(b.unit_targets||[])].some(x=>+x.type===2)).map(([f])=>f).sort();
assert.deepEqual(type2Files,Object.keys(expectedSecretParents).sort());

// Unit-type2 and map-type2 both clear only after the hostile target is actually destroyed/captured.
state=makeState('campaign2_04.btl');assert.equal(C.yellowSecretCleared(state,manifest,(q,r)=>ownerAtFor(state,q,r)),false);const yUnit=C.battleSpec(manifest,state.battle).unit_targets.find(x=>+x.type===2);state.units.find(u=>+u.index===+yUnit.unit_index).dead=true;assert.equal(C.yellowSecretCleared(state,manifest,(q,r)=>ownerAtFor(state,q,r)),true);
state=makeState('campaign1_17.btl');assert.equal(C.yellowSecretCleared(state,manifest,(q,r)=>ownerAtFor(state,q,r)),false);const yMap=C.battleSpec(manifest,state.battle).map_targets.find(x=>+x.type===2);setOwnerAt(state,yMap.q,yMap.r,0);assert.equal(C.yellowSecretCleared(state,manifest,(q,r)=>ownerAtFor(state,q,r)),true);

// Hidden rows do not block normal progression; they become selectable only after secret unlock.
const r1=rows(1),progress={'campaign1_04.btl':1},p=f=>progress[f]||0,secret=new Set();const i5=r1.findIndex(b=>b.file==='campaign1_05.btl'),i6=r1.findIndex(b=>b.file==='campaign1_06.btl');
assert.equal(C.stageSelectable(r1,i5,p,f=>secret.has(f)),false);assert.equal(C.stageSelectable(r1,i6,p,f=>secret.has(f)),true);secret.add('campaign1_05.btl');assert.equal(C.stageSelectable(r1,i5,p,f=>secret.has(f)),true);

// campaign4_10 is a true country branch; a hidden branch can never reveal its sibling.
const r4=rows(4);assert.deepEqual(C.selectableCountryCodes(b410),['tur','rus']);let v=C.resolveVariant(b410,'tur',battles);assert.equal(v.battle.file,'campaign4_10.btl');v=C.resolveVariant(b410,'rus',battles);assert.equal(v.battle.file,'campaign4_10b.btl');assert.deepEqual(C.hiddenUnlockFiles(r4,b410,'tur',true),['campaign4_11.btl']);assert.deepEqual(C.hiddenUnlockFiles(r4,get('campaign4_10b.btl'),'rus',true),['campaign4_12.btl']);assert.deepEqual(C.hiddenUnlockFiles(r4,get('campaign4_11.btl'),'tur',true),[]);

// Red objectives override blanket annihilation. Snapshot comes from pristine battle state so save restore cannot erase the original objective contract.
state=makeState('campaign1_03.btl');const initial=C.initialTargetSnapshot(state,manifest,(q,r)=>ownerAtFor(state,q,r));assert.deepEqual(initial.type1,{friendly:1,hostile:3,neutral:0,total:4});assert.equal(C.mainObjectiveOutcome(state,manifest,initial,(q,r)=>ownerAtFor(state,q,r),true,true),null);
for(const t of C.targetEntities(state,manifest,1,(q,r)=>ownerAtFor(state,q,r)))if(t.status==='hostile'&&t.kind==='unit')t.entity.dead=true;
assert.equal(C.mainObjectiveOutcome(state,manifest,initial,(q,r)=>ownerAtFor(state,q,r),true,true)?.kind,'victory');
state=makeState('campaign1_03.btl');for(const t of C.targetEntities(state,manifest,1,(q,r)=>ownerAtFor(state,q,r)))if(t.status==='friendly'&&t.kind==='unit')t.entity.dead=true;assert.equal(C.mainObjectiveOutcome(state,manifest,initial,(q,r)=>ownerAtFor(state,q,r),true,true)?.kind,'defeat');

// A map-objective campaign supports capture-driven victory without killing ordinary enemy units.
state=makeState('campaign1_01.btl');const initial101=C.initialTargetSnapshot(state,manifest,(q,r)=>ownerAtFor(state,q,r));assert(initial101.type1.hostile>0);for(const t of C.targetEntities(state,manifest,1,(q,r)=>ownerAtFor(state,q,r)))if(t.status==='hostile'&&t.kind==='map')setOwnerAt(state,t.q,t.r,0);assert.equal(C.mainObjectiveOutcome(state,manifest,initial101,(q,r)=>ownerAtFor(state,q,r),true,true)?.kind,'victory');

console.log('native campaign target/secret P17: PASS');
