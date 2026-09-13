const assert=require('assert');
const fs=require('fs');
const C=require('./combat_core.js');
const commanders=JSON.parse(fs.readFileSync('./assets/data/commanders.json','utf8'));
const overrides=JSON.parse(fs.readFileSync('./assets/data/player_general_overrides.json','utf8'));
const baseSkills=c=>[c.skill1,c.skill2,c.skill3,c.skill4].map(Number).filter(x=>x>=0);
function effective(id){
  const c=commanders[String(id)],o=overrides.generals[String(id)];
  const x={...c,...(o?.stats||{})};
  x.skills=[...new Set([...baseSkills(c),...((o?.addSkills||[]).map(Number))])];
  return x;
}
const ids={Napoleon:1,Davout:2,Lannes:5,Massena:10,Suchet:11,Soult:26,Murat:30};
for(const [name,id] of Object.entries(ids)) assert.equal(effective(id).movement,7,`${name} movement`);
assert.equal(effective(ids.Napoleon).infantry,5);
assert.equal(effective(ids.Davout).cavalry,5);assert.equal(effective(ids.Davout).artillery,5);
assert.equal(effective(ids.Lannes).cavalry,5);
assert.equal(effective(ids.Massena).cavalry,5);assert.equal(effective(ids.Massena).artillery,5);
assert.equal(effective(ids.Suchet).infantry,5);
assert.equal(effective(ids.Soult).infantry,5);assert.equal(effective(ids.Soult).artillery,5);
assert.equal(effective(ids.Murat).cavalry,5);assert.equal(effective(ids.Murat).artillery,5);

// Every combat skill explicitly requested by the user must be present after dedupe.
const expected={
  1:[8,1,31,5,7,32,4,3],
  2:[10,11,3,32],
  5:[12,13,14,3,4,1,32],
  10:[12,14,15,33,5,6,7,8,35,9,11,34,31],
  11:[12,14,15,33,9,10,34,31],
  26:[3,13,14,1,32],
  30:[1,32,9,10,11,3]
};
for(const [id,list] of Object.entries(expected)){
  const e=effective(id);
  for(const skill of list) assert(C.hasSkill(e,skill),`general ${id} missing skill ${skill}`);
  assert.equal(new Set(e.skills).size,e.skills.length,`general ${id} duplicate skills`);
}

// The user-selected combat families must actually alter the repaired interval.
// Base 1-7 becomes player 5-11 before skill bonuses (+4/+4 player override).
let e=effective(1); // Napoleon infantry: infantry tactics lower +1, no formation unless original contains it
let i=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:e,isPlayer:true});
assert.equal(i.attackMin,6); // +4 player +1 Infantry Tactics
assert.equal(i.attackMax,11);

// Davout cavalry: Maneuver lower +1 and Surprise upper +1.
e=effective(2);i=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'cavalry',minatk:2,maxatk:8},commander:e,isPlayer:true});
assert.equal(i.attackMin,7);assert.equal(i.attackMax,13);

// Massena artillery: Ballistics lower +1 + Explosives upper +1.
e=effective(10);i=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'artillery',minatk:3,maxatk:9},commander:e,isPlayer:true});
assert.equal(i.attackMin,8);assert.equal(i.attackMax,14);

// AI copies must remain unmodified when base commander data is passed directly.
const aiNap=commanders['1'];
i=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:aiNap,isPlayer:false});
assert.equal(i.attackMin,2); // Napoleon already has Infantry Tactics in original data
assert.equal(i.attackMax,7);
assert.equal(aiNap.movement,3);

console.log('enhanced player-general combat regressions: PASS');
