'use strict';
const fs=require('fs'),assert=require('assert'),C=require('./native_conquest_extinction_core.js');
const D=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8')),A=JSON.parse(fs.readFileSync('assets/data/army_stats.json','utf8'));
const b=D.battles.find(x=>x.file==='conquest1.btl');assert(b,'conquest1');
function unitType(u){const code=b.countries?.find(c=>+c.index===+u.owner)?.code||'fra',key=`${u.army_name}|${u.grade}`;return A[code]?.[key]?.type||Object.values(A).find(x=>x[key])?.[key]?.type||'infantry'}
const byOwner=new Map();for(const u of b.units){const t=unitType(u);if(!byOwner.has(+u.owner))byOwner.set(+u.owner,new Set);byOwner.get(+u.owner).add(t)}
const owner=[...byOwner].find(([o,t])=>t.has('warship')&&([...t].some(x=>C.LAND_ARMY_TYPES.has(x))))?.[0];assert(owner!=null,'need a real conquest power with land army + navy');
const units=b.units.map(u=>({...u,hp:+u.hp||+u.max_hp||100,dead:false})),objects=b.objects.map(o=>({...o})),state={battle:b,units,objects};
assert.equal(C.countryStatus(state,owner,unitType).defeated,false,'real nation starts alive');
let navy=0,land=0;for(const u of units){if(+u.owner!==+owner)continue;const t=unitType(u);if(C.LAND_ARMY_TYPES.has(t)){u.dead=true;u.hp=0;land++}else if(t==='warship')navy++}
assert(land>0&&navy>0);
for(const o of objects)if(+o.owner===+owner&&C.isCountedFacility(o))o.owner=0===owner?1:0;
const x=C.countryStatus(state,owner,unitType);assert.equal(x.defeated,true);assert.equal(units.some(u=>+u.owner===+owner&&!u.dead&&unitType(u)==='warship'),true,'navy intentionally remains alive');
const roundtrip=JSON.parse(JSON.stringify(state));assert.equal(C.countryStatus(roundtrip,owner,unitType).defeated,true,'defeat must reconstruct from saved battlefield facts without a new save schema');
console.log('P30 real conquest extinction + navy-remnant + JSON reconstruction PASS',{owner,land,navy});
for(const bx of D.battles.filter(x=>/^conquest[1-6]\.btl$/.test(String(x.file)))){
  const utype=u=>{const code=bx.countries?.find(c=>+c.index===+u.owner)?.code||'fra',key=`${u.army_name}|${u.grade}`;return A[code]?.[key]?.type||Object.values(A).find(x=>x[key])?.[key]?.type||'infantry'};
  const live={battle:bx,units:bx.units.map(u=>({...u,hp:+u.hp||+u.max_hp||100,dead:false})),objects:bx.objects.map(o=>({...o}))};
  assert.deepStrictEqual(C.defeatedOwners(live,utype),[],`${bx.file} must not start with a falsely extinct country`);
}
