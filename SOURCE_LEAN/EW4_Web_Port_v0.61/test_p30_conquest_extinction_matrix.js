'use strict';
const fs=require('fs'),assert=require('assert'),C=require('./native_conquest_extinction_core.js'),T=require('./country_turn_core.js');
const D=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json')),A=JSON.parse(fs.readFileSync('assets/data/army_stats.json'));
let cases=0;
for(const b of D.battles.filter(x=>/^conquest[1-6]\.btl$/.test(String(x.file)))){
  const type=u=>{const code=b.countries?.find(c=>+c.index===+u.owner)?.code||'fra',key=`${u.army_name}|${u.grade}`;return A[code]?.[key]?.type||Object.values(A).find(x=>x[key])?.[key]?.type||'infantry'};
  for(const pc of b.countries){const player=+pc.index;if(T.hint(b,player)===4)continue;
    const relation=(a,z)=>T.relation(b,a,z,{mode:'conquest',playerOwner:player});
    const base={battle:b,units:b.units.map(u=>({...u,hp:+u.hp||+u.max_hp||100,dead:false})),objects:b.objects.map(o=>({...o}))};
    const hostiles=C.hostileOwners(base,player,relation);if(!hostiles.length)continue;
    // Kill/capture every hostile country's survival assets but deliberately leave warships and forts alive.
    const state=JSON.parse(JSON.stringify(base));
    for(const u of state.units)if(hostiles.includes(+u.owner)&&C.LAND_ARMY_TYPES.has(type(u))){u.dead=true;u.hp=0}
    for(const o of state.objects)if(hostiles.includes(+o.owner)&&C.isCountedFacility(o))o.owner=player;
    const out=C.outcome(state,{playerOwner:player,unitType:type,relation});assert(out&&out.kind==='victory',`${b.file} player ${player} must win when every hostile power meets extinction contract`);
    // Reopen one hostile port: victory must disappear even if that nation's land army is gone.
    const target=hostiles.find(h=>base.objects.some(o=>+o.owner===h&&o.construction_type==='port'));
    if(target!=null){const port=base.objects.find(o=>+o.owner===target&&o.construction_type==='port');const copy=JSON.parse(JSON.stringify(state));const q=copy.objects.find(o=>+o.index===+port.index);q.owner=target;assert.equal(C.outcome(copy,{playerOwner:player,unitType:type,relation}),null,`${b.file} owner ${target} surviving port must block victory`)}
    // Player itself: remove player land army + facilities, leave any navy alive; must be defeat.
    const lose=JSON.parse(JSON.stringify(base));for(const u of lose.units)if(+u.owner===player&&C.LAND_ARMY_TYPES.has(type(u))){u.dead=true;u.hp=0}for(const o of lose.objects)if(+o.owner===player&&C.isCountedFacility(o))o.owner=hostiles[0];const loss=C.outcome(lose,{playerOwner:player,unitType:type,relation});assert(loss&&loss.kind==='defeat',`${b.file} player ${player} extinction must lose regardless of navy`);
    cases++;
  }
}
assert(cases>=60,`expected broad country matrix, got ${cases}`);
console.log('P30 conquest extinction all-country matrix PASS',{cases});
