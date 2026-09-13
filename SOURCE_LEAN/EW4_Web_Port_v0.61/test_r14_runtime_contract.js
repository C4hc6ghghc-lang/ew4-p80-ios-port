'use strict';
const fs=require('fs'),assert=require('assert'),vm=require('vm');
const h=fs.readFileSync('index.html','utf8'),a=fs.readFileSync('app.js','utf8'),swCode=fs.readFileSync('sw.js','utf8');

// Battle HUD should not expose debug/mod currency overlay.
assert(!h.includes('id="mod-strip"'));
assert(!h.includes('class="mod-strip"'));

// Native round/skip assets are wired to actual phase state.
for(const needle of ["phase:'player'","setBattlePhase('ai')","button_skip","aiFastForward=true","aiDelay(step"]){
  assert(a.includes(needle),needle);
}
assert(a.includes("S.phase==='ai'||S.ended"),'enemy-turn reentry guard');

// Camera must use the reversed native camera/gesture core, not the old Web-only zoom range.
for(const needle of ['EW4NativeCamera.MIN_ZOOM','EW4NativeCamera.MAX_ZOOM','function clampCamera','function zoomCameraAt','EW4NativeCamera.panStep','EW4NativeCamera.pinchStep','EW4NativeCamera.isNativeTap','unitVisualZoom']){
  assert(a.includes(needle),needle);
}
assert(h.includes('native_camera_core.js'),'native camera core load missing');
assert(swCode.includes('./native_camera_core.js'),'native camera core precache missing');
assert(!a.includes('CAMERA_MIN_ZOOM=.58'),'legacy .58 minimum removed');
assert(!a.includes('CAMERA_MAX_ZOOM=1.65'),'legacy 1.65 maximum removed');
assert(!a.includes('pinchWorld'),'legacy fixed-midpoint pinch removed');
assert(!a.includes("Math.max(.45,Math.min(1.8"),'legacy unconstrained zoom path removed');


// Original-style battle interaction shell: selection exposes native circular actions,
// information panels open only through the action bar, and debug overlays stay hidden.
for(const needle of ['id="battle-actions"','id="battle-action-menu"','button_buyship','button_builddefense','button_city','button_info'])assert((h+a).includes(needle),needle);
assert(a.includes('function selectFacility'));
assert(a.includes('function renderBattleActions'));
assert(a.includes('function showBuildMenu'));
assert(!a.includes('renderUnitActions(u,el)'),'legacy black-card action injection removed');
assert(h.includes('#battle-pause{left:535px!important'), 'original-scale pause HUD placement');
assert(h.includes('#battle-actions{position:absolute;left:50%;bottom:2px'), 'bottom native action row placement');
assert(a.includes('Original EW4 uses hollow destination/target rings'), 'native hollow move-ring feedback missing');
assert(a.includes('isHostilePair(S.selected,u)'), 'pairwise hostile target-ring logic missing');

// Music is a real battle lifecycle, not only an options-page demo button.
for(const needle of ['function startBattleMusic','function pauseBattleMusic','function stopDefeatMusic','saveState.music=music',"EW4NativeUIAudio?.battleResultAudio?.('defeat')",'resultAudio.bgm&&music',"playNativeSfxFile('sfx_celebrate.wav')"])assert(a.includes(needle),needle);


// Campaign loop is sequential like the original locked-stage list and persists victory tier.
for(const needle of ['campaignProgress:{}','function campaignUnlocked','function recordCampaignResult','battle-row.locked','button_lock.png','openZone(selectedZone)'])assert((h+a).includes(needle),needle);
assert(a.includes("recordCampaignResult(battleState.battle,result.score)"));
assert(a.includes('campaignBestRating'));assert(h.includes('native_result_core.js'));

// Mod cheats remain mechanical only; they are not painted over the original UI.
for(const visible of ['🏅 ∞','🛡️ ∞','刷新 ∞','上限 ∞','玩家专属强化版'])assert(!h.includes(visible)&&!a.includes(visible),visible);

// In-battle general/equipment information uses the original general-info button asset.
for(const needle of ['showBattleCommanderInfo','button_generalinfo','image_ui_hd','battle-general-eq'])assert((h+a).includes(needle),needle);

// Original motion manifests now drive pose weights, and original special-facility markers are decoded.
for(const needle of ['function attackAnimationProfile','ATTACK_POSES?.[k]','RELOAD_POSES?.[k]','FINISH_POSES?.[k]','Math.round(sum*11.2)','(path.length-1)*150','function specialFacilityType','marker_${t}.png'])assert(a.includes(needle),needle);
assert(a.includes("n===1?'trade':n===2?'shop':n===3?'bar'"),'native special-building order');
for(const visible of ['勋章不扣除','未扣除'])assert(!a.includes(visible),visible);
// Native building-upgrade cost tables reversed from arm64 helpers 0x55320/0x553b0.
for(const needle of ['EW4NativeConstruction.upgradeCost','EW4Combat.hasSkill(c,30)','button_buildupgrade'])assert(a.includes(needle),needle);


// Equipment is inventory-backed; P18 replaces the old instant Web picker with native form_deployitem.
for(const needle of ['itemInventory:EW4ItemInventory.emptyBank()','function equipmentSlotsForCommander','function openDeployItem','function commitDeployItem','EW4ItemInventory.changeSlot','bank.slots.forEach((entry,i)=>'])assert(a.includes(needle),needle);
assert(!a.includes('function equipmentPool()'),'free global equipment catalog removed');
assert(!a.includes('function inventoryEquipmentPool'),'old compressed equipment-pool controller removed');
assert(!a.includes('openEquipmentPicker('),'old instant Web equipment picker removed');
assert(h.includes('item_inventory_core.js'));assert(h.includes('id="eq-equip"'));assert(h.includes('id="eq-prev"'));assert(h.includes('id="eq-next"'));
assert(swCode.includes('./item_inventory_core.js'));

// Execute the service worker fetch handler with mocks and verify navigation is network-first.
const handlers={};
const stored=[];
const cache={addAll:async()=>{},put:async(req,res)=>{stored.push({req,res})}};
const sandbox={
  self:{addEventListener:(name,fn)=>handlers[name]=fn,skipWaiting:async()=>{},clients:{claim:async()=>{}}},
  caches:{open:async()=>cache,keys:async()=>[],delete:async()=>true,match:async()=>({ok:true,redirected:true,type:'basic',tag:'bad-cache'})},
  fetch:async(req)=>({ok:true,redirected:false,type:'basic',tag:'network',clone(){return this}}),
  Promise,setTimeout,console
};
vm.createContext(sandbox);vm.runInContext(swCode,sandbox);
assert(handlers.fetch,'fetch handler');
let navPromise;
handlers.fetch({request:{method:'GET',mode:'navigate'},respondWith:p=>navPromise=p});
Promise.resolve(navPromise).then(resp=>{
  assert.equal(resp.tag,'network');
  assert(!swCode.includes("const CORE=['./',"),'redirect-prone root is not precached');
  assert(swCode.includes("!response.redirected"));
  console.log('r14 runtime contract PASS: SW navigation, phase/skip, camera clamp/semantic scale');
}).catch(e=>{console.error(e);process.exitCode=1});
