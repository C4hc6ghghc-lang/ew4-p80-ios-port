'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const app=fs.readFileSync(path.join(__dirname,'app.js'),'utf8');
const unitRules=require('./player_unit_rules.js');
const combat=require('./combat_core.js');
const princess=require('./assets/data/player_princess_overrides.json');
const commanders=require('./assets/data/commanders.json');
// Numeric baseline used by the original-style UI paths.
assert.strictEqual(unitRules.effectiveBaseHp(80,true),200,'player line-infantry base HP shown by recruit UI should include +120');
assert.deepStrictEqual(combat.effectiveAttackInterval({min:1,max:7,isPlayer:true}),{min:5,max:11},'player recruit attack display should include +4/+4');
assert.strictEqual(unitRules.effectiveMovement(6,'infantry',true),8);
// Existing battle-unit UI must read live effective values, not raw APK values.
assert(app.includes("{kind:'text',value:`${Math.max(0,Math.round(u.hp))}/${Math.max(1,Math.round(u.max_hp))}`,title:'生命'}"));
assert(app.includes('atk=attackInterval(u)'));
assert(app.includes("{kind:'text',value:String(effectiveMovePoints(u)),title:'移动'}"));
// Recruit form must use player effective HP/attack/movement.
assert(app.includes('EW4PlayerUnitRules.effectiveBaseHp(+st.strength||0,true)'));
assert(app.includes('EW4Combat.effectiveAttackInterval({min:+st.minatk||0,max:+st.maxatk||0,isPlayer:true})'));
assert(app.includes('EW4PlayerUnitRules.effectiveMovement(+st.movement||0,st.type,true)'));
// Commander information and in-battle commander information resolve the player-effective commander.
assert(app.includes('const ec=effectiveCommander(c,true)'));
assert(app.includes('const c=effectiveCommanderForUnit(u)'));
// Raw princess records remain original; overrides are layered separately.
assert.strictEqual(commanders['208'].infantry,3);assert.strictEqual(princess.princesses['208'].stats.infantry,5);
assert.strictEqual(commanders['204'].artillery,3);assert.strictEqual(princess.princesses['204'].stats.artillery,5);
assert.strictEqual(commanders['205'].movement,4);assert.strictEqual(princess.princesses['205'].stats.movement,7);
console.log('effective UI contract PASS: battle/recruit/general display paths consume effective values; original raw data remains untouched');
