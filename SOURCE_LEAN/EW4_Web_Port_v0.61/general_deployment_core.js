'use strict';
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.EW4GeneralDeployment=api})(typeof self!=='undefined'?self:globalThis,function(){
  function preserveDamage(unit,nextCommanderId,nextBonus=0){
    if(!unit)return null;
    const oldBonus=Math.max(0,+unit.playerCommanderHpBonus||0);
    const oldMax=Math.max(1,+unit.max_hp||1),oldHp=Math.max(0,+unit.hp||0);
    const damage=Math.max(0,oldMax-oldHp),baseMax=Math.max(1,oldMax-oldBonus),bonus=Math.max(0,+nextBonus||0);
    unit.commander_id=nextCommanderId==null?null:+nextCommanderId;
    unit.playerCommanderHpBonus=bonus;
    unit.max_hp=baseMax+bonus;
    unit.hp=Math.max(0,Math.min(unit.max_hp,unit.max_hp-damage));
    return unit
  }
  function deployedIds(units,playerOwner,exceptUnitIndex=null){
    const out=new Set();for(const u of units||[]){if(!u||u.dead||+u.owner!==+playerOwner||u.commander_id==null)continue;if(exceptUnitIndex!=null&&+u.index===+exceptUnitIndex)continue;out.add(+u.commander_id)}return out
  }
  function assign(units,targetIndex,commanderId,playerOwner,bonusForCommander=()=>0){
    const target=(units||[]).find(u=>u&&!u.dead&&+u.index===+targetIndex&&+u.owner===+playerOwner);if(!target)return null;
    const cid=+commanderId;
    for(const u of units||[]){if(!u||u===target||u.dead||+u.owner!==+playerOwner)continue;if(+u.commander_id===cid)preserveDamage(u,null,0)}
    preserveDamage(target,cid,+bonusForCommander(cid,target)||0);return target
  }
  return{preserveDamage,deployedIds,assign}
});
