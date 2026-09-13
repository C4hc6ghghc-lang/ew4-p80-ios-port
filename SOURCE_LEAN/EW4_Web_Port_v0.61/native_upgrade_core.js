(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeUpgrade=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const MAX_STARS=999;
  const MAX_TECH_LEVEL=3;
  const TECH_COUNT=26;
  const VISIBLE_TECH_COUNT=22;
  const PAGE_TECH_IDS=Object.freeze([
    Object.freeze([0,1,2,3,4,5]),Object.freeze([6,7,8,9]),Object.freeze([10,11,12,13]),
    Object.freeze([14,15,16,17]),Object.freeze([18,19,20,21])
  ]);
  const TECH_NAMES=Object.freeze([
    'Militia','Line Infantry','Light Infantry','Grenadier','Guards','Machine Gun',
    'Light Cavalry','Heavy Cavalry','Guards Cavalry','Armored Car',
    'Light Artillery','Heavy Artillery','Siege Artillery','Rocket',
    'Privateer','Frigate','Battleship','Ironclad',
    'Small Fortress','Fortress','Large Fortress','Coastal Fort',
    'Farm','Financial','Factory','Dock'
  ]);
  const TECH_COSTS=Object.freeze([
    [0,3,6,12],[1,4,7,13],[2,5,8,14],[3,6,9,15],[4,7,10,16],[8,9,12,18],
    [0,4,8,15],[3,6,10,17],[6,8,12,19],[9,10,14,21],
    [0,5,10,18],[4,7,12,20],[7,9,14,22],[10,11,16,24],
    [0,6,12,21],[5,8,14,23],[8,10,16,25],[11,12,18,27],
    [0,12,18,22],[6,15,20,25],[12,20,25,30],[0,10,16,20],
    [0,8,16,24],[0,15,25,35],[0,12,20,30],[0,8,12,16]
  ].map(Object.freeze));
  const UNIT_TECH_IDS=Object.freeze(Object.fromEntries(TECH_NAMES.slice(0,18).map((n,i)=>[n,i])));
  const FORT_TECH_IDS=Object.freeze(Object.fromEntries(TECH_NAMES.slice(18,22).map((n,i)=>[n,i+18])));
  const clampInt=(v,a,b)=>Math.max(a,Math.min(b,Number.isFinite(+v)?Math.trunc(+v):a));
  const clampStars=v=>clampInt(v,0,MAX_STARS);
  const clampLevel=v=>clampInt(v,-1,MAX_TECH_LEVEL);
  function displayLevel(level){return clampInt(clampLevel(level)+1,0,4)}
  function pageTechIds(page){return PAGE_TECH_IDS[clampInt(page,0,PAGE_TECH_IDS.length-1)]||PAGE_TECH_IDS[0]}
  function techName(id){return TECH_NAMES[clampInt(id,0,TECH_COUNT-1)]||''}
  function techIdForArmy(name){return Object.prototype.hasOwnProperty.call(UNIT_TECH_IDS,String(name))?UNIT_TECH_IDS[String(name)]:null}
  function techIdForFort(name){return Object.prototype.hasOwnProperty.call(FORT_TECH_IDS,String(name))?FORT_TECH_IDS[String(name)]:null}
  function initialZones(manifest){
    const rows=Array.isArray(manifest?.zones)?manifest.zones:[];const out={};
    for(let z=0;z<6;z++){const raw=rows.find(x=>+x.id===z)?.levels;out[String(z+1)]=Array.from({length:TECH_COUNT},(_,i)=>clampLevel(raw?.[i]??0))}
    return out
  }
  function normalizeZones(state,manifest){
    const base=initialZones(manifest),src=state&&typeof state==='object'?state:{};const out={};
    for(let z=1;z<=6;z++){const raw=Array.isArray(src[String(z)])?src[String(z)]:base[String(z)];out[String(z)]=Array.from({length:TECH_COUNT},(_,i)=>clampLevel(raw?.[i]??base[String(z)][i]))}
    return out
  }
  function techLevel(zones,zone,id){const row=zones?.[String(clampInt(zone,1,6))];return clampLevel(row?.[clampInt(id,0,TECH_COUNT-1)]??-1)}
  function upgradeCost(id,currentLevel){id=clampInt(id,0,TECH_COUNT-1);currentLevel=clampLevel(currentLevel);if(currentLevel>=MAX_TECH_LEVEL)return 0;return TECH_COSTS[id][currentLevel+1]??0}
  function canUpgrade(stars,id,currentLevel){currentLevel=clampLevel(currentLevel);if(currentLevel>=MAX_TECH_LEVEL)return false;return clampStars(stars)>=upgradeCost(id,currentLevel)}
  function upgrade(zones,stars,zone,id){
    zone=clampInt(zone,1,6);id=clampInt(id,0,TECH_COUNT-1);const current=techLevel(zones,zone,id),cost=upgradeCost(id,current);
    if(current>=MAX_TECH_LEVEL)return{ok:false,reason:'max',zones,stars:clampStars(stars),cost:0,level:current};
    if(clampStars(stars)<cost)return{ok:false,reason:'stars',zones,stars:clampStars(stars),cost,level:current};
    const next=normalizeZones(zones,{zones:Array.from({length:6},(_,i)=>({id:i,levels:zones?.[String(i+1)]||Array(26).fill(0)}))});
    next[String(zone)][id]=current+1;
    return{ok:true,zones:next,stars:clampStars(stars-cost),cost,level:current+1,displayLevel:displayLevel(current+1)}
  }
  function nativeScoreDelta(oldBest,newScore){oldBest=clampInt(oldBest,0,5);newScore=clampInt(newScore,0,5);return Math.max(0,newScore-oldBest)}
  function awardScoreDelta(stars,oldBest,newScore){const delta=nativeScoreDelta(oldBest,newScore);return{stars:clampStars(clampStars(stars)+delta),delta}}
  function initialTrainingLevel(level){level=clampLevel(level);return level>0?level:0}
  function recruitAllowed(level){return clampLevel(level)>=0}
  function economicBonus(level,kind){level=clampInt(level,0,3);if(kind==='money')return [0,20,40,60][level];if(kind==='industry'||kind==='food')return [0,10,20,30][level];return 0}
  function zoneEconomicBonuses(zones,zone){return{
    food:economicBonus(techLevel(zones,zone,22),'food'),money:economicBonus(techLevel(zones,zone,23),'money'),industry:economicBonus(techLevel(zones,zone,24),'industry')
  }}
  function armyClass(name){
    const id=techIdForArmy(name);if(id==null)return null;if(id<=5)return'infantry';if(id<=9)return'cavalry';if(id<=13)return'artillery';if(id<=17)return'navy';return null
  }
  function canEmbarkArmy(name,dockLevel){dockLevel=clampLevel(dockLevel);const c=armyClass(name);if(c==='infantry')return dockLevel>=1;if(c==='cavalry')return dockLevel>=2;if(c==='artillery')return dockLevel>=3;if(c==='navy')return true;return false}
  return Object.freeze({MAX_STARS,MAX_TECH_LEVEL,TECH_COUNT,VISIBLE_TECH_COUNT,PAGE_TECH_IDS,TECH_NAMES,TECH_COSTS,UNIT_TECH_IDS,FORT_TECH_IDS,displayLevel,pageTechIds,techName,techIdForArmy,techIdForFort,initialZones,normalizeZones,techLevel,upgradeCost,canUpgrade,upgrade,nativeScoreDelta,awardScoreDelta,initialTrainingLevel,recruitAllowed,economicBonus,zoneEconomicBonuses,armyClass,canEmbarkArmy,clampStars});
});
