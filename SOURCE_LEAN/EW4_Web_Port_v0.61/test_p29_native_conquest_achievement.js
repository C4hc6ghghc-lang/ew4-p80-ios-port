'use strict';
const assert=require('assert'),fs=require('fs');
const C=require('./native_conquest_achievement_core.js');

const commanders={1:{id:1,rank:0,nobilityrank:0},2:{id:2,rank:0,nobilityrank:0}};
const save={owned:[1,2],rank:{1:2,2:3},nobility:{1:1,2:2},campaignBestRating:{},campaignProgress:{},achievementConquests:{}};
for(let i=1;i<=20;i++)save.campaignBestRating[`campaign1_${String(i).padStart(2,'0')}.btl`]=5; // getter only counts native-defined 1..18 => 90 stars

assert.equal(C.mapType('europe'),0);assert.equal(C.mapType('america'),1);
assert.equal(C.generalLevelContribution(save,commanders),770);
assert.equal(C.resourceContribution({money:1000,industry:500,food:2000}),600);
assert.equal(C.normalRoundContribution(31),23330);
assert.equal(C.normalRoundContribution(40),19980);
assert.equal(C.normalRoundContribution(50),13875);
assert.equal(C.normalRoundContribution(60),8880);
assert.equal(C.normalRoundContribution(70),4995);
assert.equal(C.normalRoundContribution(80),2220);
assert.equal(C.normalRoundContribution(100),0);
assert.equal(C.asiaRoundContribution(25,'europe'),19500);
assert.equal(C.asiaRoundContribution(40,'europe'),11700);
assert.equal(C.asiaRoundContribution(55,'europe'),2925);
assert.equal(C.asiaRoundContribution(40,'america'),7800);
assert.equal(C.asiaRoundContribution(50,'america'),3250);
assert.equal(C.asiaRoundContribution(51,'america'),0);
assert.equal(C.asiaEligible(65,'europe'),true);assert.equal(C.asiaEligible(66,'europe'),false);
assert.equal(C.asiaEligible(55,'america'),true);assert.equal(C.asiaEligible(56,'america'),false);

// Assembly-derived reference vectors. Campaign native-star sum here is 90.
let n=C.normalValue({round:40,map:'europe',resources:{money:1000,industry:500,food:2000},save,commanders});
assert.deepEqual(n.components,{resource:600,hq:770,stage:900,round:19980});
assert.equal(n.total,22250);assert.equal(n.normalized,47);assert.equal(n.value,450);assert.equal(n.kind,'europe');
let a=C.asiaValue({round:40,map:'america',resources:{money:1000,industry:500,food:2000},save,commanders});
assert.deepEqual(a.components,{resource:600,hq:770,stage:1530,round:7800});
assert.equal(a.total,10700);assert.equal(a.normalized,15);assert.equal(a.value,10);assert.equal(a.kind,'asia');

// Native caller semantics corrected from direct x86_64 form_complete callbacks:
// fast victories open group_challenge and DO NOT persist yet. The player chooses
// Asia (7ef50 then 7efe0) or the normal Europe/America record (7efe0 only).
let out=C.recordVictory(save,commanders,{mode:'conquest',victory:true,round:40,map:'america',resources:{money:1000,industry:500,food:2000}});
assert.equal(out.requiresChoice,true);assert.equal(out.changed,false);assert.equal(out.prepared.normal.kind,'america');assert.equal(out.prepared.asia.kind,'asia');assert.equal(out.save.achievementConquests.america,undefined);assert.equal(out.save.achievementConquests.asia,undefined);
let picked=C.recordResult(out.save,out.prepared.asia);assert.equal(picked.save.achievementConquests.asia.value,10);assert.equal(picked.save.achievementConquests.america,undefined);
out=C.recordVictory(picked.save,commanders,{mode:'conquest',victory:true,round:70,map:'europe',resources:{money:1000,industry:500,food:2000}});
assert.equal(out.requiresChoice,false);assert.equal(out.result.kind,'europe');assert.ok(out.save.achievementConquests.europe.value>0);
const old=out.save.achievementConquests.europe.value;
out=C.recordVictory(out.save,commanders,{mode:'conquest',victory:true,round:99,map:'europe',resources:{money:0,industry:0,food:0}});
assert.equal(out.save.achievementConquests.europe.value,old); // native max-only persistence
assert.equal(C.resultForVictory({mode:'campaign',victory:true,round:1,map:'europe',resources:{},save,commanders}),null);
assert.equal(C.resultForVictory({mode:'conquest',victory:false,round:1,map:'europe',resources:{},save,commanders}),null);

const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),sw=fs.readFileSync('sw.js','utf8');
assert(html.includes('native_conquest_achievement_core.js'));
assert(app.includes('EW4NativeConquestAchievement.prepareVictory'));assert(app.includes('EW4NativeConquestAchievement.recordResult'));
assert(sw.includes("'./native_conquest_achievement_core.js'"));
console.log('P29 native conquest Achievement formula + persistence: PASS');
