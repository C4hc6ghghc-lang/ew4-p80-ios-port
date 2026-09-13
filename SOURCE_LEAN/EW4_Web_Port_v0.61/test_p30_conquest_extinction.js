'use strict';
const assert=require('assert');
const C=require('./native_conquest_extinction_core.js');
const type=u=>u.type;
const rel=(a,b)=>a===b?'ally':(new Set([a,b]).has(2)?'neutral':'hostile');
function st(units=[],objects=[]){return{battle:{countries:[{index:0},{index:1},{index:2}]},units,objects}}
let s=st([
 {owner:0,type:'infantry',hp:10},{owner:1,type:'warship',hp:100},{owner:1,type:'fort',hp:100},{owner:2,type:'infantry',hp:10}
],[{owner:1,construction_type:'city'},{owner:1,construction_type:'port'},{owner:2,construction_type:'city'}]);
let x=C.countryStatus(s,1,type);assert.equal(x.defeated,false);assert.equal(x.landArmyAlive,false);assert.equal(x.landFacilitiesHeld,true);assert.equal(x.portsHeld,true);
// Navy and fort do not preserve national survival once all counted land facilities/ports are lost.
s.objects=s.objects.filter(o=>o.owner!==1);x=C.countryStatus(s,1,type);assert.equal(x.defeated,true);assert.equal(x.landArmyAlive,false);assert.equal(x.landFacilitiesHeld,false);assert.equal(x.portsHeld,false);
// A surviving port alone prevents extinction.
s.objects.push({owner:1,construction_type:'port'});assert.equal(C.countryStatus(s,1,type).defeated,false);
// A surviving non-port land facility alone also prevents extinction.
s.objects=[{owner:1,construction_type:'farmland'}];assert.equal(C.countryStatus(s,1,type).defeated,false);
// A living artillery unit is land army and prevents extinction without facilities.
s.objects=[];s.units.push({owner:1,type:'artillery',hp:1});assert.equal(C.countryStatus(s,1,type).defeated,false);
s.units.at(-1).dead=true;assert.equal(C.countryStatus(s,1,type).defeated,true);
// Neutral owner never enters hostile victory requirements.
assert.deepStrictEqual(C.hostileOwners(s,0,rel),[1]);assert.equal(C.outcome(s,{playerOwner:0,unitType:type,relation:rel}).kind,'victory');
// Player can still have navy but is defeated if land army + all facilities + all ports are gone.
s.units=s.units.filter(u=>u.owner!==0);s.units.push({owner:0,type:'warship',hp:100});assert.equal(C.outcome(s,{playerOwner:0,unitType:type,relation:rel}).kind,'defeat');
// Unrelated construction_type=null objects never count as survival facilities.
s.objects=[{owner:0,construction_type:null}];assert.equal(C.countryStatus(s,0,type).defeated,true);
console.log('P30 conquest extinction core PASS');
