const assert=require('assert');
const C=require('./combat_core.js');
const eq=(a,b,m)=>assert.deepStrictEqual(a,b,m);
const rngSeq=(arr,def=.5)=>()=>arr.length?arr.shift():def;

// 0.61 global player-only panel interval bonus.
eq(C.effectiveAttackInterval({min:1,max:7,isPlayer:false}),{min:1,max:7});
eq(C.effectiveAttackInterval({min:1,max:7,isPlayer:true}),{min:5,max:11});
// Lower-bound repair: the floor is real and cannot be erased by clamping.
eq(C.effectiveAttackInterval({min:1,max:7,lowerBonus:4}),{min:5,max:7});
eq(C.effectiveAttackInterval({min:4,max:6,lowerBonus:5}),{min:9,max:9});

// Native skill panel intent, with formerly-broken lower skills now functional.
eq(C.skillIntervalBonus({skills:[13]},'infantry'),{lower:1,upper:0});
eq(C.skillIntervalBonus({skills:[12]},'infantry'),{lower:0,upper:1});
eq(C.skillIntervalBonus({skills:[11,10]},'cavalry'),{lower:1,upper:1});
eq(C.skillIntervalBonus({skills:[7,8]},'artillery'),{lower:1,upper:1});

// EW4 formation / HP coefficient ladder.
assert.strictEqual(C.formationCoefficient({grade:0,hp:100,max_hp:100},null,'infantry'),5);
assert.strictEqual(C.formationCoefficient({grade:1,hp:70,max_hp:100},null,'infantry'),6);
assert.strictEqual(C.formationCoefficient({grade:1,hp:55,max_hp:100},null,'infantry'),5);
assert.strictEqual(C.formationCoefficient({grade:2,hp:85,max_hp:100},null,'infantry'),7);
assert.strictEqual(C.formationCoefficient({grade:2,hp:70,max_hp:100},null,'infantry'),6);
assert.strictEqual(C.formationCoefficient({grade:2,hp:40,max_hp:100},null,'infantry'),4);
assert.strictEqual(C.formationCoefficient({grade:2,hp:10,max_hp:100},null,'infantry'),2);
assert.strictEqual(C.formationCoefficient({grade:2,hp:1,max_hp:100},null,'infantry'),1);
// Dense Attack / Mass Fire holds the full coefficient at low HP.
assert.strictEqual(C.formationCoefficient({grade:2,hp:1,max_hp:100},{skills:[15]},'infantry'),7);

// Native dice structure: 3-star infantry + single 1-7 = 20..50.
let b=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:{infantry:3}});
assert.strictEqual(b.min,20);assert.strictEqual(b.max,50);assert.strictEqual(b.coefficient,5);
// Player +4/+4 shifts every attack die: 40..70.
b=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:{infantry:3},isPlayer:true});
assert.strictEqual(b.min,40);assert.strictEqual(b.max,70);
// Fixed weapon equipment is added once, not multiplied by formation coefficient.
b=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:{infantry:3},fixedBonus:6});
assert.strictEqual(b.min,26);assert.strictEqual(b.max,56);
// Infantry Tactics lower +1 is now real: minimum rises by coefficient (5).
b=C.damageBounds({unit:{grade:0,hp:100,max_hp:100},stat:{type:'infantry',minatk:1,maxatk:7},commander:{infantry:3,skills:[13]}});
assert.strictEqual(b.min,25);assert.strictEqual(b.max,50);

// Attack Tactics: active attack proc forces theoretical max.
let r=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:1,maxatk:7},attackerCommander:{infantry:3,skills:[31]}},rngSeq([.05]));
assert.strictEqual(r.attackTactic,true);assert.strictEqual(r.value,r.max);
// Counterattack must not proc Attack Tactics.
r=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:1,maxatk:7},attackerCommander:{infantry:3,skills:[31]},isCounter:true},()=>.05);
assert.strictEqual(r.attackTactic,false);

// Defense Tactics: active enemy attack can collapse damage to 1.
r=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:1,maxatk:7},defenderStat:{type:'infantry'},defenderCommander:{skills:[32]}},rngSeq([.5,.5,.5,.5,.5,.05]));
assert.strictEqual(r.defenseTactic,true);assert.strictEqual(r.value,1);
// Defense Tactics does not proc against a counterattack on the unit's own turn.
r=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:1,maxatk:7},defenderStat:{type:'infantry'},defenderCommander:{skills:[32]},isCounter:true},()=>.05);
assert.strictEqual(r.defenseTactic,false);

// Spy +50% against fortifications.
const noSpy=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:5,maxatk:5},attackerCommander:{infantry:0},defenderStat:{type:'fort'},defenderIsFort:true},()=>.5);
const spy=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:5,maxatk:5},attackerCommander:{infantry:0,skills:[4]},defenderStat:{type:'fort'},defenderIsFort:true},()=>.5);
assert.strictEqual(spy.value,Math.floor(noSpy.value*1.5));
// Bug-fixed class ignore skill wipes known map/building avoidance.
r=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'infantry',minatk:5,maxatk:5},attackerCommander:{skills:[14]},defenderStat:{type:'infantry'},terrainReduction:20,buildingReduction:20},()=>.5);
assert.strictEqual(r.totalReduction,0);
// Helmsman reduces incoming naval damage by 10%.
const navalBase=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'warship',minatk:10,maxatk:10},defenderStat:{type:'warship'}},()=>.5);
const helm=C.resolveDamage({attacker:{grade:0,hp:100,max_hp:100},attackerStat:{type:'warship',minatk:10,maxatk:10},defenderStat:{type:'warship'},defenderCommander:{skills:[16]}},()=>.5);
assert.strictEqual(helm.value,Math.floor(navalBase.value*.9));


// Commander-star fixed contribution must decay with low HP too.
{
  const u={grade:0,hp:40,max_hp:100}, c={infantry:3,skills:[]}, st={type:'infantry',minatk:1,maxatk:7};
  const b=C.damageBounds({unit:u,stat:st,commander:c});
  assert.equal(b.coefficient,4); assert.equal(b.masteryCoefficient,4); assert.equal(b.min,16); assert.equal(b.max,40);
}
// Dense Attack / Snare Drum preserve both formation dice and commander-star coefficient.
{
  const st={type:'infantry',minatk:1,maxatk:7};
  let b=C.damageBounds({unit:{grade:0,hp:20,max_hp:100},stat:st,commander:{infantry:3,skills:[15]}});
  assert.equal(b.coefficient,5); assert.equal(b.masteryCoefficient,5); assert.equal(b.min,20); assert.equal(b.max,50);
  b=C.damageBounds({unit:{grade:0,hp:20,max_hp:100,forceFullFormation:true},stat:st,commander:{infantry:3,skills:[]}});
  assert.equal(b.coefficient,5); assert.equal(b.masteryCoefficient,5); assert.equal(b.min,20); assert.equal(b.max,50);
}
console.log('combat_core 0.61 native-skill tests: PASS');
