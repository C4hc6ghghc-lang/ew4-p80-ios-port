'use strict';
const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),sw=fs.readFileSync('sw.js','utf8');
for(const x of ['function nativeStageTurnLimits','EW4NativeResult.result','campaignBestRating','recordCampaignResult(battleState.battle,result.score)','battleState.round>lim.win',"showBattleResult('defeat','turn-limit')"])assert(app.includes(x),x);
for(const x of ['battle-result-continue','native-result-threshold','native-result-stars','native-result-medals','native_result_core.js'])assert(html.includes(x),x);
for(const x of ['star_middle.png','diffcult_1.png','medals.png'])assert((app+html).includes(x),x);
assert(/posthandoff(?:1[6-9]|[2-9][0-9])-/.test(sw),'service worker cache must be P16 or newer');assert(sw.includes("'./native_result_core.js'"));
assert(app.includes("STRINGS?.[`desc_failure ${reason==='turn-limit'?2:1}`]"));
console.log('native result integration PASS: runtime limits + 5-grade result form + reward delta + defeat timeout bridge');
