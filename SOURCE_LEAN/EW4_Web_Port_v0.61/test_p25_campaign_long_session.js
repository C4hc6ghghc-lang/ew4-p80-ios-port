'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const U=require('./native_upgrade_core.js');
const S=require('./native_campaign_session_core.js');
const C=require('./native_campaign_core.js');
const R=require('./native_result_core.js');
const BS=require('./battle_save_core.js');
const battleData=JSON.parse(fs.readFileSync(path.join(__dirname,'assets/data/battles_runtime.json'),'utf8'));
const battles=Array.isArray(battleData)?battleData:(battleData.battles||[]);
const techManifest=JSON.parse(fs.readFileSync(path.join(__dirname,'assets/data/native_warzone_tech.json'),'utf8'));
const initialTech=U.initialZones(techManifest);
let meta=S.normalizeSave({campaignStars:0,campaignProgress:{},campaignBestRating:{},campaignSecretUnlocks:{},campaignCompletedZones:{},campaignCompletionEarned:{},warzoneTech:initialTech},{campaignStars:0,warzoneTech:initialTech});
const rows=z=>battles.filter(b=>new RegExp(`^campaign${z}_[0-9]+\\.btl$`).test(b.file)).sort((a,b)=>a.file.localeCompare(b.file,undefined,{numeric:true}));
const progress=f=>S.progressLevel(meta,f), secret=f=>!!meta.campaignSecretUnlocks?.[f];
let battleSaveCycles=0,resultEvents=0,replays=0,upgrades=0,zoneRewards=0;
function persistMeta(times=2){for(let i=0;i<times;i++)meta=S.storageRoundTrip(meta,meta)}
function opportunisticUpgrade(zone){
  for(let id=0;id<U.TECH_COUNT;id++){const lv=U.techLevel(meta.warzoneTech,zone,id),cost=U.upgradeCost(id,lv);if(lv<U.MAX_TECH_LEVEL&&cost<=meta.campaignStars){const out=U.upgrade(meta.warzoneTech,meta.campaignStars,zone,id);if(out.ok){meta={...meta,warzoneTech:out.zones,campaignStars:out.stars};persistMeta(2);upgrades++;return{id,level:out.level}}}}
  return null;
}
function battleRoundTrip(b,zone,serial){
  const snap=meta.warzoneTech[String(zone)].slice();
  const sample={battle:b,map:zone===5?'america':'europe',mode:'campaign',playerOwner:0,round:Math.max(1,R.stageTurnLimits(b).best),resources:{money:100+serial,industry:30+serial,food:500-serial},countryResources:{'0':{money:100+serial,industry:30,food:500}},camera:{x:100+serial,y:200,zoom:.8},units:[{index:serial,army_name:'Line Infantry',owner:0,q:10,r:10,grade:0,trainingLevel:U.initialTrainingLevel(snap[1]),hp:120,max_hp:120}],objects:[],ownership:[],assignments:new Map([[serial,201]]),installations:[],fireCells:new Set([`${serial},1`]),nativeFiredEvents:new Set(['f'+serial]),nativeAppliedEvents:new Set(['a'+serial]),itemStores:{},taverns:{},collectMedal:serial%4,campaignTech:snap,campaignTechZone:zone,ended:null};
  let raw=BS.makePayload(sample);assert.equal(raw.schema,6);let restored=null;
  // Real lifecycle: JSON storage -> normalize on load -> runtime -> makePayload on next save.
  for(let i=0;i<4;i++){restored=BS.normalize(JSON.parse(JSON.stringify(raw)));battleSaveCycles++;raw=BS.makePayload({...restored,battle:b})}
  restored=BS.normalize(JSON.parse(JSON.stringify(raw)));assert.deepEqual(restored.campaignTech,snap);assert.equal(restored.campaignTechZone,zone);assert.equal(restored.units[0].trainingLevel,U.initialTrainingLevel(snap[1]));assert(restored.assignments instanceof Map);assert(restored.fireCells instanceof Set);assert(restored.nativeFiredEvents instanceof Set);assert(restored.nativeAppliedEvents instanceof Set);
}
function clearVisibleStage(zone,b,serial){
  const list=rows(zone),idx=list.findIndex(x=>x.file===b.file);assert(idx>=0);assert(C.stageSelectable(list,idx,progress,secret),`${b.file} must be selectable before clear`);
  const lim=R.stageTurnLimits(b);assert(lim.valid,`${b.file} needs native limits`);const best=R.result(lim.best,b,S.bestRating(meta,C.canonicalFile(b)));assert.equal(best.score,5);
  const before=meta.campaignStars,out=S.recordResult(meta,C.canonicalFile(b),best.score);meta=out.state;resultEvents++;assert(meta.campaignStars>=before);persistMeta(3);
  const afterBest=meta.campaignStars,poor=S.recordResult(meta,C.canonicalFile(b),1);meta=poor.state;replays++;assert.equal(meta.campaignStars,afterBest,'worse replay must never add Stars');assert.equal(S.bestRating(meta,C.canonicalFile(b)),5);persistMeta(2);
  battleRoundTrip(b,zone,serial);
}

let serial=1,expectedReward={medals:0,badges:0,score:0},visibleTotal=0;
for(let zone=1;zone<=6;zone++){
  const list=rows(zone),visible=list.filter(b=>!C.originalHide(b));visibleTotal+=visible.length;let zoneClears=0;
  for(const b of visible){clearVisibleStage(zone,b,serial++);zoneClears++;if(zoneClears===2)assert(opportunisticUpgrade(zone),'each zone must exercise at least one live tech purchase')}
  const last=visible[visible.length-1],decision=R.campaignContinueDecision(list,C.canonicalFile(last));assert(decision.valid&&decision.complete,`zone ${zone} final visible stage must complete campaign`);
  const reward=R.campaignCompletionReward(zone,false);expectedReward.medals+=reward.medal;expectedReward.badges+=reward.badge;expectedReward.score+=reward.score;
  let zr=S.recordZoneCompletion(meta,zone,reward);assert(zr.applied);meta=zr.state;zoneRewards++;persistMeta(3);
  zr=S.recordZoneCompletion(meta,zone,reward);assert(!zr.applied,'zone completion reward must be one-shot');meta=zr.state;persistMeta(2);
}
assert.equal(resultEvents,visibleTotal);assert.equal(replays,visibleTotal);assert.equal(battleSaveCycles,visibleTotal*4);assert.equal(upgrades,6);assert.equal(zoneRewards,6);
assert.equal(Object.keys(meta.campaignProgress).length,visibleTotal);assert(Object.values(meta.campaignBestRating).every(x=>x===5));assert.equal(Object.keys(meta.campaignCompletedZones).length,6);assert.deepEqual(meta.campaignCompletionEarned,expectedReward);
// A long quit/relaunch tail: 500 complete campaign-meta persistence cycles must be byte-stable as JSON.
const beforeFinal=JSON.stringify(meta);for(let i=0;i<500;i++)meta=S.storageRoundTrip(meta,meta);assert.equal(JSON.stringify(meta),beforeFinal);
console.log(`P25 six-zone long session: PASS (${visibleTotal} first clears + ${visibleTotal} replays, ${battleSaveCycles} battle save/load cycles, 500 meta reloads, 6 one-shot zone rewards)`);
