'use strict';
const assert=require('assert'),fs=require('fs'),C=require('./native_campaign_core.js');
const battles=JSON.parse(fs.readFileSync('./assets/data/battles_runtime.json','utf8')).battles;
const manifest=JSON.parse(fs.readFileSync('./assets/data/native_campaign_targets.json','utf8'));
const campaign=battles.filter(b=>/^campaign[1-6]_\d+(?:b)?\.btl$/.test(b.file));
function stateFor(b){return{battle:b,playerOwner:+b.player_owner_default,units:b.units.map(u=>({...u,dead:false})),objects:b.objects.map(o=>({...o})),ownership:[...b.ownership]}}
function ownAt(S,q,r){const h=S.battle.header,x=q-h.origin_x,y=r-h.origin_y;if(x<0||y<0||x>=h.width||y>=h.height)return 255;const i=y*h.width+x-(S.battle.owner_index_bias??0);return i>=0?(S.ownership[i]??255):255}
function setOwn(S,q,r,o){const h=S.battle.header,i=(r-h.origin_y)*h.width+(q-h.origin_x)-(S.battle.owner_index_bias??0);assert(i>=0&&i<S.ownership.length,`${S.battle.file}: target ownership index`);S.ownership[i]=o}
function hostileOwner(spec,po){return(spec.countries||[]).map(x=>+x.owner).find(o=>C.campaignRelation(spec,po,o)==='hostile')}
let redStages=0,yellowStages=0,redVictorySims=0,redDefeatSims=0,yellowSims=0;
for(const b of campaign){
  const spec=C.battleSpec(manifest,b);assert(spec,`${b.file}: native target spec`);let S=stateFor(b),owner=(q,r)=>ownAt(S,q,r);const initial=C.initialTargetSnapshot(S,manifest,owner);
  assert.equal(C.mainObjectiveOutcome(S,manifest,initial,owner,true,true),null,`${b.file}: no instant result at battle start`);
  const red=C.targetEntities(S,manifest,1,owner),yellow=C.targetEntities(S,manifest,2,owner);if(red.length)redStages++;if(yellow.length)yellowStages++;
  if(initial.type1.hostile>0){
    S=stateFor(b);owner=(q,r)=>ownAt(S,q,r);const init=C.initialTargetSnapshot(S,manifest,owner);
    for(const t of C.targetEntities(S,manifest,1,owner)){if(t.status!=='hostile')continue;if(t.kind==='unit')t.entity.dead=true;else setOwn(S,t.q,t.r,S.playerOwner)}
    const out=C.mainObjectiveOutcome(S,manifest,init,owner,true,true);assert.equal(out?.kind,'victory',`${b.file}: hostile red objectives cleared => victory`);redVictorySims++;
  }
  if(initial.type1.friendly>0){
    const ho=hostileOwner(spec,+b.player_owner_default);assert.notEqual(ho,undefined,`${b.file}: friendly objective stage needs hostile owner fixture`);
    S=stateFor(b);owner=(q,r)=>ownAt(S,q,r);const init=C.initialTargetSnapshot(S,manifest,owner);
    for(const t of C.targetEntities(S,manifest,1,owner)){if(t.status!=='friendly')continue;if(t.kind==='unit')t.entity.dead=true;else setOwn(S,t.q,t.r,ho)}
    const out=C.mainObjectiveOutcome(S,manifest,init,owner,true,true);assert.equal(out?.kind,'defeat',`${b.file}: friendly red objectives cleared => defeat`);redDefeatSims++;
  }
  if(yellow.length){
    assert.equal(C.yellowSecretCleared(S=stateFor(b),manifest,(q,r)=>ownAt(S,q,r)),false,`${b.file}: yellow target starts uncleared`);
    owner=(q,r)=>ownAt(S,q,r);for(const t of C.targetEntities(S,manifest,2,owner)){assert.equal(t.status,'hostile',`${b.file}: native type2 target must start hostile`);if(t.kind==='unit')t.entity.dead=true;else setOwn(S,t.q,t.r,S.playerOwner)}
    assert.equal(C.yellowSecretCleared(S,manifest,(q,r)=>ownAt(S,q,r)),true,`${b.file}: clearing yellow targets unlocks secret path`);yellowSims++;
  }
}
assert.equal(yellowStages,11);assert.equal(yellowSims,11);assert(redStages>50);assert(redVictorySims>40);assert(redDefeatSims>20);
console.log(`native campaign exhaustive P17 PASS: ${campaign.length} campaign BTL · red stages ${redStages} · red victory sims ${redVictorySims} · red defeat sims ${redDefeatSims} · yellow ${yellowSims}/11`);
