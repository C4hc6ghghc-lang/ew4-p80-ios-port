'use strict';
const assert=require('assert'),fs=require('fs'),C=require('./native_construction_core.js'),Combat=require('./combat_core.js');
const d=JSON.parse(fs.readFileSync('./assets/data/constructions.json','utf8'));
assert.deepStrictEqual(d.city.levels.map(x=>[x.tax,x.industry,x.food,x.supply,x.avoid]),[[3,0,0,1,3],[6,0,0,2,6],[12,0,0,4,9],[20,2,0,6,12],[30,4,0,8,15],[45,6,0,10,18],[60,8,0,12,20]]);
assert.deepStrictEqual(d.industry.levels.map(x=>[x.tax,x.industry,x.food,x.supply,x.avoid]),[[0,4,0,2,3],[0,8,0,4,6],[0,12,0,6,9],[0,16,0,8,12]]);
assert.deepStrictEqual(d.stable.levels.map(x=>[x.tax,x.industry,x.food,x.supply,x.avoid]),[[2,0,0,2,3],[4,0,0,4,6],[6,0,0,6,9]]);
assert.deepStrictEqual(d.port.levels.map(x=>[x.tax,x.industry,x.food,x.supply,x.avoid]),[[3,1,0,2,3],[6,2,0,4,6],[9,3,0,6,9]]);
assert.deepStrictEqual(d.farmland.levels.map(x=>[x.tax,x.industry,x.food,x.supply,x.avoid]),[[0,0,5,0,0],[0,0,15,0,0],[0,0,40,0,0]]);
assert.deepStrictEqual(C.summaryEntries(d.city.levels[4]).map(x=>[x.kind,x.value]),[['money',30],['industry',4],['all',15]]);
assert.deepStrictEqual(C.summaryEntries(d.farmland.levels[2]).map(x=>[x.kind,x.value]),[['food',40]]);
assert.equal(C.mapAvoidance({hasConstruction:true,constructionAvoid:15,terrainAvoid:30,installationAvoid:20}),15);
assert.equal(C.mapAvoidance({hasConstruction:true,constructionAvoid:0,terrainAvoid:30,installationAvoid:20}),0);
assert.equal(C.mapAvoidance({hasConstruction:false,constructionAvoid:0,terrainAvoid:30,installationAvoid:20}),30);

assert.deepStrictEqual(C.UPGRADE_COST,{city:{money:65,industry:0},industry:{money:60,industry:20},stable:{money:80,industry:5},port:{money:75,industry:10},farmland:{money:40,industry:0}});
for(const type of Object.keys(C.UPGRADE_COST)){
  const b=C.UPGRADE_COST[type];
  assert.deepStrictEqual(C.upgradeCost(type),{money:b.money,industry:b.industry,discount:false});
}
assert.deepStrictEqual(C.upgradeCost('city',{architecture:true}),{money:39,industry:0,discount:true});
assert.deepStrictEqual(C.upgradeCost('industry',{architecture:true}),{money:36,industry:12,discount:true});
assert.deepStrictEqual(C.upgradeCost('stable',{architecture:true}),{money:48,industry:3,discount:true});
assert.deepStrictEqual(C.upgradeCost('port',{architecture:true}),{money:45,industry:6,discount:true});
assert.deepStrictEqual(C.upgradeCost('farmland',{architecture:true}),{money:24,industry:0,discount:true});
assert.equal(C.upgradeCost('unknown'),null);
function resolved(opts){return Combat.resolveDamage({attackerStat:{type:'infantry'},defenderStat:{type:'infantry'},...opts},()=>0)}
assert.equal(resolved({terrainReduction:30,buildingReduction:15,installationReduction:20,defenderHasConstruction:true}).totalReduction,15);
assert.equal(resolved({terrainReduction:30,buildingReduction:0,installationReduction:20,defenderHasConstruction:false}).totalReduction,30);
assert.equal(resolved({terrainReduction:30,buildingReduction:0,installationReduction:20,defenderHasConstruction:true}).totalReduction,0);
console.log('native construction economy/UI/avoidance PASS');
