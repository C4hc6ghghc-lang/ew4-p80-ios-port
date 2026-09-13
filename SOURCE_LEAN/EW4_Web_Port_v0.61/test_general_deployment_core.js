const assert=require('assert');
const G=require('./general_deployment_core.js');
function unit(index,owner,hp,max,commander=null,bonus=0){return{index,owner,hp,max_hp:max,commander_id:commander,playerCommanderHpBonus:bonus,dead:false}}
// Changing commanders preserves damage taken, not current HP percentage and never heals damage away.
{
  const u=unit(1,0,80,100,11,20); // base max 80, current damage 20
  G.preserveDamage(u,22,40);
  assert.strictEqual(u.commander_id,22);
  assert.strictEqual(u.playerCommanderHpBonus,40);
  assert.strictEqual(u.max_hp,120);
  assert.strictEqual(u.hp,100); // still exactly 20 damage
}
// Only the selected unit receives the requested general. If a stale/programmatic duplicate exists,
// the old carrier is cleared rather than permitting one general on two units.
{
  const units=[unit(1,0,70,100,7,0),unit(2,0,90,100,null,0),unit(3,1,100,100,7,0)];
  const out=G.assign(units,2,7,0,()=>30);
  assert.strictEqual(out,units[1]);
  assert.strictEqual(units[0].commander_id,null);
  assert.strictEqual(units[1].commander_id,7);
  assert.strictEqual(units[1].max_hp,130);
  assert.strictEqual(units[1].hp,120); // 10 damage preserved
  assert.strictEqual(units[2].commander_id,7); // enemy ownership is untouched
}
// Native deploy grid excludes commanders already deployed on another player unit, but may retain
// the target unit's current commander while editing that unit.
{
  const units=[unit(4,0,100,100,10),unit(5,0,100,100,20),unit(6,1,100,100,30)];
  assert.deepStrictEqual([...G.deployedIds(units,0)].sort((a,b)=>a-b),[10,20]);
  assert.deepStrictEqual([...G.deployedIds(units,0,4)].sort((a,b)=>a-b),[20]);
}
assert.strictEqual(G.assign([unit(1,1,100,100)],1,9,0,()=>0),null);
console.log('in-battle general deployment core PASS');
