'use strict';
const fs=require('fs'),assert=require('assert');
const R=require('./native_result_core.js'),S=require('./battle_save_core.js');
const db=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8')).battles;
function b(file){const x=db.find(v=>v.file===file);assert(x,file);return x}
// Five-grade exact turn boundaries + cumulative award deltas.
const c1=b('campaign1_01.btl');
assert.deepStrictEqual(R.result(8,c1,0),{limits:{valid:true,win:22,best:8},score:5,grade:1,awardMedal:50,cumulativeMedal:50,descriptionKey:'desc_victory 1'});
assert.equal(R.result(8,c1,5).awardMedal,0);
assert.equal(R.result(16,c1,3).awardMedal,0);
// Result list must cap unique player generals at six and ignore enemy/duplicates.
const units=[1,2,2,3,4,5,6,7,8].map((id,i)=>({owner:i===8?1:0,commander_id:id}));
assert.deepStrictEqual(R.participatingGeneralIds(units,0,6),[1,2,3,4,5,6]);
// Continue completes at the last non-hidden stage even if a physical hidden entry follows it.
const rows=[{file:'campaign1_17.btl',meta:{hide:0}},{file:'campaign1_18.btl',meta:{hide:1}}];
assert.deepStrictEqual(R.campaignContinueDecision(rows,'campaign1_17.btl'),{valid:true,complete:true,continueBattle:0,index:0,lastVisible:0});
assert.deepStrictEqual(R.campaignContinueDecision(rows,'campaign1_18.btl'),{valid:true,complete:false,continueBattle:0,index:1,lastVisible:0});
// SceneComplete first-clear rewards are exact and repeat clears are zeroed.
assert.deepStrictEqual(R.campaignCompletionReward(1,false),{zone:1,medal:0,badge:1,score:1,image:'campaignend_fr.png',firstTime:true});
assert.deepStrictEqual(R.campaignCompletionReward(2,false),{zone:2,medal:50,badge:0,score:1,image:'campaignend_coalitiont.png',firstTime:true});
assert.deepStrictEqual(R.campaignCompletionReward(2,true),{zone:2,medal:0,badge:0,score:0,image:'campaignend_coalitiont.png',firstTime:false});
// getmedal proc: native strict > thresholds and class/level adjustment.
assert.equal(R.collectMedalProc(19,99,1,9),false);
assert.equal(R.collectMedalProc(20,95,255,0),false);assert.equal(R.collectMedalProc(20,96,255,0),true);
assert.equal(R.collectMedalProc(25,91,255,0),false);assert.equal(R.collectMedalProc(25,92,255,0),true);
assert.equal(R.collectMedalProc(30,87,255,0),false);assert.equal(R.collectMedalProc(30,88,255,0),true);
assert.equal(R.collectMedalProc(35,82,255,0),false);assert.equal(R.collectMedalProc(35,83,255,0),true);
assert.equal(R.collectMedalAdjustedRoll(90,0,3),96);assert.equal(R.collectMedalAdjustedRoll(90,3,3),96);assert.equal(R.collectMedalAdjustedRoll(90,1,3),99);assert.equal(R.collectMedalAdjustedRoll(90,2,3),90);
// BattleSave current schema persists CollectMedal while accepting legacy schema 4.
const state={battle:{file:'campaign1_01.btl',title_cn:'x'},map:'europe',mode:'campaign',playerOwner:0,round:4,resources:{money:1,industry:2,food:3},countryResources:{},camera:{x:1,y:2,zoom:.5},units:[],objects:[],ownership:[],assignments:new Map(),installations:[],fireCells:new Set(),nativeFiredEvents:new Set(),nativeAppliedEvents:new Set(),itemStores:{},taverns:{},collectMedal:7,ended:null};
const payload=S.makePayload(state);assert.equal(payload.schema,S.SCHEMA);assert(S.SCHEMA>=5);assert.equal(payload.collectMedal,7);assert.equal(S.normalize(payload).collectMedal,7);
const legacy={...payload,schema:4};delete legacy.collectMedal;assert(S.validate(legacy));assert.equal(S.normalize(legacy).collectMedal,0);
console.log('P16 behavior PASS: result grades + generals + Continue/Complete + getmedal + current save schema');
