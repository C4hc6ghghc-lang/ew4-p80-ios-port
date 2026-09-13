'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4BattleSave=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const SCHEMA=6;
  const LEGACY_SCHEMAS=new Set([1,2,3,4,5,6]);
  const TRANSIENT_UNIT_KEYS=new Set(['moveAnim','attackAnimStart','attackPoseUntil']);
  function cleanObject(src,dropKeys){
    const out={};
    for(const [k,v] of Object.entries(src||{})){
      if(dropKeys&&dropKeys.has(k))continue;
      if(typeof v==='function'||v===undefined)continue;
      if(v instanceof Map)out[k]=[...v.entries()];
      else if(v instanceof Set)out[k]=[...v.values()];
      else out[k]=v;
    }
    return out;
  }
  function makePayload(state){
    if(!state?.battle?.file)throw new Error('no active battle');
    return{
      schema:SCHEMA,
      gameVersion:61,
      savedAt:Date.now(),
      battleFile:state.battle.file,
      battleTitle:state.battle.title_cn||state.battle.name_cn||state.battle.file,
      map:state.map,
      mode:state.mode,
      playerOwner:+state.playerOwner,
      round:+state.round||1,
      resources:{...state.resources},
      countryResources:Object.fromEntries(Object.entries(state.countryResources||{}).map(([k,v])=>[String(+k),{money:+v?.money||0,industry:+v?.industry||0,food:+v?.food||0}])),
      camera:{x:+state.camera?.x||0,y:+state.camera?.y||0,zoom:+state.camera?.zoom||1},
      cameraGeometry:state.cameraGeometry||null,
      units:(state.units||[]).map(u=>cleanObject(u,TRANSIENT_UNIT_KEYS)),
      objects:(state.objects||[]).map(o=>cleanObject(o)),
      ownership:[...(state.ownership||[])],
      assignments:state.assignments instanceof Map?[...state.assignments.entries()]:(state.assignments||[]),
      installations:(state.installations||[]).map(x=>cleanObject(x)),
      fireCells:state.fireCells instanceof Set?[...state.fireCells]:[...(state.fireCells||[])],
      nativeFiredEvents:state.nativeFiredEvents instanceof Set?[...state.nativeFiredEvents]:[...(state.nativeFiredEvents||[])],
      nativeAppliedEvents:state.nativeAppliedEvents instanceof Set?[...state.nativeAppliedEvents]:[...(state.nativeAppliedEvents||[])],
      itemStores:state.itemStores&&typeof state.itemStores==='object'?JSON.parse(JSON.stringify(state.itemStores)):null,
      taverns:state.taverns&&typeof state.taverns==='object'?JSON.parse(JSON.stringify(state.taverns)):null,
      collectMedal:Math.max(0,Math.trunc(+state.collectMedal||0)),
      campaignTech:Array.isArray(state.campaignTech)?state.campaignTech.slice(0,26).map(v=>Math.max(-1,Math.min(3,Math.trunc(+v||0)))):null,
      campaignTechZone:Math.max(0,Math.min(6,Math.trunc(+state.campaignTechZone||0))),
      ended:state.ended||null
    };
  }
  function validate(p){
    return !!(p&&LEGACY_SCHEMAS.has(+p.schema)&&p.battleFile&&Array.isArray(p.units)&&Array.isArray(p.objects)&&Array.isArray(p.ownership));
  }
  function normalize(p){
    if(!validate(p))throw new Error('invalid battle save');
    return{
      ...p,
      playerOwner:+p.playerOwner,
      round:Math.max(1,+p.round||1),
      resources:{money:+p.resources?.money||0,industry:+p.resources?.industry||0,food:+p.resources?.food||0},
      countryResources:p.countryResources&&typeof p.countryResources==='object'?Object.fromEntries(Object.entries(p.countryResources).map(([k,v])=>[String(+k),{money:+v?.money||0,industry:+v?.industry||0,food:+v?.food||0}])):null,
      camera:{x:+p.camera?.x||0,y:+p.camera?.y||0,zoom:Math.max(.2,Math.min(1,+p.camera?.zoom||1))},
      assignments:p.assignments instanceof Map?new Map(p.assignments):new Map((p.assignments||[]).map(([a,b])=>[+a,+b])),
      fireCells:p.fireCells instanceof Set?new Set(p.fireCells):new Set(p.fireCells||[]),
      nativeFiredEvents:p.nativeFiredEvents instanceof Set?new Set(p.nativeFiredEvents):new Set(p.nativeFiredEvents||[]),
      nativeAppliedEvents:p.nativeAppliedEvents instanceof Set?new Set(p.nativeAppliedEvents):new Set(p.nativeAppliedEvents||[]),
      itemStores:p.itemStores&&typeof p.itemStores==='object'?JSON.parse(JSON.stringify(p.itemStores)):null,
      taverns:p.taverns&&typeof p.taverns==='object'?JSON.parse(JSON.stringify(p.taverns)):null,
      collectMedal:Math.max(0,Math.trunc(+p.collectMedal||0)),
      campaignTech:Array.isArray(p.campaignTech)?p.campaignTech.slice(0,26).map(v=>Math.max(-1,Math.min(3,Math.trunc(+v||0)))):null,
      campaignTechZone:Math.max(0,Math.min(6,Math.trunc(+p.campaignTechZone||0)))
    };
  }
  return{SCHEMA,makePayload,validate,normalize};
});
