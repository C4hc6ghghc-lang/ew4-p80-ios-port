'use strict';
const assert=require('assert'),fs=require('fs');
const C=require('./native_conquest_achievement_core.js');
const html=fs.readFileSync('index.html','utf8'),app=fs.readFileSync('app.js','utf8'),xml=fs.readFileSync('assets/data/original_layout-568h.xml','utf8'),sw=fs.readFileSync('sw.js','utf8');
// Native form_complete contract: 346x190, challenge and conquest groups, exact buttons.
assert(xml.includes('<Layout id="form_complete" type="user_window" w="346" h="190"'));
for(const id of ['group_challenge','group_conquest','btn_chal_asia','btn_chal_euro','image_archive','text_round_value','text_medal_value'])assert(xml.includes(`id="${id}"`));
assert(html.includes('id="conquest-complete"'));assert(html.includes('id="conquest-challenge-group"'));assert(html.includes('id="conquest-summary-group"'));
assert(html.includes('assets/textures/conquest_asia.png'));assert(html.includes('id="conquest-challenge-asia"'));assert(html.includes('id="conquest-challenge-home"'));
assert(app.includes("continueConquestFromResult()"));assert(app.includes("chooseConquestChallenge('asia')"));assert(app.includes("chooseConquestChallenge('normal')"));
assert(app.includes("battleState.map==='america'?'btn_chal_amer':'btn_chal_euro'"));
assert(app.includes('recordPreparedConquestAchievement(prepared.normal)'));assert(app.includes("choice==='asia'?prepared.asia:prepared.normal"));
// Fast conquest is choice-gated, not automatically written to Asia.
const commanders={1:{id:1,rank:0,nobilityrank:0}},save={owned:[1],rank:{1:0},nobility:{1:0},campaignBestRating:{},campaignProgress:{},achievementConquests:{}};
const fast=C.recordVictory(save,commanders,{mode:'conquest',victory:true,round:40,map:'europe',resources:{money:1000,industry:500,food:1000}});
assert.equal(fast.requiresChoice,true);assert.deepEqual(fast.save.achievementConquests,{});assert.equal(fast.prepared.normal.kind,'europe');assert.equal(fast.prepared.asia.kind,'asia');
const normal=C.recordResult(fast.save,fast.prepared.normal);assert(normal.save.achievementConquests.europe);assert(!normal.save.achievementConquests.asia);
const asia=C.recordResult(fast.save,fast.prepared.asia);assert(asia.save.achievementConquests.asia);assert(!asia.save.achievementConquests.europe);
for(const a of ['conquest_asia.png','button_conquest_asia.png','tex_conquest_1793.png','tex_conquest_1775.png','tex_conquest_1806.png','tex_conquest_1809.png','tex_conquest_1812.png','tex_conquest_1815.png'])assert(sw.includes(a),`SW missing ${a}`);
console.log('P30 native Conquest form_complete + fast challenge choice flow PASS');
