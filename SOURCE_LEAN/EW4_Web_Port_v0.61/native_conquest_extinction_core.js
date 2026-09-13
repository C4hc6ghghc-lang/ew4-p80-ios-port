'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeConquestExtinction=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const LAND_ARMY_TYPES=new Set(['infantry','cavalry','artillery']);
  const LAND_FACILITY_TYPES=new Set(['city','industry','stable','farmland']);
  const PORT_TYPE='port';
  function ownerOf(x){return x?.owner==null?255:+x.owner}
  function alive(u){return !!u&&!u.dead&&(+u.hp||0)>0}
  function typeOf(u,unitType){const t=typeof unitType==='function'?unitType(u):u?.type;return String(t||'').toLowerCase()}
  function isLandArmy(u,unitType){return alive(u)&&LAND_ARMY_TYPES.has(typeOf(u,unitType))}
  function isCountedFacility(o){return !!o&&!!o.construction_type&&(LAND_FACILITY_TYPES.has(String(o.construction_type))||String(o.construction_type)===PORT_TYPE)}
  function countryStatus(state,owner,unitType){
    owner=+owner;
    const units=state?.units||[],objects=state?.objects||[];
    const landArmyAlive=units.some(u=>ownerOf(u)===owner&&isLandArmy(u,unitType));
    const landFacilitiesHeld=objects.some(o=>ownerOf(o)===owner&&LAND_FACILITY_TYPES.has(String(o?.construction_type||'')));
    const portsHeld=objects.some(o=>ownerOf(o)===owner&&String(o?.construction_type||'')===PORT_TYPE);
    return{owner,landArmyAlive,landFacilitiesHeld,portsHeld,defeated:!landArmyAlive&&!landFacilitiesHeld&&!portsHeld};
  }
  function ownerCandidates(state){
    const out=new Set();
    for(const c of state?.battle?.countries||[])if(c?.index!=null&&+c.index!==255)out.add(+c.index);
    for(const u of state?.units||[])if(ownerOf(u)!==255)out.add(ownerOf(u));
    for(const o of state?.objects||[])if(isCountedFacility(o)&&ownerOf(o)!==255)out.add(ownerOf(o));
    return [...out].sort((a,b)=>a-b);
  }
  function defeatedOwners(state,unitType){return ownerCandidates(state).filter(o=>countryStatus(state,o,unitType).defeated)}
  function hostileOwners(state,playerOwner,relation){
    return ownerCandidates(state).filter(owner=>owner!==+playerOwner&&typeof relation==='function'&&relation(+playerOwner,owner)==='hostile');
  }
  function outcome(state,{playerOwner=0,unitType,relation}={}){
    if(!state)return null;
    const player=countryStatus(state,+playerOwner,unitType);
    if(player.defeated)return{kind:'defeat',reason:'country-extinction',owner:+playerOwner,status:player};
    const hostile=hostileOwners(state,+playerOwner,relation);
    if(hostile.length&&hostile.every(o=>countryStatus(state,o,unitType).defeated))return{kind:'victory',reason:'hostile-powers-extinct',owners:hostile};
    return null;
  }
  return{LAND_ARMY_TYPES,LAND_FACILITY_TYPES,PORT_TYPE,isLandArmy,isCountedFacility,countryStatus,ownerCandidates,defeatedOwners,hostileOwners,outcome};
});
