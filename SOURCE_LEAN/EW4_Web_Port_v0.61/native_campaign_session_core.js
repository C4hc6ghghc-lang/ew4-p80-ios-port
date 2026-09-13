'use strict';
(function(root,factory){
  const upgrade=(typeof module==='object'&&module.exports)?require('./native_upgrade_core.js'):root.EW4NativeUpgrade;
  const api=factory(upgrade);
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeCampaignSession=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(U){
  const own=(o,k)=>!!o&&Object.prototype.hasOwnProperty.call(o,k);
  const obj=v=>v&&typeof v==='object'&&!Array.isArray(v)?v:{};
  const clampScore=v=>Math.max(0,Math.min(5,Math.trunc(+v||0)));
  const cloneObject=v=>Object.assign({},obj(v));
  function progressLevel(state,file){return Math.max(0,Math.trunc(+obj(state?.campaignProgress)[String(file||'')]||0))}
  function bestRating(state,file){
    file=String(file||'');const best=clampScore(obj(state?.campaignBestRating)[file]);if(best)return best;
    const legacy=progressLevel(state,file);return legacy>=2?5:legacy>=1?1:0;
  }
  function legacyStarTotal(raw){
    const best=obj(raw?.campaignBestRating),progress=obj(raw?.campaignProgress),keys=new Set([...Object.keys(best),...Object.keys(progress)]);let total=0;
    for(const file of keys){let v=clampScore(best[file]);if(!v){const p=Math.max(0,+progress[file]||0);v=p>=2?5:p>=1?1:0}total+=v}
    return U?.clampStars?U.clampStars(total):Math.max(0,Math.min(999,Math.trunc(total)))
  }
  // Normalize only campaign-meta fields. `source` is the original persisted object so
  // pre-P21 saves can be distinguished from a defaultSave() object that already has Stars.
  function normalizeSave(state,source=state){
    const out=Object.assign({},state||{}),src=source||{};
    out.campaignProgress=cloneObject(out.campaignProgress);
    out.campaignBestRating=cloneObject(out.campaignBestRating);
    out.campaignSecretUnlocks=cloneObject(out.campaignSecretUnlocks);
    out.campaignCompletedZones=cloneObject(out.campaignCompletedZones);
    const earned=obj(out.campaignCompletionEarned);out.campaignCompletionEarned={medals:Math.max(0,Math.trunc(+earned.medals||0)),badges:Math.max(0,Math.trunc(+earned.badges||0)),score:Math.max(0,Math.trunc(+earned.score||0))};
    out.campaignStars=own(src,'campaignStars')?(U?.clampStars?U.clampStars(out.campaignStars):Math.max(0,Math.min(999,Math.trunc(+out.campaignStars||0)))):legacyStarTotal(src);
    out.warzoneTech=own(src,'warzoneTech')&&out.warzoneTech&&typeof out.warzoneTech==='object'&&!Array.isArray(out.warzoneTech)?out.warzoneTech:null;
    return out;
  }
  function recordResult(state,file,rating){
    file=String(file||'');if(!file)return{state:Object.assign({},state||{}),changed:false,delta:0,oldBest:0,next:0};
    const oldBest=bestRating(state,file),next=Math.max(1,clampScore(rating)||1),award=U.awardScoreDelta(state?.campaignStars,oldBest,next),out=Object.assign({},state||{});
    out.campaignProgress=cloneObject(state?.campaignProgress);out.campaignBestRating=cloneObject(state?.campaignBestRating);out.campaignStars=award.stars;
    out.campaignProgress[file]=Math.max(1,progressLevel(state,file));if(next>oldBest)out.campaignBestRating[file]=next;
    return{state:out,changed:next>oldBest||progressLevel(state,file)<1,delta:award.delta,oldBest,next};
  }
  function zoneCompleted(state,zone){return !!obj(state?.campaignCompletedZones)[String(Math.max(1,Math.min(6,Math.trunc(+zone||1))))]}
  function recordZoneCompletion(state,zone,reward){
    zone=Math.max(1,Math.min(6,Math.trunc(+zone||1)));if(zoneCompleted(state,zone))return{state:Object.assign({},state||{}),applied:false};
    const out=Object.assign({},state||{}),earned=obj(state?.campaignCompletionEarned);out.campaignCompletedZones=cloneObject(state?.campaignCompletedZones);out.campaignCompletedZones[String(zone)]=true;
    out.campaignCompletionEarned={medals:Math.max(0,Math.trunc(+earned.medals||0))+Math.max(0,Math.trunc(+reward?.medal||0)),badges:Math.max(0,Math.trunc(+earned.badges||0))+Math.max(0,Math.trunc(+reward?.badge||0)),score:Math.max(0,Math.trunc(+earned.score||0))+Math.max(0,Math.trunc(+reward?.score||0))};
    return{state:out,applied:true};
  }
  function storageRoundTrip(state,source=state){return normalizeSave(JSON.parse(JSON.stringify(state||{})),source)}
  return Object.freeze({progressLevel,bestRating,legacyStarTotal,normalizeSave,recordResult,zoneCompleted,recordZoneCompletion,storageRoundTrip});
});
