'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const root=__dirname,app=fs.readFileSync(path.join(root,'app.js'),'utf8'),html=fs.readFileSync(path.join(root,'index.html'),'utf8'),css=fs.readFileSync(path.join(root,'r14_native_forms.css'),'utf8'),sw=fs.readFileSync(path.join(root,'sw.js'),'utf8'),save=fs.readFileSync(path.join(root,'battle_save_core.js'),'utf8'),U=require('./native_upgrade_core.js');
// Persistent campaign Stars + per-warzone tech state.
assert(app.includes('campaignStars:0,warzoneTech:null'));
assert(app.includes('legacyCampaignStarTotal(raw)'));
assert(app.includes('saveState.warzoneTech=EW4NativeUpgrade.normalizeZones'));
assert(app.includes('EW4NativeCampaignSession.recordResult(saveState,campaignCanonicalFile(b),rating)'),'record improvement must delegate to tested campaign session core');
const Session=require('./native_campaign_session_core.js');let _s={campaignStars:4,campaignProgress:{},campaignBestRating:{}};let _r=Session.recordResult(_s,'campaign1_01.btl',3);assert.equal(_r.delta,3);_r=Session.recordResult(_r.state,'campaign1_01.btl',2);assert.equal(_r.delta,0,'record improvement must award only positive score delta');
// Original SceneUpgrade entry / five visible tabs only.
for(const id of ['campaign-lvlup','upgrade-overlay','upgrade-panel','upgrade-tabs','upgrade-grid','upgrade-star-value','upgrade-level-from','upgrade-level-to','upgrade-confirm'])assert(html.includes(`id="${id}"`),id);
assert.equal((html.match(/data-upgrade-page=/g)||[]).length,5,'only five native visible military tabs expected');
assert(css.includes('#upgrade-panel{position:absolute;left:74px;top:28px;width:421px;height:265px'),'native form_upgrade 421x265 geometry missing');
assert(!css.includes('202px stretch'),'invalid CSS background keyword must be removed');
// Recruit tech: locked military tech is filtered; tech level sets TRAINING, never formation grade.
assert(app.includes("(lv?.recruit||[]).filter(cap=>battleState.mode!=='campaign'||EW4NativeUpgrade.recruitAllowed(activeArmyTechLevel(cap.name)))"));
assert(app.includes("const trainingLevel=battleState.mode==='campaign'?EW4NativeUpgrade.initialTrainingLevel(activeArmyTechLevel(rec.name)):0"));
assert(!/grade:\s*EW4NativeUpgrade\.initialTrainingLevel/.test(app),'tech must never overwrite 1/2/3 formation grade');
// Fort tech, economy tech, Dock transport.
assert(app.includes("EW4NativeUpgrade.techIdForFort(name)"));
assert(app.includes("fortTechId=EW4NativeUpgrade.techIdForFort(proto.army_name)"));
for(const id of [22,23,24])assert(app.includes(`activeBattleTechLevel(${id})`),`economic tech ${id} not wired`);
assert(app.includes("EW4NativeUpgrade.canEmbarkArmy(u.army_name,activeBattleTechLevel(25))"),'Dock transport gate missing');
// Battle snapshot prevents out-of-battle upgrades mutating an old running/save game.
assert(app.includes('campaignTech=mode===\'campaign\''));
assert(app.includes('battleState={battle:b,world,map,mode,campaignTech,campaignTechZone'));
assert(save.includes('const SCHEMA=6;'));assert(save.includes('new Set([1,2,3,4,5,6])'));
assert(save.includes('campaignTech:Array.isArray(state.campaignTech)'));
assert(save.includes('campaignTechZone:'));

const BS=require('./battle_save_core.js');
const row=Array.from({length:26},(_,i)=>(i%5)-1),battleSample={battle:{file:'campaign1_01.btl',title_cn:'x'},map:'europe',mode:'campaign',playerOwner:0,round:2,resources:{money:1,industry:2,food:3},countryResources:{},camera:{x:1,y:2,zoom:.5},units:[],objects:[],ownership:[],assignments:new Map(),installations:[],fireCells:new Set(),nativeFiredEvents:new Set(),nativeAppliedEvents:new Set(),itemStores:{},taverns:{},collectMedal:0,campaignTech:row,campaignTechZone:1,ended:null};
const snap=BS.makePayload(battleSample),restored=BS.normalize(JSON.parse(JSON.stringify(snap)));assert.equal(snap.schema,6);assert.deepEqual(restored.campaignTech,row);assert.equal(restored.campaignTechZone,1);

// Offline PWA includes the controller/data and original upgrade assets.
assert(/posthandoff(?:21-upgrade|22-defense|[2-9][3-9]|30-final-pass)/.test(sw),'P21 or later cache generation required');for(const x of ['native_upgrade_core.js','native_warzone_tech.json','def_warzonetech.xml','button_lvlup.png','button_upgrade_locked.png','button_upgrade_lv4.png','button_upgrade_machinegun.png','button_upgrade_coastalartillery.png'])assert(sw.includes(x),`offline P21 asset missing ${x}`);
// Core invariant smoke checks.
assert.equal(U.recruitAllowed(-1),false);assert.equal(U.initialTrainingLevel(3),3);assert.equal(U.economicBonus(3,'money'),60);assert.equal(U.economicBonus(3,'food'),30);assert.equal(U.canEmbarkArmy('Light Artillery',2),false);assert.equal(U.canEmbarkArmy('Light Artillery',3),true);
console.log('P21 native SceneUpgrade integration: PASS');
