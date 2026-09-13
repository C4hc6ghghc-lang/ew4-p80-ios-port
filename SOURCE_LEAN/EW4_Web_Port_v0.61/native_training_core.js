'use strict';
/* Original EW4 in-battle unit training core.
   Recovered from libeuropean-war-4.so (x86_64) + original BTL/def_army data.
   This module intentionally contains only controller semantics that are directly evidenced. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeTraining=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const MAX_LEVEL=5;
  // Native .data @ 0x2271c0, six records x four int32.
  // defense, roundHeal, levelUpHeal, next/baseExp field.
  const LEVELS=Object.freeze([
    Object.freeze({level:0,defense:0,roundHeal:0,levelUpHeal:0,baseExp:0}),
    Object.freeze({level:1,defense:2,roundHeal:2,levelUpHeal:10,baseExp:100}),
    Object.freeze({level:2,defense:4,roundHeal:3,levelUpHeal:20,baseExp:150}),
    Object.freeze({level:3,defense:6,roundHeal:4,levelUpHeal:30,baseExp:220}),
    Object.freeze({level:4,defense:8,roundHeal:5,levelUpHeal:40,baseExp:300}),
    Object.freeze({level:5,defense:10,roundHeal:6,levelUpHeal:50,baseExp:400})
  ]);
  // Native gold table @ 0x1b5e50, indexed by current level for manual training.
  const GOLD_COST=Object.freeze([30,45,70,105,160]);
  const n=(v,d=0)=>Number.isFinite(+v)?+v:d;
  const level=v=>Math.max(0,Math.min(MAX_LEVEL,Math.trunc(n(v,0))));
  const row=v=>LEVELS[level(v)];
  function commanderTraining(commander){return Math.max(0,Math.trunc(n(commander?.training,0)))}
  function canManualTrain(unit,commander){
    const l=level(unit?.trainingLevel);
    return !!unit&&!unit.dead&&!!commander&&l<MAX_LEVEL&&commanderTraining(commander)>l;
  }
  function manualCost(unit,unitStat){
    const l=level(unit?.trainingLevel);
    if(l>=MAX_LEVEL)return null;
    return Object.freeze({money:GOLD_COST[l],industry:0,food:Math.max(0,Math.trunc(n(unitStat?.consumption,0)))*3});
  }
  function canAfford(resources,cost){
    return !!cost&&n(resources?.money,0)>=cost.money&&n(resources?.industry,0)>=cost.industry&&n(resources?.food,0)>=cost.food;
  }
  function levelUp(unit){
    if(!unit)return null;
    const before=level(unit.trainingLevel);if(before>=MAX_LEVEL)return null;
    const after=before+1,r=LEVELS[after],oldHp=Math.max(0,n(unit.hp,0)),maxHp=Math.max(0,n(unit.max_hp,oldHp));
    unit.trainingLevel=after;
    unit.hp=Math.min(maxHp,oldHp+r.levelUpHeal);
    return {before,after,heal:unit.hp-oldHp,defense:r.defense,roundHeal:r.roundHeal};
  }
  function manualTrain(unit,commander,unitStat,resources){
    if(!canManualTrain(unit,commander))return {ok:false,reason:'ineligible'};
    const cost=manualCost(unit,unitStat);if(!canAfford(resources,cost))return {ok:false,reason:'resources',cost};
    resources.money-=cost.money;resources.industry-=cost.industry;resources.food-=cost.food;
    const result=levelUp(unit);return {ok:true,cost,...result};
  }
  function defenseBonus(unit){return row(unit?.trainingLevel).defense}
  function roundHeal(unit){return row(unit?.trainingLevel).roundHeal}
  function levelUpHealFor(levelAfter){return row(levelAfter).levelUpHeal}
  function baseExpForLevel(levelValue){return row(levelValue).baseExp}
  // Native 0x523a0: threshold for *next* level. UnitDef type enum was proven in
  // the original parser at 0x7038b..0x70440: infantry=0,cavalry=1,artillery=2,warship=3,fort=4.
  // A commander pointer multiplies the threshold by 1.5; warships multiply it by 2.
  function nextExpThreshold(unit,{hasCommander=unit?.commander_id!=null,unitType=null}={}){
    const l=level(unit?.trainingLevel);if(l>=MAX_LEVEL)return null;
    let need=LEVELS[l+1].baseExp;
    if(hasCommander)need=Math.trunc(need*1.5);
    if(unitType==='warship'||unitType===3)need*=2;
    return need;
  }
  function awardExp(unit,amount,{hasCommander=unit?.commander_id!=null,unitType=null}={}){
    if(!unit)return {awarded:0,leveled:false};
    const awarded=Math.max(0,Math.trunc(n(amount,0)));
    unit.trainingExp=Math.max(0,Math.trunc(n(unit.trainingExp,0)))+awarded;
    const need=nextExpThreshold(unit,{hasCommander,unitType});
    if(need==null||unit.trainingExp<need)return {awarded,leveled:false,need,exp:unit.trainingExp};
    unit.trainingExp-=need;
    const up=levelUp(unit);
    return {awarded,leveled:!!up,need,exp:unit.trainingExp,...(up||{})};
  }
  function applyRoundHeal(unit){
    if(!unit||unit.dead)return 0;const h=roundHeal(unit);if(h<=0)return 0;
    const before=Math.max(0,n(unit.hp,0)),maxHp=Math.max(0,n(unit.max_hp,before));unit.hp=Math.min(maxHp,before+h);return unit.hp-before;
  }
  return Object.freeze({MAX_LEVEL,LEVELS,GOLD_COST,level,row,commanderTraining,canManualTrain,manualCost,canAfford,levelUp,manualTrain,defenseBonus,roundHeal,levelUpHealFor,baseExpForLevel,nextExpThreshold,awardExp,applyRoundHeal});
});
