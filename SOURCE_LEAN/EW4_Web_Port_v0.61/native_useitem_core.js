(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeUseItem=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';

  // SceneUseItem native constructor inserts exactly item ids 11..15 in this order.
  const USE_ITEM_IDS=Object.freeze([11,12,13,14,15]);
  const FUNCTION_SPIRIT=6,FUNCTION_WINE=7,FUNCTION_MEDICAL=8;

  function fn(item){return Number(item?.function)}
  function isBattleConsumable(item){return !!item&&USE_ITEM_IDS.includes(Number(item.id))&&[FUNCTION_SPIRIT,FUNCTION_WINE,FUNCTION_MEDICAL].includes(fn(item))}
  function canUse(item,unit,currentMorale=0){
    if(!isBattleConsumable(item)||!unit||unit.dead)return false;
    const f=fn(item);
    if(f===FUNCTION_MEDICAL)return Number(unit.hp)<Number(unit.max_hp);
    if(f===FUNCTION_SPIRIT)return Number(currentMorale)<=0;
    if(f===FUNCTION_WINE)return Number(currentMorale)<0;
    return false;
  }
  function apply(item,unit,{round=1,currentMorale=0}={}){
    if(!canUse(item,unit,currentMorale))return{ok:false,reason:'unusable'};
    const f=fn(item),r=Math.max(1,Math.floor(Number(round)||1));
    if(f===FUNCTION_MEDICAL){
      const before=Math.max(0,Number(unit.hp)||0),max=Math.max(before,Number(unit.max_hp)||0),value=Math.max(0,Number(item.value)||0),after=Math.min(max,before+value);
      unit.hp=after;
      return{ok:true,kind:'heal',healed:after-before,hp:after,maxHp:max,sfx:'sfx_supply.wav',effect:'effect_recover'};
    }
    if(f===FUNCTION_SPIRIT){
      unit.nativeMoraleBase=1;
      unit.nativeMoraleUntilRound=r+3;
      return{ok:true,kind:'spirit',moraleBase:1,untilRound:r+3,sfx:'sfx_supply.wav',effect:'effect_recover'};
    }
    unit.nativeMoraleBase=0;
    unit.nativeMoraleUntilRound=r+3;
    return{ok:true,kind:'wine',moraleBase:0,untilRound:r+3,sfx:'sfx_supply.wav',effect:'effect_recover'};
  }
  return{USE_ITEM_IDS,FUNCTION_SPIRIT,FUNCTION_WINE,FUNCTION_MEDICAL,isBattleConsumable,canUse,apply};
});
