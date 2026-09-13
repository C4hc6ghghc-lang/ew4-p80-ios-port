const assert=require('assert');
const R=require('./player_unit_rules.js');
assert.strictEqual(R.BASE_HP_BONUS,120);
assert.strictEqual(R.MOVEMENT_BONUS,2);
assert.strictEqual(R.effectiveBaseHp(80,false),80);
assert.strictEqual(R.effectiveBaseHp(80,true),200);
assert.strictEqual(R.effectiveMovement(6,'infantry',false),6);
assert.strictEqual(R.effectiveMovement(6,'infantry',true),8);
assert.strictEqual(R.effectiveMovement(3,'warship',true),5);
assert.strictEqual(R.effectiveMovement(0,'fort',true),0,'forts stay immobile');
const u={hp:70,max_hp:100};
R.applyBaseHp(u,true);assert.strictEqual(u.hp,190);assert.strictEqual(u.max_hp,220);assert.strictEqual(u.playerBaseHpBonus,120);
R.applyBaseHp(u,true);assert.strictEqual(u.hp,190);assert.strictEqual(u.max_hp,220,'must not double apply after save/reopen');
// Migration from the earlier r14-39 +40 save preserves absolute damage (30) and upgrades only the delta +80.
const old={hp:110,max_hp:140,playerBaseHpBonusApplied:true,playerBaseHpBonus:40};
R.applyBaseHp(old,true);assert.strictEqual(old.hp,190);assert.strictEqual(old.max_hp,220);assert.strictEqual(old.playerBaseHpBonus,120);
const ai={hp:70,max_hp:100};R.applyBaseHp(ai,false);assert.deepStrictEqual(ai,{hp:70,max_hp:100});
console.log('player unit rules PASS: attack +4/+4 lives in combat_core; HP +120; movement +2; old +40 saves migrate by delta; AI unchanged');
