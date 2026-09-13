(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeGeneral=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const MILITARY_THRESHOLDS=Object.freeze([500,800,1200,1900,3000,4800,7500,12000,19000,30000,48000,76000,120000,200000]);
  const NOBILITY_THRESHOLDS=Object.freeze([100,200,300,450,675,1000,1500,2250,3375]);
  const MILITARY_RETENTION=Object.freeze([100,97,94,91,88,85,82,79,76,73,70,67,64,61,58]);
  const NOBILITY_RETENTION=Object.freeze([100,96,92,88,84,80,76,72,68,64]);
  const MILITARY_MEDAL_RATE=0.008;
  const NOBILITY_MEDAL_RATE=0.2;
  const ALL_FULL_MEDAL_CAP=3600;
  const MILITARY_MAX=MILITARY_THRESHOLDS.length;
  const NOBILITY_MAX=NOBILITY_THRESHOLDS.length;
  // Commander skill ids are stored zero-based in EW4 data. 33..39 display as skill 34..40.
  const TEACHING_SKILLS=Object.freeze({33:'infantry',34:'cavalry',35:'artillery',36:'warship',37:'fort',38:'business',39:'movement'});
  // Native battle-growth skill ids are zero-based: skill 20/21/22 in UI => 19/20/21.
  const NOBILITY_GROWTH_SKILL=19;
  const MILITARY_GROWTH_EXPERT_SKILL=20;
  const MILITARY_GROWTH_MASTER_SKILL=21;
  const NOBILITY_SKILL_MULTIPLIER=1.5;
  const MILITARY_EXPERT_MULTIPLIER=1.4;
  const MILITARY_MASTER_MULTIPLIER=1.8;
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,Number.isFinite(+v)?Math.trunc(+v):a));
  const nonneg=v=>Math.max(0,Number.isFinite(+v)?Math.trunc(+v):0);

  function normalizeGrowth(level,progress,thresholds){
    level=clamp(level,0,thresholds.length);progress=nonneg(progress);
    while(level<thresholds.length&&progress>=thresholds[level]){progress-=thresholds[level];level++}
    if(level>=thresholds.length)progress=0;
    return{level,progress};
  }
  function nextMilitaryCost(rank,progress){
    rank=clamp(rank,0,MILITARY_MAX);if(rank>=MILITARY_MAX)return 0;
    return Math.ceil(Math.max(0,MILITARY_THRESHOLDS[rank]-nonneg(progress))*MILITARY_MEDAL_RATE);
  }
  function nextNobilityCost(level,progress){
    level=clamp(level,0,NOBILITY_MAX);if(level>=NOBILITY_MAX)return 0;
    return Math.ceil(Math.max(0,NOBILITY_THRESHOLDS[level]-nonneg(progress))*NOBILITY_MEDAL_RATE);
  }
  function remainingRaw(level,progress,thresholds){
    level=clamp(level,0,thresholds.length);if(level>=thresholds.length)return 0;
    let raw=-nonneg(progress);for(let i=level;i<thresholds.length;i++)raw+=thresholds[i];return Math.max(0,raw)
  }
  function allFullCost(rank,militaryProgress,nobility,nobilityProgress){
    const military=Math.ceil(remainingRaw(rank,militaryProgress,MILITARY_THRESHOLDS)*MILITARY_MEDAL_RATE);
    const noble=Math.ceil(remainingRaw(nobility,nobilityProgress,NOBILITY_THRESHOLDS)*NOBILITY_MEDAL_RATE);
    return Math.min(ALL_FULL_MEDAL_CAP,military+noble);
  }
  function addMilitaryProgress(rank,progress,amount){return normalizeGrowth(rank,nonneg(progress)+nonneg(amount),MILITARY_THRESHOLDS)}
  function addNobilityProgress(level,progress,amount){return normalizeGrowth(level,nonneg(progress)+nonneg(amount),NOBILITY_THRESHOLDS)}
  function militaryFull(rank){return{level:MILITARY_MAX,progress:0}}
  function nobilityFull(level){return{level:NOBILITY_MAX,progress:0}}
  function allFull(){return{rank:MILITARY_MAX,militaryProgress:0,nobility:NOBILITY_MAX,nobilityProgress:0}}

  function completedProgress(level,progress,thresholds,base){
    level=clamp(level,0,thresholds.length);let total=base+nonneg(progress);for(let i=0;i<level;i++)total+=thresholds[i];return total
  }
  function militaryTransfer(rank,progress){
    rank=clamp(rank,0,MILITARY_MAX);const pct=MILITARY_RETENTION[Math.min(rank,MILITARY_RETENTION.length-1)]??0;
    return Math.floor(completedProgress(rank,progress,MILITARY_THRESHOLDS,300)*pct/100)
  }
  function nobilityTransfer(level,progress){
    level=clamp(level,0,NOBILITY_MAX);const pct=NOBILITY_RETENTION[Math.min(level,NOBILITY_RETENTION.length-1)]??0;
    return Math.floor(completedProgress(level,progress,NOBILITY_THRESHOLDS,60)*pct/100)
  }
  function skillList(g){
    if(Array.isArray(g?.skills))return g.skills.map(Number).filter(Number.isFinite);
    return [g?.skill1,g?.skill2,g?.skill3,g?.skill4].map(Number).filter(x=>Number.isFinite(x)&&x>=0)
  }
  function teachingBonuses(source){
    const out={};for(const id of skillList(source)){const stat=TEACHING_SKILLS[id];if(stat)out[stat]=(out[stat]||0)+1}return out
  }
  function regroupPreview(target,source){
    if(!target||!source)throw new Error('target/source required');
    const tr=clamp(target.rank,0,MILITARY_MAX),tp=nonneg(target.militaryProgress),tn=clamp(target.nobility??target.nobilityrank,0,NOBILITY_MAX),tnp=nonneg(target.nobilityProgress);
    const sr=clamp(source.rank,0,MILITARY_MAX),sp=nonneg(source.militaryProgress),sn=clamp(source.nobility??source.nobilityrank,0,NOBILITY_MAX),snp=nonneg(source.nobilityProgress);
    const milGain=militaryTransfer(sr,sp),nobGain=nobilityTransfer(sn,snp);
    const m=addMilitaryProgress(tr,tp,milGain),n=addNobilityProgress(tn,tnp,nobGain),bonus=teachingBonuses(source);
    const stats={};for(const stat of ['infantry','cavalry','artillery','warship','fort','business','movement','training'])stats[stat]=Math.max(0,Number.isFinite(+target[stat])?+target[stat]:0);
    for(const [stat,inc] of Object.entries(bonus))if(stats[stat]<5)stats[stat]=Math.min(5,stats[stat]+inc);
    return{rank:m.level,militaryProgress:m.progress,nobility:n.level,nobilityProgress:n.progress,stats,militaryGain:milGain,nobilityGain:nobGain,teachingBonuses:bonus,sourceDeleted:true,sourceItemsDisappear:true}
  }
  function regroupCommit(target,source){return regroupPreview(target,source)}

  function equipmentGrowthMultiplier(kind,items){
    const fn=kind==='military'?2:kind==='nobility'?1:null;if(fn===null)return null;let best=null;
    for(const it of (Array.isArray(items)?items:[])){if(!it||+it.function!==fn)continue;const mult=Math.max(0,(+it.value||0)/100);if(best===null||mult>best)best=mult}
    return best
  }
  function skillGrowthMultiplier(kind,skills){
    const ids=new Set((Array.isArray(skills)?skills:[]).map(Number));
    if(kind==='nobility')return ids.has(NOBILITY_GROWTH_SKILL)?NOBILITY_SKILL_MULTIPLIER:1;
    if(kind==='military'){if(ids.has(MILITARY_GROWTH_MASTER_SKILL))return MILITARY_MASTER_MULTIPLIER;if(ids.has(MILITARY_GROWTH_EXPERT_SKILL))return MILITARY_EXPERT_MULTIPLIER}
    return 1
  }
  function growthMultiplier(kind,{items=[],skills=[]}={}){const eq=equipmentGrowthMultiplier(kind,items);return eq===null?skillGrowthMultiplier(kind,skills):eq}
  function battleMilitaryGain(damage,context={}){const base=Math.max(0,Number.isFinite(+damage)?+damage:0)*2;return Math.floor(base*growthMultiplier('military',context))}
  function battleNobilityGain(victimGrade,victimHasCommander,context={}){const grade=Math.max(0,Number.isFinite(+victimGrade)?Math.trunc(+victimGrade):0),base=(grade+1)*(victimHasCommander?2:1);return Math.floor(base*growthMultiplier('nobility',context))}

  return{MILITARY_THRESHOLDS,NOBILITY_THRESHOLDS,MILITARY_RETENTION,NOBILITY_RETENTION,MILITARY_MEDAL_RATE,NOBILITY_MEDAL_RATE,ALL_FULL_MEDAL_CAP,MILITARY_MAX,NOBILITY_MAX,TEACHING_SKILLS,NOBILITY_GROWTH_SKILL,MILITARY_GROWTH_EXPERT_SKILL,MILITARY_GROWTH_MASTER_SKILL,NOBILITY_SKILL_MULTIPLIER,MILITARY_EXPERT_MULTIPLIER,MILITARY_MASTER_MULTIPLIER,nextMilitaryCost,nextNobilityCost,allFullCost,addMilitaryProgress,addNobilityProgress,militaryFull,nobilityFull,allFull,militaryTransfer,nobilityTransfer,teachingBonuses,regroupPreview,regroupCommit,equipmentGrowthMultiplier,skillGrowthMultiplier,growthMultiplier,battleMilitaryGain,battleNobilityGain};
});
