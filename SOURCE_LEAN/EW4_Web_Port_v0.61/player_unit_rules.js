'use strict';
/* Player-only EW4 Web Port rule overrides.
   Presentation/controller behavior stays original; these only alter player-side battle numbers. */
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4PlayerUnitRules=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const BASE_HP_BONUS=120;
  const MOVEMENT_BONUS=2;

  function effectiveBaseHp(strength,isPlayer=false){
    return Math.max(1,+strength||1)+(isPlayer?BASE_HP_BONUS:0);
  }
  function effectiveMovement(movement,type,isPlayer=false){
    const base=Math.max(0,+movement||0);
    // Fort-family units are immobile in original EW4; a player movement override must not make them movable.
    return base+(isPlayer&&type!=='fort'?MOVEMENT_BONUS:0);
  }
  function applyBaseHp(unit,isPlayer=false){
    if(!unit||!isPlayer)return unit;
    // r14-39 previously used +40. Saves persist both the applied marker and the
    // actual bonus, so migrate by the delta instead of stacking +120 on top.
    const previous=unit.playerBaseHpBonusApplied?Math.max(0,+unit.playerBaseHpBonus||0):0;
    const delta=BASE_HP_BONUS-previous;
    unit.playerBaseHpBonusApplied=true;
    unit.playerBaseHpBonus=BASE_HP_BONUS;
    if(delta!==0){
      // Preserve absolute damage: a unit 30 HP below maximum stays 30 below the new maximum.
      unit.max_hp=Math.max(1,(+unit.max_hp||1)+delta);
      unit.hp=Math.max(0,(+unit.hp||0)+delta);
      if(unit.hp>unit.max_hp)unit.hp=unit.max_hp;
    }
    return unit;
  }
  return Object.freeze({BASE_HP_BONUS,MOVEMENT_BONUS,effectiveBaseHp,effectiveMovement,applyBaseHp});
});
