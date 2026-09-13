const assert=require('assert');const fs=require('fs');
const O=JSON.parse(fs.readFileSync('assets/data/player_general_overrides.json','utf8'));
const expected={
  1:{movement:7,infantry:5},2:{movement:7,cavalry:5,artillery:5},5:{movement:7,cavalry:5},
  10:{movement:7,cavalry:5,artillery:5},11:{movement:7,infantry:5},26:{movement:7,infantry:5,artillery:5},30:{movement:7,cavalry:5,artillery:5}
};
for(const [id,stats] of Object.entries(expected))for(const [k,v] of Object.entries(stats))assert.strictEqual(O.generals[id].stats[k],v,`${id} ${k}`);
assert.strictEqual(O.generals['1'].rankHpBonusCap,1000);assert.strictEqual(O.generals['1'].nobilityHealCap,100);
for(const id of ['2','5','10','11','26','30']){assert.ok(!O.generals[id].rankHpBonusCap);assert.ok(!O.generals[id].nobilityHealCap)}
for(const [id,g] of Object.entries(O.generals)){assert.strictEqual(new Set(g.addSkills).size,g.addSkills.length,`duplicate skill in ${id}`)}
console.log('player_general_overrides 0.61 tests: PASS');
