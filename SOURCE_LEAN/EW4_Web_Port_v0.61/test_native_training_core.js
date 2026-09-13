'use strict';
const assert=require('assert');
const T=require('./native_training_core.js');
assert.deepStrictEqual(T.LEVELS.map(x=>[x.defense,x.roundHeal,x.levelUpHeal,x.baseExp]),[
 [0,0,0,0],[2,2,10,100],[4,3,20,150],[6,4,30,220],[8,5,40,300],[10,6,50,400]
]);
assert.deepStrictEqual([...T.GOLD_COST],[30,45,70,105,160]);
for(let l=0;l<5;l++){
 assert.equal(T.canManualTrain({trainingLevel:l},{training:l+1}),true);
 assert.equal(T.canManualTrain({trainingLevel:l},{training:l}),false);
}
assert.equal(T.canManualTrain({trainingLevel:5},{training:7}),false);
assert.deepStrictEqual(T.manualCost({trainingLevel:0},{consumption:5}),{money:30,industry:0,food:15});
assert.deepStrictEqual(T.manualCost({trainingLevel:4},{consumption:15}),{money:160,industry:0,food:45});
let u={trainingLevel:3,trainingExp:99,hp:620,max_hp:900},r={money:1000,industry:500,food:100};
let out=T.manualTrain(u,{training:5},{consumption:10},r);
assert.equal(out.ok,true);assert.equal(u.trainingLevel,4);assert.equal(u.trainingExp,99);assert.equal(u.hp,660);assert.deepStrictEqual(r,{money:895,industry:500,food:70});
u={trainingLevel:4,trainingExp:0,hp:890,max_hp:900};out=T.levelUp(u);assert.equal(u.hp,900);assert.equal(out.heal,10);assert.equal(u.max_hp,900);
assert.equal(T.defenseBonus({trainingLevel:5}),10);assert.equal(T.roundHeal({trainingLevel:5}),6);
u={trainingLevel:5,hp:895,max_hp:900};assert.equal(T.applyRoundHeal(u),5);assert.equal(u.hp,900);
assert.equal(T.nextExpThreshold({trainingLevel:0,commander_id:null},{hasCommander:false,unitType:'infantry'}),100);
assert.equal(T.nextExpThreshold({trainingLevel:0,commander_id:1},{hasCommander:true,unitType:'infantry'}),150);
assert.equal(T.nextExpThreshold({trainingLevel:0,commander_id:1},{hasCommander:true,unitType:'warship'}),300);
assert.equal(T.nextExpThreshold({trainingLevel:5}),null);

// Native combat EXP: damage amount is accumulated; at most one level is advanced per award call.
u={trainingLevel:0,trainingExp:90,hp:50,max_hp:100,commander_id:null};out=T.awardExp(u,15,{hasCommander:false,unitType:'infantry'});assert.equal(out.leveled,true);assert.equal(u.trainingLevel,1);assert.equal(u.trainingExp,5);assert.equal(u.hp,60);
u={trainingLevel:0,trainingExp:140,hp:50,max_hp:100,commander_id:9};out=T.awardExp(u,10,{hasCommander:true,unitType:'infantry'});assert.equal(out.leveled,true);assert.equal(u.trainingExp,0);
u={trainingLevel:0,trainingExp:290,hp:50,max_hp:100,commander_id:4};out=T.awardExp(u,10,{hasCommander:true,unitType:'warship'});assert.equal(out.leveled,true);assert.equal(u.trainingExp,0);
console.log('native training core PASS');
// Native BTL raw[20] contract: all 7407 shipped scenario units use only level 0..5.
const fs=require('fs'),path=require('path');
const runtime=JSON.parse(fs.readFileSync(path.join(__dirname,'assets/data/battles_runtime.json'),'utf8'));
let count=0,seen=new Set();for(const b of runtime.battles)for(const unit of b.units){assert(Array.isArray(unit.raw)&&unit.raw.length>20);const l=unit.raw[20];assert(l>=0&&l<=5);seen.add(l);count++;}
assert.equal(count,7407);assert.deepStrictEqual([...seen].sort((a,b)=>a-b),[0,1,2,3,4,5]);
