'use strict';
(function(root,factory){
  const achievement=(typeof module==='object'&&module.exports)?require('./native_achievement_core.js'):root.EW4NativeAchievement;
  const api=factory(achievement);
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeConquestAchievement=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(A){
  // x86_64 native source of truth: libeuropean-war-4.so function ~0x7e760.
  // Result record mapping is native map continent enum: europe=0, america=1;
  // the fast-conquest override stores index 2 (Asia achievement record).
  const NORMAL_THRESHOLDS=Object.freeze([91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16,1]);
  const ASIA_THRESHOLDS=Object.freeze([95,91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16]);
  const RULE_YEARS=Object.freeze([1000,950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,100,50]);
  const clamp=(v,lo,hi)=>Math.max(lo,Math.min(hi,Math.trunc(Number(v)||0)));
  const nonneg=v=>Math.max(0,Math.trunc(Number(v)||0));
  const truncDiv=(n,d)=>Math.trunc(n/d);

  function mapType(map){return String(map||'').toLowerCase()==='america'?1:0}
  function normalKey(map){return mapType(map)?'america':'europe'}
  function ownedStates(save,commanders){
    return A.ownedGeneralIds(save).map(id=>A.effectiveGeneralState(save,commanders,id));
  }
  function generalLevelContribution(save,commanders){
    // Native loops 12 original HQ slots and uses only rank/nobility LEVEL fields.
    // User mod removes that hard cap, so—as in P28 global Achievement summary—the
    // exact native per-general formula is deliberately extended to every owned HQ general.
    return ownedStates(save,commanders).reduce((sum,s)=>sum+
      10*(s.rank+1)*(s.rank+2)+25*(s.nobility+1)*(s.nobility+2),0);
  }
  function resourceContribution(resources){
    const r=resources||{},money=Math.trunc(Number(r.money)||0),industry=Math.trunc(Number(r.industry)||0),food=Math.trunc(Number(r.food)||0);
    return truncDiv(2*money+4*industry+food,10);
  }
  function campaignStarContribution(save,multiplier,cap){
    return Math.min(cap,A.campaignStageStars(save).earned*multiplier);
  }
  function normalRoundContribution(round){
    round=Math.trunc(Number(round)||0);
    if(round<=31)return 23330;
    if(round>99)return 0;
    let k=0;
    if(round<=45)k=4;
    else if(round<=55)k=3;
    else if(round<=65)k=2;
    else if(round<=75)k=1;
    const base=111*(100-round),factor=Math.fround(Math.fround(k)*Math.fround(0.5)+Math.fround(1));
    return Math.trunc(Math.fround(Math.fround(base)*factor));
  }
  function asiaRoundContribution(round,map){
    round=Math.trunc(Number(round)||0);const mt=mapType(map);
    if(round<=20)return 21000;
    if(round>99)return 0;
    let k=0;
    if(mt){ // america native continent enum 1
      if(round<=25)k=4;else if(round<=35)k=3;else if(round<=45)k=2;else if(round<=50)k=1;
    }else{ // europe native continent enum 0
      if(round<=30)k=4;else if(round<=40)k=3;else if(round<=50)k=2;else if(round<=60)k=1;
    }
    return 65*k*(100-round);
  }
  function yearsFromScore(normalized,thresholds,fallback){
    for(let i=0;i<thresholds.length;i++)if(normalized>=thresholds[i])return RULE_YEARS[i];
    return fallback;
  }
  function normalValue({round,map,resources,save,commanders}){
    const resource=resourceContribution(resources),hq=Math.min(6999,generalLevelContribution(save,commanders)),stage=Math.min(2333,A.campaignStageStars(save).earned*10),roundScore=normalRoundContribution(round);
    const total=resource+hq+stage+roundScore;
    // Native magic 0xb3c814e5 / sar15 is GCC signed division by 46660.
    const normalized=clamp(truncDiv(total*100,46660),1,100),value=yearsFromScore(normalized,NORMAL_THRESHOLDS,0);
    return{kind:normalKey(map),value,normalized,total,components:{resource,hq,stage,round:roundScore}};
  }
  function asiaValue({round,map,resources,save,commanders}){
    const resource=resourceContribution(resources),hq=Math.min(17500,generalLevelContribution(save,commanders)),stage=Math.min(7000,A.campaignStageStars(save).earned*17),roundScore=asiaRoundContribution(round,map);
    const total=resource+hq+stage+roundScore;
    // Native magic 0x5d9f7391 / sar8 is GCC signed division by 700.
    const normalized=Math.min(100,truncDiv(total,700)),value=yearsFromScore(normalized,ASIA_THRESHOLDS,10);
    return{kind:'asia',value,normalized,total,components:{resource,hq,stage,round:roundScore}};
  }
  function asiaEligible(round,map){
    round=Math.trunc(Number(round)||0);
    // Native helper ~0x7eee0/~0x7ef50: only after conquest victory; America <=55,
    // Europe <=65. Result-state victory gating is kept at the integration boundary.
    return round<=(mapType(map)?55:65);
  }
  function prepareVictory(save,commanders,context){
    if(!context||context.mode!=='conquest'||context.victory!==true)return null;
    const base={...context,save,commanders},normal=normalValue(base),eligible=asiaEligible(context.round,context.map);
    return{normal,asiaEligible:eligible,asia:eligible?asiaValue(base):null};
  }
  function resultForVictory(context){
    if(!context||context.mode!=='conquest'||context.victory!==true)return null;
    // Native 0x9f9e0 opens form_complete(group_challenge) for a fast win; the
    // player then chooses whether to keep the normal continent result or replace
    // it with the Asia challenge result. Return the ordinary pending record here.
    return normalValue(context);
  }
  function recordResult(save,result){
    if(!result||!['europe','america','asia'].includes(result.kind))return{save:Object.assign({},save||{}),changed:false,result:null};
    const rec=A.recordConquestValue(save,result.kind,result.value);
    return{save:rec.save,changed:rec.changed,result:{...result,storedValue:rec.value}};
  }
  function recordVictory(save,commanders,context){
    const prepared=prepareVictory(save,commanders,context);
    if(!prepared)return{save:Object.assign({},save||{}),changed:false,result:null,requiresChoice:false,prepared:null};
    if(prepared.asiaEligible)return{save:Object.assign({},save||{}),changed:false,result:prepared.normal,requiresChoice:true,prepared};
    const out=recordResult(save,prepared.normal);return{...out,requiresChoice:false,prepared};
  }
  return Object.freeze({NORMAL_THRESHOLDS,ASIA_THRESHOLDS,RULE_YEARS,mapType,normalKey,generalLevelContribution,resourceContribution,normalRoundContribution,asiaRoundContribution,normalValue,asiaValue,asiaEligible,prepareVictory,resultForVictory,recordResult,recordVictory});
});
