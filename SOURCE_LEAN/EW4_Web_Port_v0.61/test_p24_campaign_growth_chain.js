'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const U=require('./native_upgrade_core.js');
const BS=require('./battle_save_core.js');
const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'assets/data/native_warzone_tech.json'),'utf8'));

// One continuous campaign-meta chain: improved result -> Stars -> upgrades -> unlock/training/economy/Dock -> battle snapshot -> save/load.
let zones=U.initialZones(manifest),stars=80;
assert.equal(U.techLevel(zones,1,5),-1,'zone 1 Machine Gun begins locked in original tech table');
assert.equal(U.recruitAllowed(U.techLevel(zones,1,5)),false);
let award=U.awardScoreDelta(stars,2,5);stars=award.stars;assert.deepEqual(award,{stars:83,delta:3});

function buy(id){const out=U.upgrade(zones,stars,1,id);assert.equal(out.ok,true,`upgrade ${id} should succeed`);zones=out.zones;stars=out.stars;return out;}
buy(5);             // Machine Gun -1 -> 0: unlock
buy(1);             // Line Infantry 0 -> 1: initial recruit training follows tech
buy(25);            // Dock 0 -> 1: infantry transport permission
buy(22);buy(23);buy(24); // Farm / Financial / Factory 0 -> 1
buy(20);            // Large Fortress -1 -> 0: fort unlock

assert.equal(U.recruitAllowed(U.techLevel(zones,1,5)),true);
assert.equal(U.initialTrainingLevel(U.techLevel(zones,1,1)),1);
assert.equal(U.recruitAllowed(U.techLevel(zones,1,20)),true);
assert.deepEqual(U.zoneEconomicBonuses(zones,1),{food:10,money:20,industry:10});
assert.equal(U.canEmbarkArmy('Militia',U.techLevel(zones,1,25)),true);
assert.equal(U.canEmbarkArmy('Light Cavalry',U.techLevel(zones,1,25)),false);
assert.equal(U.canEmbarkArmy('Light Artillery',U.techLevel(zones,1,25)),false);

const battleTech=zones['1'].slice();
const sample={battle:{file:'campaign1_99.btl',title_cn:'growth-chain'},map:'europe',mode:'campaign',playerOwner:0,round:7,resources:{money:123,industry:45,food:67},countryResources:{},camera:{x:12,y:34,zoom:.75},units:[{army_name:'Line Infantry',grade:0,trainingLevel:U.initialTrainingLevel(battleTech[1]),hp:100,max_hp:100}],objects:[],ownership:[],assignments:new Map(),installations:[],fireCells:new Set(),nativeFiredEvents:new Set(),nativeAppliedEvents:new Set(),itemStores:{},taverns:{},collectMedal:0,campaignTech:battleTech,campaignTechZone:1,ended:null};
const payload=BS.makePayload(sample);
assert.equal(payload.schema,6);assert.deepEqual(payload.campaignTech,battleTech);assert.equal(payload.campaignTechZone,1);
// Meta upgrades after battle start must not retroactively mutate the battle/save snapshot.
zones['1'][25]=3;zones['1'][1]=3;
assert.equal(payload.campaignTech[25],1);assert.equal(payload.campaignTech[1],1);
const restored=BS.normalize(JSON.parse(JSON.stringify(payload)));
assert.deepEqual(restored.campaignTech,battleTech);assert.equal(restored.units[0].trainingLevel,1);assert.equal(restored.campaignTechZone,1);
console.log('P24 campaign growth end-to-end chain: PASS');
