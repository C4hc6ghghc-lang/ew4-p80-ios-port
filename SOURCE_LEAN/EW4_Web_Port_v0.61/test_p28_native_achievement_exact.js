'use strict';
const assert=require('assert'),fs=require('fs'),A=require('./native_achievement_core.js');
assert.equal(A.MAX_STAGE_STARS,420);assert.deepEqual(A.STAGE_COUNTS,[18,17,15,13,11,10]);
let save={owned:[1],campaignBestRating:{'campaign1_01.btl':5,'campaign1_02.btl':3,'campaign1_03b.btl':5},campaignProgress:{'campaign1_03.btl':2},rank:{},rankProgress:{},nobility:{},nobilityProgress:{}};
let commanders={1:{id:1,rank:0,nobilityrank:0}};
let vm=A.viewModel(save,commanders);
assert.deepEqual(vm.stageStars,{earned:13,max:420},'canonical 84-stage stars + legacy progress fallback; branch-b must not double-count');
assert.equal(vm.walletStars,0);
assert.deepEqual(vm.military,{level:7,score:30,raw:300});
assert.deepEqual(vm.nobility,{level:3,score:240,raw:60});
// Native per-general raw values: base 300/60 + completed thresholds + current progress.
save={owned:[1],rank:{1:2},rankProgress:{1:17},nobility:{1:2},nobilityProgress:{1:9}};
vm=A.viewModel(save,commanders);
assert.equal(vm.military.raw,1617); // 300+500+800+17
assert.equal(vm.military.score,161);
assert.equal(vm.nobility.raw,369); // 60+100+200+9
assert.equal(vm.nobility.score,1476);
// Native global levels use float32 threshold growth and cap at 99.
assert.equal(A.aggregateLevel(99,{cutoff:99,first:121,multiplier:1.214}),1);
assert.equal(A.aggregateLevel(100,{cutoff:99,first:121,multiplier:1.214}),2);
assert.equal(A.aggregateLevel(121,{cutoff:99,first:121,multiplier:1.214}),3);
assert.equal(A.aggregateLevel(49,{cutoff:49,first:56,multiplier:1.125}),1);
assert.equal(A.aggregateLevel(50,{cutoff:49,first:56,multiplier:1.125}),2);
assert.equal(A.aggregateLevel(56,{cutoff:49,first:56,multiplier:1.125}),3);
// User mod adaptation: original loops 12 HQ pointers, unlimited-HQ port must not silently ignore slot 13+.
const many={owned:Array.from({length:13},(_,i)=>i+1),rank:{},rankProgress:{},nobility:{},nobilityProgress:{}};
const manyCommanders={};for(let i=1;i<=13;i++)manyCommanders[i]={id:i,rank:0,nobilityrank:0};
const m=A.viewModel(many,manyCommanders);assert.equal(m.countedGenerals,13);assert.equal(m.military.raw,3900);assert.equal(m.nobility.raw,780);
// Native continent value is one integer, rendered without leading zeros, display capped at 999.
assert.deepEqual(A.ruleDigits(0),[0]);assert.deepEqual(A.ruleDigits(7),[7]);assert.deepEqual(A.ruleDigits(42),[4,2]);assert.deepEqual(A.ruleDigits(999),[9,9,9]);
assert.deepEqual(A.continent({achievementConquests:{europe:{value:1000}}},'europe'),{value:1000,display:999,digits:[9,9,9]});
let rec=A.recordConquestValue({},'europe',321);assert(rec.changed);assert.equal(rec.value,321);rec=A.recordConquestValue(rec.save,'europe',111);assert(!rec.changed);assert.equal(rec.value,321);
const app=fs.readFileSync('./app.js','utf8'),html=fs.readFileSync('./index.html','utf8'),css=fs.readFileSync('./r14_native_forms.css','utf8'),sw=fs.readFileSync('./sw.js','utf8');
assert(app.includes('EW4NativeAchievement.viewModel(saveState,COMMANDERS)'));
assert(app.includes('`${vm.stageStars.earned}/${vm.stageStars.max}`'));
assert(app.includes('`Lv ${vm.military.level}`')&&app.includes('`Lv ${vm.nobility.level}`'));
assert(!html.includes('year-value'));assert(!css.includes('.year-value'));
assert(css.includes('.year-word{position:absolute;left:93px;top:115px'));
const cacheVersion=sw.match(/posthandoff(\d+)/);assert(cacheVersion&&+cacheVersion[1]>=28);assert(sw.includes("'./native_achievement_core.js'"));
console.log('P28 native achievement exact local semantics: PASS');
