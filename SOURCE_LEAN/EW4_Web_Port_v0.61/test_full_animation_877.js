const fs=require('fs'),assert=require('assert');
const anim=require('./native_animation_controller.js');
const pack=JSON.parse(fs.readFileSync('assets/data/native_animation_core877.json','utf8'));
const battles=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8'));
const READY=JSON.parse(fs.readFileSync('assets/data/unit_ready_manifest.json','utf8'));
assert.strictEqual(pack.unit_count,877);assert.strictEqual(pack.motion_count,3519);assert.strictEqual(Object.keys(pack.units).length,877);assert.strictEqual(Object.values(pack.units).reduce((n,u)=>n+u.motions.length,0),3519);
let chains=0;
for(const [name,u] of Object.entries(pack.units)){
  for(const direction of ['left','right']){
    const c=anim.buildAttackChain(pack,name,{direction,weapon:'',targetClass:'infantry'});assert(c.length>=2,name+' '+direction);assert(c[0].kind==='attack');assert(c.at(-1).kind==='ready');chains++;
  }
}
function readyKey(u,b){
 const fixed=['Privateer','Frigate','Battleship','Ironclad','Small Fortress','Fortress','Large Fortress','Coastal Fort']; if(fixed.includes(u.army_name)) return u.army_name;
 const g=Math.max(1,(u.grade||0)+1),cc=b.countries[u.owner]?.code||'fra'; const ck=`${u.army_name} ${cc} ${g}`; return READY[ck]?ck:`${u.army_name} ${g}`;
}
let total=0,miss=[];
for(const b of battles.battles)for(const u of b.units){total++;const k=readyKey(u,b);if(!pack.units[k])miss.push({battle:b.file,unit:u.index,key:k});}
assert.strictEqual(total,7407);assert.deepStrictEqual(miss,[]);
console.log(`full compact animation coverage PASS · ${pack.unit_count}/877 units · ${pack.motion_count}/3519 motions · ${chains}/1754 directional chains · ${total}/7407 battle units resolved`);
