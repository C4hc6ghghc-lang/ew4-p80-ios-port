'use strict';
/* EW4 Web Port 0.61 combat core.
   Goals:
   1) preserve EW4's dice/formation damage structure;
   2) FIX the original lower-bound regression: lower attack is a real die floor;
   3) support native skill semantics used by player-enhanced generals;
   4) keep player-only +4/+4 isolated from AI units. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4Combat=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const PLAYER_ATTACK_INTERVAL_BONUS=4;
  const ATTACK_TACTIC_CHANCE=0.10;
  const DEFENSE_TACTIC_CHANCE=0.10;
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  const num=(v,d=0)=>Number.isFinite(+v)?+v:d;

  function normalizeInterval(min,max){
    let lo=num(min,0),hi=num(max,lo);
    if(hi<lo)hi=lo; // a valid lower-bound increase is NEVER deleted
    return {min:lo,max:hi};
  }

  function hasSkill(commander,id){
    if(!commander)return false;
    id=+id;
    const legacy=[commander.skill1,commander.skill2,commander.skill3,commander.skill4];
    const extended=Array.isArray(commander.skills)?commander.skills:[];
    return [...legacy,...extended].some(x=>+x===id);
  }

  function skillIntervalBonus(commander,statType){
    let lower=0,upper=0;
    // Native EW4 intent. The original game failed to use these lower floors correctly;
    // 0.61 intentionally repairs that regression.
    if(statType==='infantry'){
      if(hasSkill(commander,13))lower+=1; // Infantry Tactics
      if(hasSkill(commander,12))upper+=1; // Formation
    }else if(statType==='cavalry'){
      if(hasSkill(commander,11))lower+=1; // Maneuver
      if(hasSkill(commander,10))upper+=1; // Surprise
    }else if(statType==='artillery'){
      if(hasSkill(commander,7))lower+=1;  // Ballistics
      if(hasSkill(commander,8))upper+=1;  // Explosives
    }
    return {lower,upper};
  }

  function effectiveAttackInterval(opts={}){
    const isPlayer=!!opts.isPlayer;
    const baseMin=num(opts.min,1),baseMax=num(opts.max,baseMin);
    const flat=num(opts.flatBonus,0);
    const lower=num(opts.lowerBonus,0);
    const upper=num(opts.upperBonus,0);
    const player=isPlayer?PLAYER_ATTACK_INTERVAL_BONUS:0;
    return normalizeInterval(baseMin+flat+lower+player,baseMax+flat+upper+player);
  }

  function masteryBonus(commander,statType,isFort=false){
    if(!commander)return 0;
    if(isFort)return num(commander.fort,0);
    if(statType==='infantry')return num(commander.infantry,0);
    if(statType==='cavalry')return num(commander.cavalry,0);
    if(statType==='artillery')return num(commander.artillery,0);
    if(statType==='warship')return num(commander.warship,0);
    return 0;
  }

  function fullFormationCoefficient(unit){
    // grade 0/1/2 is EW4 single/double/triple formation.
    return clamp(5+Math.max(0,Math.min(2,Math.trunc(num(unit?.grade,0)))),5,7);
  }

  function formationCoefficient(unit,commander,statType){
    const full=fullFormationCoefficient(unit);
    if(unit?.forceFullFormation||(statType==='infantry'&&hasSkill(commander,15)))return full; // Snare Drum / Mass Fire
    const hp=Math.max(0,num(unit?.hp,0)),max=Math.max(1,num(unit?.max_hp,1));
    const r=hp/max;
    // Recovered EW4 HP breakpoints:
    // single: >=50/30/15/5% => 5/4/3/2, else 1
    // double adds coeff 6 above 65%; triple adds 7 above 80% and 6 above 65%.
    if(full>=7&&r>=0.80)return 7;
    if(full>=6&&r>=0.65)return 6;
    if(r>=0.50)return 5;
    if(r>=0.30)return 4;
    if(r>=0.15)return 3;
    if(r>=0.05)return 2;
    return 1;
  }

  function masteryCoefficient(unit,commander,statType){
    // EW4 commander-star damage decays with the same 50/30/15/5% breakpoints as a
    // single formation. Dense Attack (infantry) and Snare Drum preserve full output.
    if(unit?.forceFullFormation||(statType==='infantry'&&hasSkill(commander,15)))return 5;
    const hp=Math.max(0,num(unit?.hp,0)),max=Math.max(1,num(unit?.max_hp,1)),r=hp/max;
    if(r>=0.50)return 5;if(r>=0.30)return 4;if(r>=0.15)return 3;if(r>=0.05)return 2;return 1;
  }

  function rollInclusive(min,max,rng=Math.random){
    const lo=Math.ceil(num(min,0)),hi=Math.max(lo,Math.floor(num(max,lo)));
    const r=clamp(num(rng(),0),0,0.999999999999);
    return lo+Math.floor(r*(hi-lo+1));
  }

  function damageBounds({unit,stat,commander,isPlayer=false,isFort=false,fixedBonus=0,flatBonus=0,lowerBonus=0,upperBonus=0}={}){
    stat=stat||{};unit=unit||{};
    const s=skillIntervalBonus(commander,stat.type);
    const interval=effectiveAttackInterval({
      min:stat.minatk,max:stat.maxatk,isPlayer,
      flatBonus:num(flatBonus,0),
      lowerBonus:num(lowerBonus,0)+s.lower,
      upperBonus:num(upperBonus,0)+s.upper
    });
    const mastery=masteryBonus(commander,stat.type,isFort);
    const coeff=formationCoefficient(unit,commander,stat.type),masteryCoeff=masteryCoefficient(unit,commander,stat.type);
    // Commander-star contribution also loses tiers as HP falls. Equipment attack remains fixed.
    const fixed=Math.round(mastery*masteryCoeff+num(fixedBonus,0));
    const minDamage=Math.max(1,fixed+coeff*interval.min);
    const maxDamage=Math.max(minDamage,fixed+coeff*interval.max);
    return {min:minDamage,max:maxDamage,attackMin:interval.min,attackMax:interval.max,mastery,coefficient:coeff,masteryCoefficient:masteryCoeff,fixedBonus:num(fixedBonus,0),skillLower:s.lower,skillUpper:s.upper};
  }

  function rollDamage(args={},rng=Math.random,forceMax=false){
    const b=damageBounds(args);
    let dice=0;
    if(forceMax)dice=b.coefficient*b.attackMax;
    else for(let i=0;i<b.coefficient;i++)dice+=rollInclusive(b.attackMin,b.attackMax,rng);
    const fixed=b.mastery*b.masteryCoefficient+b.fixedBonus;
    const value=Math.max(1,Math.round(fixed+dice));
    return {...b,value};
  }

  function ignoresAvoidance(commander,statType){
    return statType==='infantry'?hasSkill(commander,14):
           statType==='cavalry'?hasSkill(commander,9):
           statType==='artillery'?hasSkill(commander,5):false;
  }

  function resolveDamage(opts={},rng=Math.random){
    const aStat=opts.attackerStat||opts.stat||{};
    const dStat=opts.defenderStat||{};
    const aCmd=opts.attackerCommander||opts.commander||null;
    const dCmd=opts.defenderCommander||null;
    const isCounter=!!opts.isCounter;

    // Attack Tactics only applies to the active attack, never to an off-turn counterattack.
    const attackTactic=hasSkill(aCmd,31)&&!isCounter&&rng()<ATTACK_TACTIC_CHANCE;
    const rolled=rollDamage({
      unit:opts.attacker||opts.unit,stat:aStat,commander:aCmd,
      isPlayer:!!opts.isPlayerAttacker,isFort:!!opts.attackerIsFort,
      fixedBonus:num(opts.fixedBonus,0),flatBonus:num(opts.flatBonus,0),
      lowerBonus:num(opts.lowerBonus,0),upperBonus:num(opts.upperBonus,0)
    },rng,attackTactic);

    let value=rolled.value;
    const notes=[];
    if(attackTactic)notes.push('attack-tactics');

    // Morale is a fixed modifier based on the current formation coefficient.
    // +1 morale => +k damage; -1/-2 => -k/-2k. Low defender morale increases incoming by k/2k.
    const aMorale=Math.trunc(num(opts.attackerMorale,0));
    const dMorale=Math.trunc(num(opts.defenderMorale,0));
    value+=aMorale*rolled.coefficient;
    if(dMorale<0)value+=(-dMorale)*rolled.coefficient;

    // Native unit training level contributes a flat defender-side subtraction before
    // subsequent multiplicative combat modifiers. Level 0..5 => 0/2/4/6/8/10.
    const trainingDefense=Math.max(0,Math.trunc(num(opts.defenderTrainingDefense,0)));
    if(trainingDefense>0){value=Math.max(1,value-trainingDefense);notes.push(`training-defense-${trainingDefense}`);}

    // Sailor cancels the 20% attack penalty for land units fighting while embarked.
    if(opts.attackerEmbarked&&aStat.type!=='warship'&&!hasSkill(aCmd,17)){
      value=Math.floor(value*0.8);notes.push('embarked-penalty');
    }

    // Spy: +50% against fortress-family units.
    if(opts.defenderIsFort&&hasSkill(aCmd,4)){
      value=Math.floor(value*1.5);notes.push('spy+50%');
    }

    // Terrain / field-work / building avoidance. Infantry/Cavalry/Artillery ignore skills
    // wipe the known avoidance layers; Siegecraft ignores building avoidance only.
    let terrain=Math.max(0,num(opts.terrainReduction,0));
    let installation=Math.max(0,num(opts.installationReduction,0));
    let building=Math.max(0,num(opts.buildingReduction,0));
    let country=Math.max(0,num(opts.countryReduction,0));
    if(ignoresAvoidance(aCmd,aStat.type)){
      terrain=installation=building=country=0;notes.push('ignore-avoidance');
    }else if(hasSkill(aCmd,29)&&building>0){
      building=0;notes.push('siegecraft');
    }
    // Native defense selector: a construction owns the cell's map-avoidance path.
    // Only a cell without a construction falls back to max(terrain, field installation).
    // This matters even for farmland (construction present, avoid=0): terrain is not added back in.
    const hasConstruction=!!opts.defenderHasConstruction;
    const mapReduction=hasConstruction?building:Math.max(terrain,installation);
    const totalReduction=clamp(mapReduction+country,0,95);
    if(totalReduction>0)value=Math.floor(value*(100-totalReduction)/100);

    // Helmsman: naval unit suffers 10% less damage.
    if(dStat.type==='warship'&&hasSkill(dCmd,16)){
      value=Math.floor(value*0.9);notes.push('helmsman-10%');
    }

    value=Math.max(1,Math.floor(value));

    // Defense Tactics only applies while defending against an active enemy attack.
    // In EW4 it does not trigger when the unit is taking a counterattack on its own turn.
    const defenseTactic=hasSkill(dCmd,32)&&!isCounter&&rng()<DEFENSE_TACTIC_CHANCE;
    if(defenseTactic){value=1;notes.push('defense-tactics');}

    return {...rolled,value,attackTactic,defenseTactic,totalReduction,notes};
  }

  return Object.freeze({
    PLAYER_ATTACK_INTERVAL_BONUS,ATTACK_TACTIC_CHANCE,DEFENSE_TACTIC_CHANCE,
    effectiveAttackInterval,skillIntervalBonus,damageBounds,rollDamage,resolveDamage,
    hasSkill,masteryBonus,masteryCoefficient,formationCoefficient,fullFormationCoefficient,ignoresAvoidance
  });
});
