'use strict';
(function(root,factory){
  const general=(typeof module==='object'&&module.exports)?require('./native_general_core.js'):root.EW4NativeGeneral;
  const api=factory(general);
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeAchievement=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(General){
  const MILITARY_THRESHOLDS=Object.freeze([...(General?.MILITARY_THRESHOLDS||[500,800,1200,1900,3000,4800,7500,12000,19000,30000,48000,76000,120000,200000])]);
  const NOBILITY_THRESHOLDS=Object.freeze([...(General?.NOBILITY_THRESHOLDS||[100,200,300,450,675,1000,1500,2250,3375])]);
  const STAGE_COUNTS=Object.freeze([18,17,15,13,11,10]);
  const MAX_STAGE_STARS=STAGE_COUNTS.reduce((a,n)=>a+n*5,0); // native: 84 stages * 5 = 420
  const obj=v=>v&&typeof v==='object'&&!Array.isArray(v)?v:{};
  const clamp=(v,lo,hi)=>Math.max(lo,Math.min(hi,Math.trunc(+v||0)));
  const nonneg=v=>Math.max(0,Math.trunc(+v||0));
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o||{},k);

  function ownedGeneralIds(save,maxId=208){
    const seen=new Set(),out=[];
    for(const raw of Array.isArray(save?.owned)?save.owned:[]){
      const id=Math.trunc(+raw||0);if(id<1||id>maxId||seen.has(id))continue;seen.add(id);out.push(id);
    }
    return out;
  }
  function commanderLookup(commanders,id){
    if(!commanders)return null;
    if(Array.isArray(commanders))return commanders.find(c=>+c?.id===+id)||null;
    return commanders[String(id)]||commanders[id]||null;
  }
  function effectiveGeneralState(save,commanders,id){
    const c=commanderLookup(commanders,id)||{};
    const ranks=obj(save?.rank),nobs=obj(save?.nobility),rprog=obj(save?.rankProgress),nprog=obj(save?.nobilityProgress);
    return{
      id,
      rank:clamp(own(ranks,id)?ranks[id]:(c.rank??0),0,MILITARY_THRESHOLDS.length),
      rankProgress:nonneg(rprog[id]),
      nobility:clamp(own(nobs,id)?nobs[id]:(c.nobilityrank??c.nobility??0),0,NOBILITY_THRESHOLDS.length),
      nobilityProgress:nonneg(nprog[id])
    };
  }
  function completedRaw(level,progress,thresholds,base){
    level=clamp(level,0,thresholds.length);let total=base+nonneg(progress);for(let i=0;i<level;i++)total+=thresholds[i];return total;
  }
  function rawMilitary(state){return completedRaw(state?.rank,state?.rankProgress,MILITARY_THRESHOLDS,300)}
  function rawNobility(state){return completedRaw(state?.nobility,state?.nobilityProgress,NOBILITY_THRESHOLDS,60)}
  function nativeFloatThresholdNext(threshold,multiplier){
    return Math.trunc(Math.fround(Math.fround(threshold)*Math.fround(multiplier)));
  }
  function aggregateLevel(total,{cutoff,first,multiplier}){
    total=nonneg(total);if(total<=cutoff)return 1;
    let level=2,threshold=first;
    while(level<99&&total>=threshold){threshold=nativeFloatThresholdNext(threshold,multiplier);level++}
    return level;
  }
  function globalSummary(save,commanders){
    // Native EW4 iterates the original 12 HQ slots. This port deliberately removes
    // the general-cap mod, so the same native per-general/raw/global formulas are
    // extended across every owned HQ general instead of silently ignoring slot 13+.
    const states=ownedGeneralIds(save).map(id=>effectiveGeneralState(save,commanders,id));
    const militaryRaw=states.reduce((a,s)=>a+rawMilitary(s),0),nobilityRaw=states.reduce((a,s)=>a+rawNobility(s),0);
    return{
      military:{level:aggregateLevel(militaryRaw,{cutoff:99,first:121,multiplier:1.214}),score:Math.floor(militaryRaw/10),raw:militaryRaw},
      nobility:{level:aggregateLevel(nobilityRaw,{cutoff:49,first:56,multiplier:1.125}),score:nobilityRaw*4,raw:nobilityRaw},
      countedGenerals:states.length
    };
  }
  function legacyBestRating(save,file){
    const best=obj(save?.campaignBestRating),progress=obj(save?.campaignProgress);
    if(own(best,file))return clamp(best[file],0,5);
    const p=clamp(progress[file],0,2);return p>=2?5:p>=1?1:0;
  }
  function campaignStageStars(save){
    let earned=0;
    for(let z=1;z<=STAGE_COUNTS.length;z++)for(let s=1;s<=STAGE_COUNTS[z-1];s++)earned+=legacyBestRating(save,`campaign${z}_${String(s).padStart(2,'0')}.btl`);
    return{earned:clamp(earned,0,MAX_STAGE_STARS),max:MAX_STAGE_STARS};
  }
  function continentStoredValue(save,key){
    const r=obj(save?.achievementConquests)[key];
    if(Number.isFinite(+r))return clamp(r,0,1000);
    if(r&&typeof r==='object'){
      if(Number.isFinite(+r.value))return clamp(r.value,0,1000);
      // Compatibility with the conservative P27 shape; only migrate its rendered
      // digits, never the invented separate `year` field.
      if(Array.isArray(r.rule)&&r.rule.length){let n=0;for(const d of r.rule.slice(0,3))n=n*10+clamp(d,0,9);return clamp(n,0,1000)}
    }
    return 0;
  }
  function ruleDigits(value){
    const n=clamp(value,0,999);return String(n).split('').map(x=>+x);
  }
  function continent(save,key){
    const stored=continentStoredValue(save,key),display=Math.min(999,stored);
    return{value:stored,display,digits:ruleDigits(display)};
  }
  function recordConquestValue(save,key,value){
    if(!['europe','america','asia'].includes(key))throw new Error('invalid continent');
    const next=Object.assign({},save),records=Object.assign({},obj(save?.achievementConquests)),old=continentStoredValue(save,key),v=clamp(value,0,1000);
    if(v>old)records[key]={value:v};next.achievementConquests=records;return{save:next,changed:v>old,value:Math.max(old,v)};
  }
  function viewModel(save,commanders){
    const summary=globalSummary(save,commanders);
    return{
      stageStars:campaignStageStars(save),
      walletStars:clamp(save?.campaignStars,0,999),
      military:summary.military,
      nobility:summary.nobility,
      countedGenerals:summary.countedGenerals,
      continents:{europe:continent(save,'europe'),america:continent(save,'america'),asia:continent(save,'asia')},
      generalIds:ownedGeneralIds(save)
    };
  }
  return Object.freeze({MILITARY_THRESHOLDS,NOBILITY_THRESHOLDS,STAGE_COUNTS,MAX_STAGE_STARS,ownedGeneralIds,effectiveGeneralState,rawMilitary,rawNobility,aggregateLevel,globalSummary,campaignStageStars,continentStoredValue,ruleDigits,continent,recordConquestValue,viewModel});
});
