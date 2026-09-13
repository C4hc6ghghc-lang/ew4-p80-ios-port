'use strict';

const MODS=Object.freeze({medals:Infinity,badges:Infinity,academyRefresh:Infinity,generalCap:Infinity,battleConsumables:Infinity,lowerBoundFix:true,playerAttackMinBonus:4,playerAttackMaxBonus:4,playerBaseHpBonus:120,playerMovementBonus:2});
const SAVE_KEY='ew4_web_port_v061';
const LEGACY_SAVE_KEYS=['ew4_web_port_v06','ew4_web_port_v05'];
const BATTLE_AUTOSAVE_KEY='ew4_web_port_v061_battle_autosave';
const BATTLE_SLOT_PREFIX='ew4_web_port_v061_battle_slot_';
const PRINCESS_IDS=Object.freeze([201,202,203,204,205,206,207,208]);
const ORIGINAL_PRINCESS_ORDER=Object.freeze([202,204,201,203,205,206,207,208]);
const stage=document.getElementById('stage');
const screens=[...document.querySelectorAll('.screen')];
const statusEl=document.getElementById('status');
const canvas=document.getElementById('battle-canvas'),ctx=canvas.getContext('2d');
const BATTLE_LOGICAL_W=568,BATTLE_LOGICAL_H=320,MAX_BATTLE_BACKING_SCALE=4;
let battleBackingScale=1;
const zoneNames={1:'帝国雄鹰',2:'反法同盟',3:'神圣罗马帝国',4:'东方霸主',5:'美国的崛起',6:'日不落帝国'};
const conquests=[
 {idx:1,tex:'1793',loc:'europe',year:'1798',map:'europe',countries:'法国 · 英国 · 奥地利 · 俄国 · 普鲁士 …'},
 {idx:2,tex:'1775',loc:'america',year:'1775',map:'america',countries:'美国 · 英国 · 原住民势力 …'},
 {idx:3,tex:'1806',loc:'europe',year:'1806',map:'europe',countries:'法国 · 普鲁士 · 俄国 · 奥地利 …'},
 {idx:4,tex:'1809',loc:'europe',year:'1809',map:'europe',countries:'法国 · 奥地利 · 英国 · 俄国 …'},
 {idx:5,tex:'1812',loc:'america',year:'1812',map:'america',countries:'美国 · 英国 · 加拿大地区 …'},
 {idx:6,tex:'1815',loc:'europe',year:'1815',map:'europe',countries:'法国 · 英国 · 普鲁士 · 俄国 …'}
];

let DB=null,WORLDS=null,ARMIES=null,COMMANDERS=null,READY=null,ATTACK_POSES=null,RELOAD_POSES=null,FINISH_POSES=null,TERRAIN=null,PORTRAITS=null,SPRITES=null,STRINGS=null,CONSTRUCTIONS=null,CARDS=null,ITEMS=null,ITEM_ICONS=null,PLAYER_OVERRIDES=null,PLAYER_PRINCESS_OVERRIDES=null,INSTALLATIONS=null,BUILD_CARDS=null,BATTLE_NATIVE=null,NATIVE_TRIGGER_TARGETS=null,BATTLE_ITEMSTORES=null,BATTLE_TAVERNS=null,NATIVE_ANIM_PACK=null,NATIVE_EFFECT_AUDIO_DATA=null,NATIVE_SIMPLE_EFFECTS_DATA=null,NATIVE_TUTORIAL_SCRIPTS=null,NATIVE_CAMPAIGN_TARGETS=null,NATIVE_WARZONE_TECH=null,NATIVE_BATTLELINES=null,NATIVE_BATTLELINE_XML=null;
let COMPACT_BILE_PACK=null;const COMPACT_BILE_RESOURCES=new Map(),COMPACT_BILE_PROMISES=new Map();
let MAPTEXT_BILE=null,MAPTEXT_ATLAS=null,MAPTEXT_BASE_PROMISE=null;const MAPTEXT_PLACEMENTS=new Map(),MAPTEXT_PLACEMENT_PROMISES=new Map();
let GETMEDAL_BILE=null,GETMEDAL_ATLAS=null,GETMEDAL_PROMISE=null;
const ORIGINAL_BATTLE_MUSIC=Object.freeze(['battle1.mp3','battle2.mp3','battle3.mp3','battle4.mp3']);
let selectedZone=1,selectedBattle=null,battleState=null,music=false;
let continueBattlePendingZone=0;
let pending=null,pendingPlayerOwner=null,countryChoice=null,selectedDeployGeneral=null,deploymentTargetUnitIndex=null,deploymentContext='battle';
let activeShopContext=null;
let academyPool='6',academyCandidates=[],academySelectedId=null,academyReturnScreen='deploy';
let detailCommander=null;
const imageCache=new Map();
const audio={select:new Audio('assets/audio/sfx_select.wav'),gun:new Audio('assets/audio/sfx_gunfire1.wav'),cannon:new Audio('assets/audio/sfx_cannon.wav'),knife:new Audio('assets/audio/sfx_knife1.wav'),cavalry:new Audio('assets/audio/sfx_cavalrymove.wav'),naval:new Audio('assets/audio/sfx_naval_gun.wav'),fire:new Audio('assets/audio/sfx_fire.wav')};

function defaultSave(){return{version:61,owned:[...PRINCESS_IDS],rank:{},nobility:{},rankProgress:{},nobilityProgress:{},generalStats:{},equipment:{},itemInventory:EW4ItemInventory.emptyBank(),hqShop:{dateKey:'',slots:[]},academyPool:'6',academyCandidatesByPool:{'6':[],'4':[],'2':[]},music:true,bgVol:50,seVol:50,gameSpeed:2,showGrids:false,campaignProgress:{},campaignBestRating:{},campaignStars:0,warzoneTech:null,campaignSecretUnlocks:{},campaignCompletedZones:{},campaignCompletionEarned:{medals:0,badges:0,score:0}}}
function ensurePrincessUnlocks(state){state.owned=[...new Set([...(Array.isArray(state.owned)?state.owned:[]),...PRINCESS_IDS])];return state}
function legacyCampaignStarTotal(raw){return EW4NativeCampaignSession.legacyStarTotal(raw)}
function loadSave(){for(const key of [SAVE_KEY,...LEGACY_SAVE_KEYS]){try{const v=JSON.parse(localStorage.getItem(key)||'null');if(v&&Array.isArray(v.owned)){let out=ensurePrincessUnlocks(Object.assign(defaultSave(),v,{version:61}));out.rankProgress=out.rankProgress&&typeof out.rankProgress==='object'?out.rankProgress:{};out.nobilityProgress=out.nobilityProgress&&typeof out.nobilityProgress==='object'?out.nobilityProgress:{};out.generalStats=out.generalStats&&typeof out.generalStats==='object'?out.generalStats:{};out.equipment=out.equipment&&typeof out.equipment==='object'?out.equipment:{};out.itemInventory=(out.itemInventory&&Array.isArray(out.itemInventory.slots))?EW4ItemInventory.sanitizeInventory(out.itemInventory):((out.itemInventory&&typeof out.itemInventory==='object')?out.itemInventory:EW4ItemInventory.emptyBank());out=EW4NativeCampaignSession.normalizeSave(out,v);if(key!==SAVE_KEY){try{localStorage.setItem(SAVE_KEY,JSON.stringify(out))}catch(e){}}return out}}catch(e){}}return ensurePrincessUnlocks(EW4NativeCampaignSession.normalizeSave(defaultSave(),defaultSave()))}
let saveState=loadSave();
saveState.rankProgress=(saveState.rankProgress&&typeof saveState.rankProgress==='object')?saveState.rankProgress:{};saveState.nobilityProgress=(saveState.nobilityProgress&&typeof saveState.nobilityProgress==='object')?saveState.nobilityProgress:{};saveState.generalStats=(saveState.generalStats&&typeof saveState.generalStats==='object')?saveState.generalStats:{};saveState.campaignStars=EW4NativeUpgrade.clampStars(saveState.campaignStars);saveState.academyCandidatesByPool=EW4NativeAcademy.normalizePools(saveState.academyCandidatesByPool);saveState.campaignSecretUnlocks=(saveState.campaignSecretUnlocks&&typeof saveState.campaignSecretUnlocks==='object')?saveState.campaignSecretUnlocks:{};saveState.campaignCompletedZones=(saveState.campaignCompletedZones&&typeof saveState.campaignCompletedZones==='object')?saveState.campaignCompletedZones:{};saveState.campaignCompletionEarned=Object.assign({medals:0,badges:0,score:0},saveState.campaignCompletionEarned||{});
function clampSettingPercent(v,fallback=50){v=Number(v);return Number.isFinite(v)?Math.max(0,Math.min(100,Math.round(v))):fallback}
if(saveState.bgVol==null)saveState.bgVol=saveState.music===false?0:50;
if(saveState.seVol==null)saveState.seVol=50;
saveState.bgVol=clampSettingPercent(saveState.bgVol);saveState.seVol=clampSettingPercent(saveState.seVol);saveState.gameSpeed=Math.max(1,Math.min(5,Math.trunc(+saveState.gameSpeed||2)));saveState.showGrids=saveState.showGrids===true||+saveState.showGrids===1;music=saveState.bgVol>0;saveState.music=music;
function persist(){try{localStorage.setItem(SAVE_KEY,JSON.stringify(saveState))}catch(e){}}
function battleSaveKey(slot){return slot==='auto'?BATTLE_AUTOSAVE_KEY:`${BATTLE_SLOT_PREFIX}${slot}`}
function readBattleSave(slot){try{const p=JSON.parse(localStorage.getItem(battleSaveKey(slot))||'null');return EW4BattleSave.validate(p)?p:null}catch(e){return null}}
function writeBattleSave(slot='auto',quiet=false){
  if(!battleState||battleState.dialogueActive||battleState.ended)return false;
  try{const p=EW4BattleSave.makePayload(battleState);localStorage.setItem(battleSaveKey(slot),JSON.stringify(p));if(!quiet)flash(slot==='auto'?'自动存档完成':`存档 ${slot} 已保存`);return true}catch(e){if(!quiet)flash('存档失败：'+e.message,2600);return false}
}
function battleSaveMeta(slot){const p=readBattleSave(slot);if(!p)return null;const d=new Date(p.savedAt||0);return{...p,date:d.toLocaleDateString('zh-CN',{month:'2-digit',day:'2-digit'}),time:d.toLocaleTimeString('zh-CN',{hour:'2-digit',minute:'2-digit',hour12:false})}}
let savePanelMode='save',optionsReturnScreen='main';
function activeScreenId(){return screens.find(x=>x.classList.contains('active'))?.id||'main'}
function hideBattleModals(){document.getElementById('battle-modal-shade')?.classList.remove('show');document.getElementById('pause-panel')?.classList.remove('show');document.getElementById('save-panel')?.classList.remove('show');document.getElementById('roundturn-panel')?.classList.remove('show');roundTurnContinue=null}
function openPausePanel(){if(!battleState||battleState.ended||battleState.dialogueActive)return;document.getElementById('pause-round').textContent=String(battleState.round);document.getElementById('battle-modal-shade').classList.add('show');document.getElementById('pause-panel').classList.add('show')}
function battleSaveCountryCode(m){const b=DB?.battles?.find(x=>x.file===m?.battleFile);return b?.countries?.find(c=>+c.index===+m?.playerOwner)?.code||''}
function slotHtml(slot,mode){
  const m=battleSaveMeta(slot),empty=!m,action=mode==='save'?'保存':'读取',code=m?battleSaveCountryCode(m):'',flag=code?spriteFile(`${code}1.png`):'',title=m?.battleTitle||(STRINGS?.text_empty||'无'),date=m?`${m.date} ${m.time}`:'';
  return `<div class="save-slot ${slot==='auto'?'autosave ':''}${empty?'empty ':''}" data-slot="${slot}"><div class="slot-title">${title}</div><div class="slot-date">${date}</div>${flag?`<img class="slot-flag" src="${flag}" alt="${code.toUpperCase()}">`:''}${(mode==='load'||slot!=='auto')&&(!empty||mode==='save')?`<button title="${action}" data-slot-action="${slot}"></button>`:''}</div>`
}
function renderSavePanel(){
  const root=document.getElementById('save-grid');if(!root)return;document.getElementById('save-panel-title').textContent=savePanelMode==='save'?(STRINGS?.title_savegame||'保存游戏'):(STRINGS?.title_loadgame||'载入游戏');document.getElementById('save-mode-label').textContent=STRINGS?.text_autosave||'自动保存';
  root.innerHTML=slotHtml('auto',savePanelMode)+[1,2,3,4,5,6].map(n=>slotHtml(n,savePanelMode)).join('');
  const els=[...root.querySelectorAll('.save-slot:not(.autosave)')],coords=[[0,0],[0,67],[0,134],[231,0],[231,67],[231,134]];els.forEach((el,i)=>{el.style.left=coords[i][0]+'px';el.style.top=coords[i][1]+'px'});
  root.querySelectorAll('[data-slot-action]').forEach(btn=>btn.onclick=async e=>{e.stopPropagation();const raw=btn.dataset.slotAction,slot=raw==='auto'?'auto':+raw;if(savePanelMode==='save'){if(slot==='auto')return;writeBattleSave(slot);renderSavePanel()}else await loadBattleSave(slot)});
}
function openSavePanel(mode='save'){
  savePanelMode=mode;if(mode==='save'&&(!battleState||battleState.dialogueActive)){flash('当前不能存档');return}
  playNativeFormOpenSfx('form_save');document.getElementById('battle-modal-shade').classList.add('show');document.getElementById('pause-panel').classList.remove('show');document.getElementById('save-panel').classList.add('show');renderSavePanel()
}
let roundTurnContinue=null;
function nativeRoundTurnGeneralIds(){
  const seen=new Set(),ids=[];for(const u of battleState?.units||[]){if(u.dead||+u.owner!==+battleState.playerOwner||u.commander_id==null)continue;const id=+u.commander_id;if(seen.has(id))continue;seen.add(id);ids.push(id);if(ids.length>=6)break}return ids
}
function renderNativeRoundTurn(summary={}){
  const lim=nativeStageTurnLimits(battleState?.battle),set=(id,v)=>{const el=document.getElementById(id);if(el)el.textContent=String(Math.max(0,Math.trunc(+v||0)))};
  set('rt-money',summary.money);set('rt-industry',summary.industry);set('rt-food-add',summary.foodAdd);set('rt-food-del',summary.foodDel);set('rt-roundnum',battleState?.round||1);set('rt-best',lim.valid?lim.best:0);set('rt-win',lim.valid?lim.win:0);
  const root=document.getElementById('rt-generals');if(!root)return;const ids=nativeRoundTurnGeneralIds();root.innerHTML=ids.map(id=>{const c=DB?.commanders?.find(x=>+x.id===+id);return c?`<div class="rt-general"><img src="${portrait(c.id)}"><span>${commanderName(c)}</span></div>`:''}).join('')||'<div class="rt-empty">本回合无参战将领</div>'
}
function openNativeRoundTurn(summary,done){
  if(!battleState||battleState.ended){done?.();return}roundTurnContinue=typeof done==='function'?done:null;renderNativeRoundTurn(summary);playNativeFormOpenSfx('form_roundturn');document.getElementById('battle-modal-shade')?.classList.add('show');document.getElementById('roundturn-panel')?.classList.add('show')
}
function closeNativeRoundTurn(){
  document.getElementById('roundturn-panel')?.classList.remove('show');document.getElementById('battle-modal-shade')?.classList.remove('show');const done=roundTurnContinue;roundTurnContinue=null;done?.()
}
let stageIntroContinue=null;
function renderNativeStageIntro(b){
  if(!b)return;const lim=nativeStageTurnLimits(b),c=campaignIntroCommander(b),set=(id,v)=>{const el=document.getElementById(id);if(el)el.textContent=String(v??'')};
  set('stageintro-title','');set('stageintro-desc',b.desc_cn||'');set('stageintro-win',lim.valid?lim.win:0);set('stageintro-best',lim.valid?lim.best:0);
  const pic=document.getElementById('stageintro-portrait'),name=document.getElementById('stageintro-commander-name');if(c){pic.src=portrait(c.id);pic.style.display='block';pic.alt=commanderName(c);name.textContent=commanderName(c)}else{pic.removeAttribute('src');pic.style.display='none';name.textContent=''}
}
function openNativeStageIntro(b,done){
  if(!battleState||battleState.mode!=='campaign'||!b){done?.();return}stageIntroContinue=typeof done==='function'?done:null;renderNativeStageIntro(b);playNativeFormOpenSfx('form_stageintro');const o=document.getElementById('stageintro-overlay');o?.classList.add('show');o?.setAttribute('aria-hidden','false')
}
function resetNativeStageIntro(){
  const o=document.getElementById('stageintro-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');stageIntroContinue=null
}
function closeNativeStageIntro(){
  const o=document.getElementById('stageintro-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');const done=stageIntroContinue;stageIntroContinue=null;done?.()
}
function beginNativeCampaignBattleAfterIntro(){if(!battleState||battleState.ended)return;fireNativeRoundDialogues(1);if(!battleState.dialogueActive)writeBattleSave('auto',true)}
document.getElementById('stageintro-close')?.addEventListener('click',e=>{e.stopPropagation();closeNativeStageIntro()});

async function loadBattleSave(slot){
  const raw=readBattleSave(slot);if(!raw){flash('这个存档槽是空的');return false}
  await loadDB();const p=EW4BattleSave.normalize(raw),b=DB.battles.find(x=>x.file===p.battleFile);if(!b){flash('找不到该存档对应的原版关卡',2600);return false}
  hideBattleModals();await openBattle(b,p.map,{mode:p.mode,playerOwner:p.playerOwner,assignments:p.assignments,restore:p});flash(`已读取 ${p.battleTitle} · 回合 ${p.round}`);return true
}
function owns(id){return saveState.owned.includes(+id)}
function acquire(id){id=+id;if(!owns(id)){saveState.owned.push(id);persist();return true}return false}
function commanderList(){return Object.values(COMMANDERS||{}).filter(c=>+c.id>=1&&+c.id<=208).sort((a,b)=>(+b.star-+a.star)||(+a.id-+b.id))}
function commanderName(c){return c?(STRINGS?.[`name_${c.name}`]||c.name):''}
function armyName(n){return STRINGS?.[`name_${n}`]||n}
function spriteFile(k){return SPRITES?.[k]?.file||''}
function portrait(id){return PORTRAITS?.[String(id)]||''}
function stars(n){return '★'.repeat(Math.max(0,Math.min(8,+n||0)))}
function skillName(id){return STRINGS?.[`name_skill_${String(+id+1).padStart(2,'0')}`]||`技能${id}`}
function itemName(it){return it?(STRINGS?.[`name_${it.name}`]||it.name):'空'}
function itemDesc(it){return it?(STRINGS?.[`desc_${it.name}`]||''):''}
function itemIcon(it){return it?ITEM_ICONS?.[it.name]?.file||'':''}
function baseEquipmentSlots(c){return c?EW4ItemInventory.normalizeSlots([c.item1,c.item2]):[null,null]}
function equipmentSlotsForCommander(c){if(!c)return[null,null];const override=saveState.equipment?.[String(c.id)];return Array.isArray(override)?EW4ItemInventory.normalizeSlots(override):baseEquipmentSlots(c)}
function baseSkillIds(c){return c?[c.skill1,c.skill2,c.skill3,c.skill4].map(Number).filter(x=>x>=0):[]}
function playerOverride(c){if(!c)return null;return PLAYER_OVERRIDES?.generals?.[String(c.id)]||PLAYER_PRINCESS_OVERRIDES?.princesses?.[String(c.id)]||null}
function effectiveCommander(c,playerControlled=false){
  if(!c||!playerControlled)return c;
  const o=playerOverride(c),out={...c,...(o?.stats||{})};
  const persisted=saveState.generalStats?.[String(c.id)];
  if(persisted&&typeof persisted==='object')for(const stat of ['infantry','cavalry','artillery','warship','fort','business','movement','training'])if(Number.isFinite(+persisted[stat]))out[stat]=Math.max(+out[stat]||0,+persisted[stat]);
  out.skills=[...new Set([...baseSkillIds(c),...(o?.addSkills||[]).map(Number)])];
  if(o){out.playerEnhanced=true;out.rankHpBonusCap=+o.rankHpBonusCap||+PLAYER_OVERRIDES?.global?.rankHpBonusCap||500;out.nobilityHealCap=+o.nobilityHealCap||+PLAYER_OVERRIDES?.global?.nobilityHealCap||25}
  return out;
}
function effectiveCommanderForUnit(u){const c=u?.commander_id?COMMANDERS?.[String(u.commander_id)]:null;return effectiveCommander(c,!!u&&isMine(u))}
function rankLevel(c){return Math.max(0,Math.min(+PLAYER_OVERRIDES?.global?.rankMaxLevel||14,+(saveState.rank?.[String(c.id)]??c.rank??0)))}
function nobilityLevel(c){return Math.max(0,Math.min(+PLAYER_OVERRIDES?.global?.nobilityMaxLevel||9,+(saveState.nobility?.[String(c.id)]??c.nobilityrank??0)))}
function rankProgress(c){return Math.max(0,Math.trunc(+(saveState.rankProgress?.[String(c.id)]||0)))}
function nobilityProgress(c){return Math.max(0,Math.trunc(+(saveState.nobilityProgress?.[String(c.id)]||0)))}
function setGeneralGrowth(c,{rank=rankLevel(c),militaryProgress=rankProgress(c),nobility=nobilityLevel(c),nobleProgress=nobilityProgress(c)}={}){const id=String(c.id);saveState.rank[id]=Math.max(0,Math.min(EW4NativeGeneral.MILITARY_MAX,Math.trunc(+rank||0)));saveState.nobility[id]=Math.max(0,Math.min(EW4NativeGeneral.NOBILITY_MAX,Math.trunc(+nobility||0)));saveState.rankProgress[id]=saveState.rank[id]>=EW4NativeGeneral.MILITARY_MAX?0:Math.max(0,Math.trunc(+militaryProgress||0));saveState.nobilityProgress[id]=saveState.nobility[id]>=EW4NativeGeneral.NOBILITY_MAX?0:Math.max(0,Math.trunc(+nobleProgress||0))}
function nativeGeneralGrowthContext(c){
  if(!c)return{items:[],skills:[]};const ec=effectiveCommander(c,true),items=equipmentSlotsForCommander(c).map(id=>id==null?null:ITEMS?.[String(id)]).filter(Boolean);return{items,skills:Array.isArray(ec?.skills)?ec.skills:baseSkillIds(ec)}
}
function awardNativeGeneralCombatGrowth(attacker,victim,damage,killed=false){
  if(!battleState||!attacker||attacker.dead||!isMine(attacker)||!attacker.commander_id)return null;const c=COMMANDERS?.[String(attacker.commander_id)];if(!c||!owns(c.id))return null;
  const beforeRank=rankLevel(c),beforeNob=nobilityLevel(c),beforeHpBonus=playerRankHpBonus(c),ctx=nativeGeneralGrowthContext(c),milGain=EW4NativeGeneral.battleMilitaryGain(damage,ctx),nobGain=killed?EW4NativeGeneral.battleNobilityGain(victim?.grade,victim?.commander_id!=null,ctx):0;
  let m={level:beforeRank,progress:rankProgress(c)},n={level:beforeNob,progress:nobilityProgress(c)};if(milGain>0)m=EW4NativeGeneral.addMilitaryProgress(m.level,m.progress,milGain);if(nobGain>0)n=EW4NativeGeneral.addNobilityProgress(n.level,n.progress,nobGain);
  if(m.level===beforeRank&&m.progress===rankProgress(c)&&n.level===beforeNob&&n.progress===nobilityProgress(c))return null;setGeneralGrowth(c,{rank:m.level,militaryProgress:m.progress,nobility:n.level,nobleProgress:n.progress});
  const rankLeveled=m.level>beforeRank,nobLeveled=n.level>beforeNob;if(rankLeveled){const afterHpBonus=playerRankHpBonus(c),delta=Math.max(0,afterHpBonus-beforeHpBonus);if(delta>0){attacker.max_hp=(+attacker.max_hp||0)+delta;attacker.hp=Math.min(attacker.max_hp,(+attacker.hp||0)+delta);attacker.playerCommanderHpBonus=afterHpBonus}playNativeSfxFile('sfx_lvup2.wav');spawnBattleFloat(attacker.q,attacker.r,'军衔提升','#ffd66b')}
  if(nobLeveled){playNativeSfxFile('sfx_lvup2.wav');spawnBattleFloat(attacker.q,attacker.r,'爵位提升','#f0b7ff')}
  persist();return{commanderId:+c.id,militaryGain:milGain,nobilityGain:nobGain,rankLeveled,nobilityLeveled,rank:m.level,nobility:n.level}
}
function playerRankHpBonus(c){if(!c)return 0;const max=+PLAYER_OVERRIDES?.global?.rankMaxLevel||14,cap=+c.rankHpBonusCap||+PLAYER_OVERRIDES?.global?.rankHpBonusCap||500;return Math.round(cap*rankLevel(c)/max)}
function playerNobilityHeal(c){if(!c)return 0;const max=+PLAYER_OVERRIDES?.global?.nobilityMaxLevel||9,cap=+c.nobilityHealCap||+PLAYER_OVERRIDES?.global?.nobilityHealCap||25;return Math.round(cap*nobilityLevel(c)/max)}
function applyPlayerCommanderHp(u){const c=effectiveCommanderForUnit(u);if(!c||!isMine(u))return;const bonus=playerRankHpBonus(c);if(bonus<=0)return;u.playerCommanderHpBonus=bonus;u.max_hp=(+u.max_hp||0)+bonus;u.hp=(+u.hp||0)+bonus}
function commanderMovementBonus(u){const c=effectiveCommanderForUnit(u),st=armyStat(u);let n=0;if(c){/* EW4: land units use commander movement stars; regular navy does not. */if(st.type!=='warship')n+=+c.movement||0;if(st.type==='artillery'&&EW4Combat.hasSkill(c,6))n+=2;if(st.type==='warship'&&EW4Combat.hasSkill(c,18))n+=1}for(const id of equippedItemIds(u)){const it=ITEMS?.[String(id)];if(!it||!itemTargetMatches(it,st))continue;if(+it.function===9)n+=+it.value||0}return n}
function effectiveMovePoints(u){const st=armyStat(u);return EW4PlayerUnitRules.effectiveMovement(+st.movement||0,st.type,isMine(u))+commanderMovementBonus(u)}

function bgVolume(){return clampSettingPercent(saveState.bgVol)/100}
function seVolume(){return clampSettingPercent(saveState.seVol)/100}
function playSfx(n){const a=audio[n];if(!a||seVolume()<=0)return;try{a.currentTime=0;a.volume=seVolume();a.play().catch(()=>{})}catch(e){}}
const nativeSfxBases=new Map();
function playNativeSfxFile(file){if(!file||seVolume()<=0)return false;try{let base=nativeSfxBases.get(file);if(!base){base=new Audio(`assets/audio/${file}`);base.preload='auto';nativeSfxBases.set(file,base)}const a=base.cloneNode(true);a.volume=seVolume();a.play().catch(()=>{});return true}catch(e){return false}}
function playNativeFormOpenSfx(formId){const file=EW4NativeUIAudio?.formOpenSfx?.(formId);return file?playNativeSfxFile(file):false}
function playNativeActionSfx(action){const file=window.EW4NativeActionAudio?.actionSfx?.(action);return file?playNativeSfxFile(file):false}
function playNativeMovementSfx(u){const file=window.EW4NativeActionAudio?.movementSfx?.(u,armyStat(u));return file?playNativeSfxFile(file):false}
function scheduleNativeAttackSfx(u,target,presentationSpeed=1){if(!u||!target||!NATIVE_EFFECT_AUDIO_DATA||!window.EW4NativeEffectAudio)return false;const dx=(+target.q||0)-(+u.q||0),dir=EW4NativeEffectAudio.directionFromDelta(dx||1),timeline=EW4NativeEffectAudio.resolveTimeline(u,dir,countryCode(u.owner)),cues=EW4NativeEffectAudio.scheduledCues(NATIVE_EFFECT_AUDIO_DATA,timeline,presentationSpeed);if(!cues.length)return false;const battleRef=battleState;for(const cue of cues){const fire=()=>{if(battleState!==battleRef||activeScreenId()!=='battle')return;if(cue.sound)playNativeSfxFile(cue.sound);if(cue.effect)spawnNativeAttackTimelineEffect(cue.effect,u,cue)};if(cue.delayMs<=1)fire();else setTimeout(fire,cue.delayMs)}return true}
function scheduleNativeImpactTimeline(attacker,target,damage,impactDelayMs=0,presentationSpeed=1){if(!attacker||!target||!NATIVE_EFFECT_AUDIO_DATA||!window.EW4NativeImpactEffect||!window.EW4NativeEffectAudio)return false;if(battleState?.aiFastForward&&!isMine(attacker))return false;const ast=armyStat(attacker),tst=armyStat(target),A=worldPoint(attacker.q,attacker.r),B=worldPoint(target.q,target.r),timeline=EW4NativeImpactEffect.resolveTimeline({attackerArmyId:attacker.army_id,weapon:ast.weapon,targetType:tst.type,targetSea:terrainCell(target.q,target.r)?.type==='sea',damage,dx:B.x-A.x}),cues=EW4NativeEffectAudio.scheduledCues(NATIVE_EFFECT_AUDIO_DATA,timeline,presentationSpeed);if(!cues.length)return false;const battleRef=battleState,q=target.q,r=target.r,baseDelay=Math.max(0,+impactDelayMs||0);for(const cue of cues){const fire=()=>{if(battleState!==battleRef||activeScreenId()!=='battle')return;if(cue.sound)playNativeSfxFile(cue.sound);if(cue.effect)spawnNativeCellTimelineEffect(cue.effect,q,r,cue)};const delay=baseDelay+(+cue.delayMs||0);if(delay<=1)fire();else setTimeout(fire,delay)}return true}
function configureBattleCanvasBacking(stageScale=1){
  /* Keep all recovered EW4 geometry in the original 568x320 logical space, but
     rasterize the battlefield at device resolution. The former 568x320 backing
     bitmap was then CSS-scaled on modern iPhones, softening the map and every
     BILE/unit overlay together. */
  const dpr=Math.max(1,+globalThis.devicePixelRatio||1),raw=dpr*Math.max(.25,+stageScale||1),target=Math.max(1,Math.min(MAX_BATTLE_BACKING_SCALE,Math.ceil(raw*2)/2));
  const w=BATTLE_LOGICAL_W*target,h=BATTLE_LOGICAL_H*target;
  if(canvas.width!==w||canvas.height!==h){canvas.width=w;canvas.height=h}
  battleBackingScale=target;
  ctx.setTransform(battleBackingScale,0,0,battleBackingScale,0,0);
  ctx.imageSmoothingEnabled=true;try{ctx.imageSmoothingQuality='high'}catch(e){}
}
function resize(){const vv=globalThis.visualViewport,vw=Math.max(1,+vv?.width||innerWidth),vh=Math.max(1,+vv?.height||innerHeight),s=Math.min(vw/BATTLE_LOGICAL_W,vh/BATTLE_LOGICAL_H);stage.style.transform=`translate(-50%,-50%) scale(${s})`;configureBattleCanvasBacking(s);document.getElementById('rotate-tip').style.display=(vh>vw*1.25)?'flex':'none';if(battleState&&activeScreenId()==='battle')renderBattle()}
addEventListener('resize',resize);globalThis.visualViewport?.addEventListener('resize',resize);resize();
function go(id){if(id!=='campaign')closeNativeCampaignInfo();if(id!=='campaignList')closeNativeUpgrade();const previous=activeScreenId(),opt=document.getElementById('options');if(id==='options'&&previous!=='options'){playNativeFormOpenSfx('form_option');beginNativeOptions();const overBattle=previous==='battle';screens.forEach(s=>s.classList.toggle('active',s.id===id||(overBattle&&s.id==='battle')));opt?.classList.toggle('battle-overlay',overBattle);if(!overBattle)pauseBattleMusic();if(battleState)battleState.dragging=false;return}opt?.classList.remove('battle-overlay');screens.forEach(s=>s.classList.toggle('active',s.id===id));if(id==='conquest')buildConquests();if(id==='academy')renderAcademy();if(id==='battle')startBattleMusic();else{pauseBattleMusic();if(battleState)battleState.dragging=false}if(id==='main'&&continueBattlePendingZone>0){const zone=continueBattlePendingZone;continueBattlePendingZone=0;requestAnimationFrame(()=>openZone(zone))}}
document.addEventListener('click',e=>{const g=e.target.closest('[data-go]');if(g){if(g.dataset.go==='options')optionsReturnScreen=activeScreenId()==='battle'?'battle':'main';if(g.dataset.go==='academy')academyReturnScreen='deploy';go(g.dataset.go)}});
const mainHqBtn=document.getElementById('main-hq');if(mainHqBtn)mainHqBtn.onclick=openHeadquartersDeployment;
function renderNativeAchievement(){
  if(!window.EW4NativeAchievement||!COMMANDERS)return;const vm=EW4NativeAchievement.viewModel(saveState,COMMANDERS),set=(id,v)=>{const el=document.getElementById(id);if(el)el.textContent=String(v??'--')};
  set('achievement-stars-value',`${vm.stageStars.earned}/${vm.stageStars.max}`);
  set('achievement-military-level',`Lv ${vm.military.level}`);set('achievement-military-score',vm.military.score);
  set('achievement-nobility-level',`Lv ${vm.nobility.level}`);set('achievement-nobility-score',vm.nobility.score);
  for(const key of ['europe','america','asia']){const box=document.querySelector(`.achievement-rule[data-region="${key}"]`),rec=vm.continents[key];if(!box)continue;const marks=box.querySelector('.rule-marks');marks.innerHTML=(rec.digits||[0]).map(n=>`<img src="assets/sprites/image_ui_hd/rule_${Math.max(0,Math.min(9,+n||0))}.png" alt="">`).join('')}
  const root=document.getElementById('achievement-generals');if(root){root.innerHTML='';for(const id of vm.generalIds){const c=COMMANDERS?.[String(id)];if(!c)continue;const el=document.createElement('button');el.className='achievement-general';el.dataset.commanderId=String(id);el.innerHTML=`<img src="${portrait(id)}" alt=""><span>${commanderName(c)}</span>`;root.appendChild(el)}if(!root.childElementCount)root.innerHTML='<div class="achievement-general empty"></div>'}
}
async function openNativeAchievement(){await loadDB();renderNativeAchievement();playNativeFormOpenSfx('form_achivement');go('achievement')}
document.getElementById('main-achievement')?.addEventListener('click',e=>{e.stopPropagation();openNativeAchievement()});document.getElementById('achievement-back')?.addEventListener('click',e=>{e.stopPropagation();go('main')});document.getElementById('achievement-champion')?.addEventListener('click',e=>{e.stopPropagation();playSfx('select')});document.getElementById('achievement-ranking')?.addEventListener('click',e=>{e.stopPropagation();playSfx('select')});
function flash(t,ms=1700){statusEl.textContent=t;statusEl.style.display='block';clearTimeout(flash.t);flash.t=setTimeout(()=>statusEl.style.display='none',ms)}
async function fetchJSON(path){const r=await fetch(path);if(!r.ok)throw new Error(path+' '+r.status);return r.json()}
function renderNativeLoading(strings=STRINGS){
  const desc=document.getElementById('loading-desc'),label=document.getElementById('loading-text');
  // Native x86_64 form_loading chooses one of text_tips_1..24 at construction time.
  const tip=1+Math.floor(Math.random()*24);
  if(desc)desc.textContent=strings?.[`text_tips_${tip}`]||'';
  if(label)label.textContent=strings?.text2_loading||'载入……';
}
async function bootNativeApp(){
  try{
    if(!STRINGS)STRINGS=await fetchJSON('assets/data/strings_cn.json');
    renderNativeLoading(STRINGS);
    await loadDB();
    academyPool=saveState.academyPool||'6';
    const qs=new URLSearchParams(location.search),auto=qs.get('autobattle');
    if(auto){
      const b=DB.battles.find(x=>x.file===auto||x.file===`${auto}.btl`);
      if(b){await openBattle(b,b.header.map_id===2?'america':'europe',{mode:'campaign',playerOwner:+qs.get('owner')||b.player_owner_default||0,assignments:new Map()});return}
    }
    go('main');
  }catch(e){
    const label=document.getElementById('loading-text');if(label)label.textContent='载入失败';
    flash('资源加载失败：'+e.message,4000);
  }
}
function compactBileResource(name){return COMPACT_BILE_RESOURCES.get(name)||null}
function preloadCompactBileResource(name){
  if(!name||!COMPACT_BILE_PACK)return Promise.resolve(null);
  if(COMPACT_BILE_RESOURCES.has(name))return Promise.resolve(COMPACT_BILE_RESOURCES.get(name));
  if(COMPACT_BILE_PROMISES.has(name))return COMPACT_BILE_PROMISES.get(name);
  const p=COMPACT_BILE_PACK.loadResource(name).then(r=>{
    const atlas=img(r.atlasUrl),rec={...r,atlas};COMPACT_BILE_RESOURCES.set(name,rec);COMPACT_BILE_PROMISES.delete(name);
    if(atlas){const old=atlas.onload;atlas.onload=()=>{if(typeof old==='function')old.call(atlas);requestBattleAnimation(80)}}
    requestBattleAnimation(80);return rec
  }).catch(e=>{COMPACT_BILE_PROMISES.delete(name);console.warn('compact BILE load failed',name,e);return null});
  COMPACT_BILE_PROMISES.set(name,p);return p
}
async function fetchText(path){const r=await fetch(path);if(!r.ok)throw new Error(path+' '+r.status);return r.text()}
async function fetchBuffer(path){const r=await fetch(path);if(!r.ok)throw new Error(path+' '+r.status);return r.arrayBuffer()}
function loadNativeMapTextBase(){
  if(MAPTEXT_BILE&&MAPTEXT_ATLAS)return Promise.resolve({bile:MAPTEXT_BILE,atlas:MAPTEXT_ATLAS});
  if(MAPTEXT_BASE_PROMISE)return MAPTEXT_BASE_PROMISE;
  MAPTEXT_BASE_PROMISE=Promise.all([fetchBuffer('assets/maptext_native/maptext.bin'),fetchText('assets/maptext_native/maptext.xml')]).then(([bin,xml])=>{
    MAPTEXT_BILE=new EW4CompactBile.Bile(bin,xml);MAPTEXT_ATLAS=img('assets/maptext_native/maptext.png');return{bile:MAPTEXT_BILE,atlas:MAPTEXT_ATLAS}
  }).catch(e=>{MAPTEXT_BASE_PROMISE=null;console.warn('native maptext base load failed',e);return null});return MAPTEXT_BASE_PROMISE
}
function loadNativeGetMedalEffect(){
  if(GETMEDAL_BILE&&GETMEDAL_ATLAS)return Promise.resolve({bile:GETMEDAL_BILE,atlas:GETMEDAL_ATLAS});
  if(GETMEDAL_PROMISE)return GETMEDAL_PROMISE;
  GETMEDAL_PROMISE=Promise.all([fetchBuffer('assets/effects/anim_upgrade/anim_upgrade.bin'),fetchText('assets/effects/anim_upgrade/anim_upgrade.xml')]).then(([bin,xml])=>{
    GETMEDAL_BILE=new EW4CompactBile.Bile(bin,xml);GETMEDAL_ATLAS=img('assets/effects/anim_upgrade/anim_upgrade.png');requestBattleAnimation(80);return{bile:GETMEDAL_BILE,atlas:GETMEDAL_ATLAS}
  }).catch(e=>{GETMEDAL_PROMISE=null;console.warn('native getmedal effect load failed',e);return null});return GETMEDAL_PROMISE
}
function spawnNativeGetMedalEffect(u){
  if(!battleState||!u)return false;const now=performance.now();(battleState.getMedalEffects||(battleState.getMedalEffects=[])).push({unitIndex:+u.index,q:+u.q,r:+u.r,start:now,until:now+2000});loadNativeGetMedalEffect();requestBattleAnimation(2080);return true
}
function drawNativeGetMedalEffects(){
  if(!battleState?.getMedalEffects?.length)return;const now=performance.now();battleState.getMedalEffects=battleState.getMedalEffects.filter(e=>{
    if(now>=e.until)return false;if(GETMEDAL_BILE&&GETMEDAL_ATLAS?.complete){const u=battleState.units.find(x=>+x.index===+e.unitIndex&&!x.dead),p=u?unitScreenPoint(u):screenPoint(e.q,e.r),info=GETMEDAL_BILE.motionInfo('getmedal'),frame=Math.min(info.frameCount-1,Math.max(0,Math.floor(((now-e.start)/1000)*info.fps))),scale=1.3*unitVisualZoom(battleState.camera.zoom);GETMEDAL_BILE.drawFrame(ctx,info.itemIndex,frame,GETMEDAL_ATLAS,p.x,p.y,scale,1)}return true
  })
}
function loadNativeMapText(map){
  if(MAPTEXT_PLACEMENTS.has(map))return Promise.resolve(MAPTEXT_PLACEMENTS.get(map));
  if(MAPTEXT_PLACEMENT_PROMISES.has(map))return MAPTEXT_PLACEMENT_PROMISES.get(map);
  const file=map==='america'?'maptextpos_america.xml':'maptextpos_europe.xml';
  const p=Promise.all([loadNativeMapTextBase(),fetchText(`assets/maptext_native/${file}`)]).then(([base,xml])=>{
    if(!base||!window.EW4NativeMapText)return null;const rows=EW4NativeMapText.preparePlacements(base.bile,EW4NativeMapText.parsePlacements(xml));MAPTEXT_PLACEMENTS.set(map,rows);MAPTEXT_PLACEMENT_PROMISES.delete(map);requestBattleAnimation(80);return rows
  }).catch(e=>{MAPTEXT_PLACEMENT_PROMISES.delete(map);console.warn('native maptext placement load failed',map,e);return null});MAPTEXT_PLACEMENT_PROMISES.set(map,p);return p
}
function drawNativeMapTextWorld(map,c){
  const rows=MAPTEXT_PLACEMENTS.get(map);if(!rows?.length||!MAPTEXT_BILE||!MAPTEXT_ATLAS?.complete||!window.EW4NativeMapText)return;
  const margin=100/c.zoom,b={left:c.x-284/c.zoom-margin,right:c.x+284/c.zoom+margin,top:c.y-160/c.zoom-margin,bottom:c.y+160/c.zoom+margin};
  for(const p of rows)if(EW4NativeMapText.intersects(p,b))EW4NativeMapText.drawPrepared(ctx,MAPTEXT_BILE,MAPTEXT_ATLAS,p)
}
async function loadDB(){if(DB)return DB;[DB,WORLDS,ARMIES,COMMANDERS,READY,ATTACK_POSES,RELOAD_POSES,FINISH_POSES,TERRAIN,PORTRAITS,SPRITES,STRINGS,CONSTRUCTIONS,CARDS,ITEMS,ITEM_ICONS,PLAYER_OVERRIDES,PLAYER_PRINCESS_OVERRIDES,INSTALLATIONS,BUILD_CARDS,BATTLE_NATIVE,NATIVE_TRIGGER_TARGETS,BATTLE_ITEMSTORES,BATTLE_TAVERNS,NATIVE_ANIM_PACK,NATIVE_EFFECT_AUDIO_DATA,NATIVE_SIMPLE_EFFECTS_DATA,NATIVE_TUTORIAL_SCRIPTS,NATIVE_CAMPAIGN_TARGETS,NATIVE_WARZONE_TECH,NATIVE_BATTLELINE_XML]=await Promise.all([
 fetchJSON('assets/data/battles_runtime.json'),fetchJSON('assets/data/worldmaps.json'),fetchJSON('assets/data/army_stats.json'),fetchJSON('assets/data/commanders.json'),fetchJSON('assets/data/unit_ready_manifest.json'),fetchJSON('assets/data/unit_attack_manifest.json'),fetchJSON('assets/data/unit_reload_manifest.json'),fetchJSON('assets/data/unit_finish_manifest.json'),fetchJSON('assets/data/terrain_manifest.json'),fetchJSON('assets/data/portrait_manifest.json'),fetchJSON('assets/sprite_manifest.json'),STRINGS||fetchJSON('assets/data/strings_cn.json'),fetchJSON('assets/data/constructions.json'),fetchJSON('assets/data/cards.json'),fetchJSON('assets/data/items.json'),fetchJSON('assets/data/item_icon_manifest.json'),fetchJSON('assets/data/player_general_overrides.json'),fetchJSON('assets/data/player_princess_overrides.json'),fetchJSON('assets/data/installations.json'),fetchJSON('assets/data/build_cards.json'),fetchJSON('assets/data/battle_native_triggers.json'),fetchJSON('assets/data/native_trigger_targets.json'),fetchJSON('assets/data/battle_itemstores.json'),fetchJSON('assets/data/battle_taverns.json'),fetchJSON('assets/data/native_animation_core877.json'),fetchJSON('assets/data/native_effects_audio.json'),fetchJSON('assets/data/native_simple_effects.json'),fetchJSON('assets/data/native_tutorial_scripts.json'),fetchJSON('assets/data/native_campaign_targets.json'),fetchJSON('assets/data/native_warzone_tech.json'),fetchText('assets/data/def_battleline.xml')]);NATIVE_BATTLELINES=EW4NativeCampaignLine.parse(NATIVE_BATTLELINE_XML);saveState.warzoneTech=EW4NativeUpgrade.normalizeZones(saveState.warzoneTech,NATIVE_WARZONE_TECH);saveState.campaignStars=EW4NativeUpgrade.clampStars(saveState.campaignStars);if(window.EW4CompactBile&&!COMPACT_BILE_PACK){COMPACT_BILE_PACK=new EW4CompactBile.BrowserPack('assets/bile_runtime');await COMPACT_BILE_PACK.loadManifest()}saveState.itemInventory=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS);ensureAcademyCandidatesPersisted();persist();return DB}


/* ---------- Native tutorial script executor (P15) ---------- */
let nativeTutorialRunner=null,nativeTutorialHighlight=null,nativeTutorialBattleFile='';
function nativeTutorialActive(){return !!(nativeTutorialRunner&&!nativeTutorialRunner.done&&battleState?.mode==='tutorial')}
function tutorialAreaId(q,r){return Math.trunc(+q)+EW4NativeTutorial.MAP_WIDTH*Math.trunc(+r)}
function bindTutorialUI(el,name,row=null){if(!el||!name)return el;el.dataset.tutorialUi=String(name);if(row==null)delete el.dataset.tutorialRow;else el.dataset.tutorialRow=String(row);return el}
function tutorialVisibleElement(list){return [...list].find(el=>{const r=el.getBoundingClientRect();const st=getComputedStyle(el);return st.display!=='none'&&st.visibility!=='hidden'&&r.width>0&&r.height>0})||null}
function tutorialElement(name,row=null){
  if(name==='group_res')return document.querySelector('#battle .resource-board')||document.querySelector('#battle .hud');
  if(name==='group_incom')return document.getElementById('facility-summary');
  if(name==='btn_next')return document.getElementById('round-btn');
  if(name==='btn_undo')return document.getElementById('battle-undo');
  if(name==='btn_done')return document.getElementById('native-funcres-confirm');
  if(name==='winbtn_back')return document.getElementById('deploy-back');
  if(name==='grid_general'){const rows=document.querySelectorAll('#deploy-generals .deploy-native-general');return rows[Math.max(0,+row||0)]||null}
  const all=[...document.querySelectorAll('[data-tutorial-ui]')].filter(el=>el.dataset.tutorialUi===String(name)&&(row==null||+el.dataset.tutorialRow===+row));
  return tutorialVisibleElement(all)
}
function tutorialStageRect(el){if(!el)return null;const sr=stage.getBoundingClientRect(),r=el.getBoundingClientRect(),sx=sr.width/568||1,sy=sr.height/320||1;return{x:(r.left-sr.left)/sx,y:(r.top-sr.top)/sy,w:r.width/sx,h:r.height/sy}}
function positionNativeTutorialHighlight(){
  const h=document.getElementById('tutorial-runtime-highlight');if(!h||!nativeTutorialHighlight){h?.classList.remove('show');return}
  let r=null;
  if(nativeTutorialHighlight.type==='ui'){r=tutorialStageRect(tutorialElement(nativeTutorialHighlight.name,nativeTutorialHighlight.row));const c=nativeTutorialHighlight.command;if(r&&c){if(c.w!=null)r.w=Math.max(8,r.w+(+c.w||0));if(c.h!=null)r.h=Math.max(8,r.h+(+c.h||0))}}
  else if(nativeTutorialHighlight.type==='world'&&battleState){const c=nativeTutorialHighlight.command,cell=EW4NativeTutorial.areaCell(c.id),p=cell?screenPoint(cell.q,cell.r):null;if(p)r={x:p.x+(+c.x||0)*battleState.camera.zoom,y:p.y+(+c.y||0)*battleState.camera.zoom,w:Math.max(8,(+c.w||34)*battleState.camera.zoom),h:Math.max(8,(+c.h||34)*battleState.camera.zoom)}}
  if(!r){h.classList.remove('show');return}h.style.left=`${Math.round(r.x)}px`;h.style.top=`${Math.round(r.y)}px`;h.style.width=`${Math.max(8,Math.round(r.w))}px`;h.style.height=`${Math.max(8,Math.round(r.h))}px`;h.classList.add('show')
}
function setNativeTutorialHighlight(v){nativeTutorialHighlight=v||null;positionNativeTutorialHighlight();if(nativeTutorialHighlight&&typeof requestAnimationFrame==='function'){const ref=nativeTutorialHighlight;requestAnimationFrame(()=>{if(nativeTutorialHighlight===ref)positionNativeTutorialHighlight()})}}
function clearNativeTutorialHighlight(){setNativeTutorialHighlight(null)}
function showNativeTutorialText(id){const box=document.getElementById('tutorial-runtime-text'),v=document.getElementById('tutorial-runtime-textvalue');if(!box||!v)return;v.textContent=STRINGS?.[`desc_tutorials_word_${id}`]||`教程 ${id}`;box.classList.add('show')}
function hideNativeTutorialText(){document.getElementById('tutorial-runtime-text')?.classList.remove('show')}
function clearNativeTutorialRuntime({leaveBattle=false}={}){nativeTutorialRunner=null;nativeTutorialBattleFile='';nativeTutorialHighlight=null;const o=document.getElementById('tutorial-runtime-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');hideNativeTutorialText();clearNativeTutorialHighlight();if(leaveBattle&&battleState?.mode==='tutorial')go('tutorial')}
function tutorialNotifyTouch(){if(nativeTutorialActive())nativeTutorialRunner.notifyTouch()}
function tutorialNotifyArea(q,r){if(nativeTutorialActive())nativeTutorialRunner.notifyArea(tutorialAreaId(q,r))}
function tutorialNotifyUI(name,row=null){if(nativeTutorialActive())nativeTutorialRunner.notifyUI(name,row)}
function tutorialNotifyAction(delay=0){if(!nativeTutorialActive())return;if(delay>0){const ref=nativeTutorialRunner;setTimeout(()=>{if(nativeTutorialRunner===ref&&nativeTutorialActive())ref.notifyAction()},delay)}else nativeTutorialRunner.notifyAction()}
function selectNativeTutorialArea(cell){if(!battleState||!cell)return;const u=unitAt(cell.q,cell.r);if(u){selectUnit(u);return}const o=objectAt(cell.q,cell.r);if(o){selectFacility(o);return}selectEmptyCell(cell)}
function unselectNativeTutorialArea(cell){if(!battleState)return;const sameUnit=battleState.selected&&cell&&battleState.selected.q===cell.q&&battleState.selected.r===cell.r,sameObj=battleState.selectedObject&&cell&&battleState.selectedObject.q===cell.q&&battleState.selectedObject.r===cell.r,sameCell=battleState.selectedCell&&cell&&battleState.selectedCell.q===cell.q&&battleState.selectedCell.r===cell.r;if(sameUnit||sameObj||sameCell||!cell)selectUnit(null)}
function startNativeTutorialForBattle(){
  clearNativeTutorialRuntime();if(!battleState||battleState.mode!=='tutorial'||!window.EW4NativeTutorial)return false;const raw=NATIVE_TUTORIAL_SCRIPTS?.scripts?.[battleState.battle.file];if(!raw?.commands?.length)return false;
  const overlay=document.getElementById('tutorial-runtime-overlay');overlay?.classList.add('show');overlay?.setAttribute('aria-hidden','false');nativeTutorialBattleFile=battleState.battle.file;
  nativeTutorialRunner=new EW4NativeTutorial.Runner({
    onShowText:id=>showNativeTutorialText(id),onHideText:hideNativeTutorialText,
    onDrawUIRect:c=>setNativeTutorialHighlight({type:'ui',name:c.string,row:c.row,command:c}),onDrawWorldRect:c=>setNativeTutorialHighlight({type:'world',command:c}),onClearRect:clearNativeTutorialHighlight,
    onMoveToArea:cell=>{if(!cell||!battleState)return;const p=worldPoint(cell.q,cell.r),z=battleState.camera.zoom<CAMERA_DETAIL_ZOOM?1:null;startNativeProgrammaticCamera(p,{targetZoom:z});requestBattleAnimation(260)},
    onSelectArea:selectNativeTutorialArea,onUnselectArea:unselectNativeTutorialArea,
    onExit:()=>{const file=nativeTutorialBattleFile;clearNativeTutorialRuntime();if(battleState?.mode==='tutorial'&&battleState?.battle?.file===file)go('tutorial')}
  });nativeTutorialRunner.start(raw.commands);positionNativeTutorialHighlight();return true
}
stage.addEventListener('pointerup',e=>{if(nativeTutorialActive())tutorialNotifyTouch()},true);
stage.addEventListener('click',e=>{if(!nativeTutorialActive())return;const el=e.target.closest?.('[data-tutorial-ui]');if(el)tutorialNotifyUI(el.dataset.tutorialUi,el.dataset.tutorialRow==null?null:+el.dataset.tutorialRow)},true);

/* ---------- Campaign / conquest / tutorial ---------- */
function campaignRows(zone){return DB.battles.filter(b=>new RegExp(`^campaign${zone}_[0-9]+\\.btl$`).test(b.file)).sort((a,b)=>a.file.localeCompare(b.file,undefined,{numeric:true}))}
function nativeStageTurnLimits(b){return window.EW4NativeResult?.stageTurnLimits?.(b)||{valid:false,win:0,best:0}}
function campaignCanonicalFile(bOrFile){if(typeof bOrFile==='string')return bOrFile;return EW4NativeCampaign?.canonicalFile?.(bOrFile)||String(bOrFile?.file||'')}
function campaignProgressLevel(file){return EW4NativeCampaignSession.progressLevel(saveState,file)}
function campaignBestRating(file){return EW4NativeCampaignSession.bestRating(saveState,file)}
function campaignTechRow(zone=selectedZone){return saveState.warzoneTech?.[String(Math.max(1,Math.min(6,+zone||1)))]||Array(26).fill(0)}
function campaignTechLevel(id,zone=selectedZone){return EW4NativeUpgrade.techLevel(saveState.warzoneTech,zone,id)}
function campaignArmyTechLevel(name,zone=selectedZone){const id=EW4NativeUpgrade.techIdForArmy(name);return id==null?0:campaignTechLevel(id,zone)}
function campaignFortTechLevel(name,zone=selectedZone){const id=EW4NativeUpgrade.techIdForFort(name);return id==null?0:campaignTechLevel(id,zone)}
let nativeUpgradePage=0,nativeUpgradeTechId=0;
const NATIVE_UPGRADE_ICONS=Object.freeze([
  'button_upgrade_militia.png','button_upgrade_line.png','button_upgrade_light.png','button_upgrade_grenadier.png','button_upgrade_guard.png','button_upgrade_machinegun.png',
  'button_upgrade_lightcavalry.png','button_upgrade_heavycavalry.png','button_upgrade_lancer.png','button_upgrade_armored.png',
  'button_upgrade_lightartillery.png','button_upgrade_heavyartillery.png','button_upgrade_fortressartillery.png','button_upgrade_rocket.png',
  'button_upgrade_ship1.png','button_upgrade_ship2.png','button_upgrade_ship3.png','button_upgrade_ship4.png',
  'button_upgrade_fortress1.png','button_upgrade_fortress2.png','button_upgrade_fortress3.png','button_upgrade_coastalartillery.png'
]);
function nativeUpgradeIcon(id){return `assets/sprites/image_ui_hd/${NATIVE_UPGRADE_ICONS[Math.max(0,Math.min(21,+id||0))]}`}
function nativeUpgradeLabel(id){const name=EW4NativeUpgrade.techName(id);return id<=21?armyName(name):name}
function renderNativeUpgrade(){
  const overlay=document.getElementById('upgrade-overlay');if(!overlay?.classList.contains('show'))return;saveState.warzoneTech=EW4NativeUpgrade.normalizeZones(saveState.warzoneTech,NATIVE_WARZONE_TECH);saveState.campaignStars=EW4NativeUpgrade.clampStars(saveState.campaignStars);
  const ids=EW4NativeUpgrade.pageTechIds(nativeUpgradePage);if(!ids.includes(nativeUpgradeTechId))nativeUpgradeTechId=ids[0];document.querySelectorAll('#upgrade-tabs [data-upgrade-page]').forEach(b=>b.classList.toggle('sel',+b.dataset.upgradePage===nativeUpgradePage));
  const grid=document.getElementById('upgrade-grid');grid.innerHTML='';for(const id of ids){const level=campaignTechLevel(id),display=EW4NativeUpgrade.displayLevel(level),b=document.createElement('button');b.className='upgrade-tech-cell'+(id===nativeUpgradeTechId?' sel':'');b.style.backgroundImage=`url('${nativeUpgradeIcon(id)}')`;b.title=nativeUpgradeLabel(id);const state=document.createElement('img');state.className='upgrade-state';state.src=`assets/sprites/image_ui_hd/${level<0?'button_upgrade_locked.png':`button_upgrade_lv${display}.png`}`;state.alt='';b.appendChild(state);b.onclick=e=>{e.stopPropagation();nativeUpgradeTechId=id;renderNativeUpgrade()};grid.appendChild(b)}
  const id=nativeUpgradeTechId,level=campaignTechLevel(id),display=EW4NativeUpgrade.displayLevel(level),cost=EW4NativeUpgrade.upgradeCost(id,level),max=level>=EW4NativeUpgrade.MAX_TECH_LEVEL,icon=nativeUpgradeIcon(id);document.getElementById('upgrade-selected-icon').src=icon;document.getElementById('upgrade-unit-icon').src=icon;document.getElementById('upgrade-tech-name').textContent=nativeUpgradeLabel(id);document.getElementById('upgrade-star-value').textContent=saveState.campaignStars;document.getElementById('upgrade-level-from').textContent=`LV${display}`;document.getElementById('upgrade-level-to').textContent=max?'MAX':`LV${display+1}`;document.getElementById('upgrade-cost').textContent=max?'—':cost;const ok=document.getElementById('upgrade-confirm');ok.disabled=max||!EW4NativeUpgrade.canUpgrade(saveState.campaignStars,id,level)
}
async function openNativeUpgrade(){await loadDB();saveState.warzoneTech=EW4NativeUpgrade.normalizeZones(saveState.warzoneTech,NATIVE_WARZONE_TECH);nativeUpgradePage=0;nativeUpgradeTechId=EW4NativeUpgrade.pageTechIds(0)[0];const o=document.getElementById('upgrade-overlay');o.classList.add('show');o.setAttribute('aria-hidden','false');playNativeFormOpenSfx('form_upgrade');renderNativeUpgrade()}
function closeNativeUpgrade(){const o=document.getElementById('upgrade-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true')}
function commitNativeUpgrade(){const id=nativeUpgradeTechId,level=campaignTechLevel(id),out=EW4NativeUpgrade.upgrade(saveState.warzoneTech,saveState.campaignStars,selectedZone,id);if(!out.ok){flash(out.reason==='stars'?'星星不足':'该科技已经满级');renderNativeUpgrade();return}saveState.warzoneTech=out.zones;saveState.campaignStars=out.stars;persist();playNativeSfxFile('sfx_lvup.wav');renderNativeUpgrade();flash(`${nativeUpgradeLabel(id)} 升至 LV${EW4NativeUpgrade.displayLevel(out.level)}`)}
function activeBattleTechLevel(id){if(!battleState||battleState.mode!=='campaign')return 0;const row=Array.isArray(battleState.campaignTech)?battleState.campaignTech:campaignTechRow(campaignZoneForBattle(battleState.battle));return Math.max(-1,Math.min(3,+row?.[id]||0))}
function activeArmyTechLevel(name){const id=EW4NativeUpgrade.techIdForArmy(name);return id==null?0:activeBattleTechLevel(id)}
function campaignSecretUnlocked(file){file=String(file||'');return !!saveState.campaignSecretUnlocks?.[file]||campaignProgressLevel(file)>0}
function campaignUnlocked(rows,index){return !!EW4NativeCampaign?.stageSelectable?.(rows,index,campaignProgressLevel,campaignSecretUnlocked)}
function recordCampaignSecretUnlocks(b){
  if(!b||battleState?.mode!=='campaign'||!EW4NativeCampaign?.yellowSecretCleared?.(battleState,NATIVE_CAMPAIGN_TARGETS,ownerAt))return[];
  const zone=campaignZoneForBattle(b),rows=campaignRows(zone),code=b?.countries?.find(c=>+c.index===+battleState.playerOwner)?.code||'',files=EW4NativeCampaign.hiddenUnlockFiles(rows,b,code,true);if(!files.length)return[];
  saveState.campaignSecretUnlocks=saveState.campaignSecretUnlocks||{};const fresh=[];for(const file of files)if(file&&!saveState.campaignSecretUnlocks[file]){saveState.campaignSecretUnlocks[file]=true;fresh.push(file)}if(fresh.length)persist();return fresh
}
function recordCampaignResult(b,rating){if(!b||battleState?.mode!=='campaign')return;const out=EW4NativeCampaignSession.recordResult(saveState,campaignCanonicalFile(b),rating);saveState=out.state;persist()}
function campaignIntroCommander(b){
  const owner=b?.player_owner_default??0;const unit=(b?.units||[]).find(u=>u.owner===owner&&u.commander_id)|| (b?.units||[]).find(u=>u.commander_id);return unit?.commander_id?COMMANDERS?.[String(unit.commander_id)]:null
}
async function openZone(zone){
  selectedZone=zone;await loadDB();const rows=campaignRows(zone);document.getElementById('campaign-list-title').textContent=zoneNames[zone];document.getElementById('campaign-stage-caption').innerHTML=`${zoneNames[zone]}<small>${rows.length} 个战役</small>`;const box=document.getElementById('battle-list');box.innerHTML='';selectedBattle=null;
  let preferred=-1;
  const zoneAsset={1:'france',2:'coalition',3:'holyroman',4:'east',5:'usa',6:'uk'}[zone]||'france';
  const visible=[];rows.forEach((b,i)=>{const unlocked=campaignUnlocked(rows,i);if(EW4NativeCampaign.originalHide(b)&&!campaignSecretUnlocked(campaignCanonicalFile(b)))return;const file=campaignCanonicalFile(b),done=campaignProgressLevel(file),rating=campaignBestRating(file),btn=document.createElement('button');btn.className='battle-row'+(unlocked?'':' locked');btn.disabled=!unlocked;btn.style.backgroundImage=`url('assets/sprites/image_menu_hd/button_choosestage_${zoneAsset}.png')`;const sn=EW4NativeCampaign.stageNumber(file)?.stage||i+1;btn.innerHTML=`<span class="stage-no">${sn}</span><span class="stage-name">${b.name_cn||b.file}</span><span class="stage-stars"><i class="${done>=1?'on':''}"></i><i class="${rating>=5?'on':''}"></i></span>`;if(unlocked)btn.onclick=()=>selectBattle(b,btn);box.appendChild(btn);visible.push({b,i,btn,unlocked,done});if(unlocked&&done===0&&preferred<0)preferred=visible.length-1});
  if(preferred<0){for(let i=visible.length-1;i>=0;i--)if(visible[i].unlocked){preferred=i;break}}
  if(preferred>=0)selectBattle(visible[preferred].b,visible[preferred].btn);else{document.getElementById('intro-title').textContent='';document.getElementById('intro-text').textContent='';document.getElementById('intro-portrait').style.display='none'}
  document.getElementById('battle-confirm').disabled=!selectedBattle;go('campaignList')
}
function selectBattle(b,btn){
  selectedBattle=b;document.querySelectorAll('.battle-row').forEach(x=>x.classList.remove('sel'));if(btn)btn.classList.add('sel');
  const lim=nativeStageTurnLimits(b),rating=campaignBestRating(campaignCanonicalFile(b)),status=rating?`　最高评价 ${6-rating}/5`:'' ,tail=lim.valid?`期限 ${lim.win}回合 / 完美 ${lim.best}回合${status}`:(status.trim()||'');
  document.getElementById('intro-title').textContent=`${b.name_cn||b.file}${tail?`　${tail}`:''}`;document.getElementById('intro-text').textContent=b?.desc_cn||'';
  const c=campaignIntroCommander(b),img=document.getElementById('intro-portrait'),src=c?portrait(c.id):'';if(src){img.src=src;img.style.display='block';img.alt=commanderName(c)}else img.style.display='none';
  document.getElementById('battle-confirm').disabled=false
}
let nativeCampaignInfoZone=0;
function closeNativeCampaignInfo(){const el=document.getElementById('campaigninfo-native');el?.classList.remove('show');el?.setAttribute('aria-hidden','true');nativeCampaignInfoZone=0}
async function openNativeCampaignInfo(zone,pin){
  await loadDB();const line=EW4NativeCampaignLine.lineForZone(NATIVE_BATTLELINES,zone);if(!line){openZone(zone);return}
  nativeCampaignInfoZone=+zone;const panel=document.getElementById('campaigninfo-native'),title=document.getElementById('campaigninfo-title'),age=document.getElementById('campaigninfo-age'),tips=document.getElementById('campaigninfo-tips'),nations=document.getElementById('campaigninfo-nations');
  title.textContent=STRINGS?.[EW4NativeCampaignLine.titleKey(line)]||pin?.getAttribute('aria-label')||line.name;age.textContent=`${line.start} - ${line.end}`;tips.textContent='';
  nations.innerHTML=line.countries.map(code=>{const flag=spriteFile(`${code}1.png`);return flag?`<img src="${flag}" alt="${code.toUpperCase()}">`:''}).join('');
  const px=pin?.offsetLeft||207,py=pin?.offsetTop||80,pw=pin?.offsetWidth||54;panel.style.left=`${Math.max(0,Math.min(413,Math.round(px+pw/2-77.5)))}px`;panel.style.top=`${Math.max(0,Math.min(237,Math.round(py-40)))}px`;panel.classList.add('show');panel.setAttribute('aria-hidden','false');playNativeFormOpenSfx('form_campaigninfo')
}
document.querySelectorAll('.campaign-pin').forEach(b=>b.onclick=e=>{e.stopPropagation();openNativeCampaignInfo(+b.dataset.zone,b)});
document.getElementById('campaigninfo-confirm')?.addEventListener('click',e=>{e.stopPropagation();const zone=nativeCampaignInfoZone;closeNativeCampaignInfo();if(zone)openZone(zone)});
document.getElementById('campaign')?.addEventListener('click',e=>{if(e.target.closest?.('.campaign-pin')||e.target.closest?.('#campaigninfo-native'))return;closeNativeCampaignInfo()});
document.getElementById('campaign-lvlup')?.addEventListener('click',e=>{e.stopPropagation();openNativeUpgrade()});document.getElementById('upgrade-close')?.addEventListener('click',closeNativeUpgrade);document.getElementById('upgrade-overlay')?.addEventListener('click',e=>{if(e.target.id==='upgrade-overlay')closeNativeUpgrade()});document.querySelectorAll('#upgrade-tabs [data-upgrade-page]').forEach(b=>b.onclick=e=>{e.stopPropagation();nativeUpgradePage=Math.max(0,Math.min(4,+b.dataset.upgradePage||0));nativeUpgradeTechId=EW4NativeUpgrade.pageTechIds(nativeUpgradePage)[0];renderNativeUpgrade()});document.getElementById('upgrade-confirm')?.addEventListener('click',e=>{e.stopPropagation();commitNativeUpgrade()});
function campaignCountryRecord(b,code){return (b?.countries||[]).find(x=>x.code===code)||null}
function closeCampaignCountrySelect(){const o=document.getElementById('campaign-country-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');if(pending?.mode==='campaign')pending=null;countryChoice=null}
function selectCampaignCountry(code){
  if(pending?.mode!=='campaign'||!pending.allowedCodes?.includes(code))return false;countryChoice=code;const idx=pending.allowedCodes.indexOf(code),sel=document.getElementById('campaign-country-selected'),rec=campaignCountryRecord(pending.battle,code);if(sel)sel.style.left=(idx===1?132:17)+'px';const name=rec?.name_cn||code.toUpperCase(),lab=document.getElementById('campaign-country-selected-name');if(lab)lab.textContent=name;return true
}
async function confirmCampaignCountrySelect(){
  if(pending?.mode!=='campaign'||countryChoice==null){flash('先选择一个国家');return false}const p=pending,resolved=EW4NativeCampaign.resolveVariant(p.battle,countryChoice,DB?.battles||[]);if(!resolved){flash('原版战役分支不存在');return false}const owner=(resolved.battle.countries||[]).find(c=>c.code===resolved.playerCode)?.index??resolved.battle.player_owner_default??0;document.getElementById('campaign-country-overlay')?.classList.remove('show');document.getElementById('campaign-country-overlay')?.setAttribute('aria-hidden','true');pending=null;await openBattle(resolved.battle,p.map,{mode:'campaign',playerOwner:owner,assignments:new Map()});return true
}
function openCampaignCountrySelect(b){
  const codes=EW4NativeCampaign.selectableCountryCodes(b);if(codes.length<2)return false;const pair=codes.slice(0,2),records=pair.map(code=>campaignCountryRecord(b,code));if(records.some(x=>!x))return false;pending={battle:b,mode:'campaign',map:b.header.map_id===2?'america':'europe',back:'campaignList',assignments:new Map(),allowedCodes:pair};
  const cards=[document.getElementById('campaign-country-left'),document.getElementById('campaign-country-right')];cards.forEach((el,i)=>{const c=records[i],code=pair[i],flag=spriteFile(`${code}1.png`);el.dataset.code=code;const img=el.querySelector('.campaign-country-flag'),name=el.querySelector('.campaign-country-name');if(flag){img.src=flag;img.style.display='block'}else{img.removeAttribute('src');img.style.display='none'}img.alt=c.name_cn||code.toUpperCase();name.textContent=c.name_cn||code.toUpperCase()});
  selectCampaignCountry(pair[0]);const o=document.getElementById('campaign-country-overlay');o.classList.add('show');o.setAttribute('aria-hidden','false');playNativeFormOpenSfx('form_selcountry');return true
}
document.getElementById('battle-confirm').onclick=async()=>{if(!selectedBattle)return;await loadDB();if(openCampaignCountrySelect(selectedBattle))return;openBattle(selectedBattle,selectedBattle.header.map_id===2?'america':'europe',{mode:'campaign',playerOwner:selectedBattle.player_owner_default??0,assignments:new Map()})};
document.getElementById('campaign-country-left')?.addEventListener('click',e=>{e.stopPropagation();selectCampaignCountry(e.currentTarget.dataset.code)});document.getElementById('campaign-country-right')?.addEventListener('click',e=>{e.stopPropagation();selectCampaignCountry(e.currentTarget.dataset.code)});document.getElementById('campaign-country-close')?.addEventListener('click',e=>{e.stopPropagation();closeCampaignCountrySelect()});document.getElementById('campaign-country-confirm')?.addEventListener('click',e=>{e.stopPropagation();confirmCampaignCountrySelect()});document.getElementById('campaign-country-overlay')?.addEventListener('click',e=>{if(e.target.id==='campaign-country-overlay')closeCampaignCountrySelect()});
function conquestBattle(idx){return DB?.battles?.find(x=>x.file===`conquest${idx}.btl`)||null}
function conquestFlagStrip(b){return (b?.countries||[]).map(c=>{const flag=spriteFile(`${c.code}1.png`);return flag?`<img src="${flag}" alt="${c.name_cn||c.code}">`:''}).join('')}
function buildConquests(){const root=document.getElementById('conquest-cards');if(root.childElementCount)return;conquests.forEach((c,i)=>{const x=i%2?292:52,y=Math.floor(i/2)*95+37,battle=conquestBattle(c.idx);const b=document.createElement('button');b.className='conq-card';b.style.left=x+'px';b.style.top=y+'px';b.style.backgroundImage=`url('assets/textures/tex_conquest_${c.tex}.png')`;b.innerHTML=`<img class="conq-loc" src="assets/sprites/image_menu_hd/conquest_text_${c.loc}.png"><img class="conq-year" style="left:${c.loc==='america'?78:65}px" src="assets/sprites/image_menu_hd/conquest_text_${c.year}.png"><img class="conq-line" src="assets/sprites/image_menu_hd/button_conquest_whiteline.png"><div class="conq-country-flags">${conquestFlagStrip(battle)}</div>`;b.onclick=async()=>{await loadDB();const live=conquestBattle(c.idx);if(live)openCountrySelect(live,c.map,c.idx)};root.appendChild(b)})}
function nativeConquestMapSize(map){return map==='america'?{w:3456,h:4014}:{w:4992,h:3582}}
function nativeConquestCellPoint(q,r){return window.EW4NativeHex?.cellCenter?EW4NativeHex.cellCenter(q,r):{x:q*64+((r&1)?32:0),y:r*54-18}}
function conquestCountryAnchor(b,c){const objs=(b.objects||[]).filter(o=>+o.owner===+c.index&&o.active!==0&&o.construction_type==='city');if(objs.length)return objs.sort((a,z)=>(+z.level||0)-(+a.level||0))[0];const units=(b.units||[]).filter(u=>+u.owner===+c.index);return units[0]||null}
function renderConquestMapPreview(b,map){
  const canvas=document.getElementById('conquest-country-map'),marks=document.getElementById('conquest-country-markers');if(!canvas||!marks)return;
  const pctx=canvas.getContext?.('2d');if(!pctx)return;const previewScale=Math.max(1,battleBackingScale||1);canvas.width=410*previewScale;canvas.height=320*previewScale;pctx.setTransform(previewScale,0,0,previewScale,0,0);pctx.imageSmoothingEnabled=true;try{pctx.imageSmoothingQuality='high'}catch(e){}marks.innerHTML='';
  const size=nativeConquestMapSize(map),vw=410,vh=320,scale=Math.min(vw/size.w,vh/size.h),ox=(vw-size.w*scale)/2,oy=(vh-size.h*scale)/2;
  const ground=img('assets/maps/map_pt.png'),overlay=img(`assets/maps/${map}.png`);
  const draw=()=>{
    pctx.clearRect(0,0,vw,vh);pctx.save();pctx.translate(ox,oy);pctx.scale(scale,scale);
    if(ground?.complete){const pat=pctx.createPattern(ground,'repeat');if(pat){pctx.fillStyle=pat;pctx.fillRect(0,0,size.w,size.h)}}else{pctx.fillStyle='#77746d';pctx.fillRect(0,0,size.w,size.h)}
    const h=b.header||{};for(let q=h.origin_x||0;q<(h.origin_x||0)+(h.width||0);q++)for(let r=h.origin_y||0;r<(h.origin_y||0)+(h.height||0);r++){
      const own=nativeOwnerAtForBattle(b,q,r);if(own===255)continue;const c=b.countries?.[own],rgba=c?.rgba||[100,100,100,40],a=Math.max(0,Math.min(1,(+rgba[3]||40)/255));const pt=nativeConquestCellPoint(q,r),verts=EW4NativeHex.vertices(pt.x,pt.y,1);pctx.beginPath();verts.forEach(([x,y],i)=>i?pctx.lineTo(x,y):pctx.moveTo(x,y));pctx.closePath();pctx.fillStyle=`rgba(${rgba[0]},${rgba[1]},${rgba[2]},${a})`;pctx.fill();
    }
    if(overlay?.complete)pctx.drawImage(overlay,0,0);pctx.restore();
  };
  if(ground&&!ground.complete)ground.addEventListener('load',draw,{once:true});if(overlay&&!overlay.complete)overlay.addEventListener('load',draw,{once:true});draw();
  for(const c of b.countries||[]){const a=conquestCountryAnchor(b,c),flag=spriteFile(`${c.code}1.png`);if(!a||!flag)continue;const p=nativeConquestCellPoint(+a.q,+a.r),m=document.createElement('img');m.className='conquest-map-country-marker';m.dataset.owner=String(c.index);m.src=flag;m.alt=c.name_cn||c.code;m.style.left=`${ox+p.x*scale}px`;m.style.top=`${oy+(p.y+18)*scale}px`;marks.appendChild(m)}
}
function syncConquestCountrySelection(){const root=document.getElementById('country-grid');root?.querySelectorAll('.native-conquest-country-row').forEach(x=>x.classList.toggle('sel',+x.dataset.owner===+countryChoice));document.querySelectorAll('.conquest-map-country-marker').forEach(x=>x.classList.toggle('sel',+x.dataset.owner===+countryChoice));const c=pending?.battle?.countries?.find(x=>+x.index===+countryChoice);const lab=document.getElementById('country-choice');if(lab)lab.textContent=c?(c.name_cn||c.code.toUpperCase()):'请选择国家'}
function openCountrySelect(b,map,scenarioIdx=null){pending={battle:b,mode:'conquest',map,back:'conquest',assignments:new Map(),scenarioIdx};countryChoice=null;const root=document.getElementById('country-grid');root.innerHTML='';for(const c of b.countries||[]){const el=document.createElement('button'),flag=spriteFile(`${c.code}1.png`);el.className='native-conquest-country-row';el.dataset.owner=String(c.index);el.innerHTML=`<span class="native-country-wedge"></span>${flag?`<img src="${flag}" alt="">`:''}<span class="native-country-name">${c.name_cn||c.code.toUpperCase()}</span>`;el.onclick=()=>{countryChoice=c.index;syncConquestCountrySelection()};root.appendChild(el)}renderConquestMapPreview(b,map);document.getElementById('country-choice').textContent='请选择国家';go('countrySelect')}
document.querySelectorAll('[data-tutorial]').forEach(btn=>btn.onclick=async()=>{await loadDB();const b=DB.battles.find(x=>x.file===btn.dataset.tutorial);if(b)openBattle(b,b.header.map_id===2?'america':'europe',{mode:'tutorial',playerOwner:b.player_owner_default??0,assignments:new Map()})});
function openPlayNotice(){if(!STRINGS){loadDB().then(openPlayNotice);return}const body=document.getElementById('playnotice-body');if(body)body.innerHTML=STRINGS.html_notice||'';document.getElementById('playnotice-shade')?.classList.add('show');document.getElementById('playnotice-native')?.classList.add('show');playNativeFormOpenSfx('form_playnotice')}
function closePlayNotice(){document.getElementById('playnotice-shade')?.classList.remove('show');document.getElementById('playnotice-native')?.classList.remove('show')}
document.getElementById('tutorial-notice')?.addEventListener('click',openPlayNotice);document.getElementById('playnotice-close')?.addEventListener('click',closePlayNotice);document.getElementById('playnotice-shade')?.addEventListener('click',closePlayNotice);document.getElementById('tutorial-close')?.addEventListener('click',()=>go('main'));

document.getElementById('country-back').onclick=()=>go(pending?.back||'conquest');
document.getElementById('country-confirm').onclick=()=>{if(countryChoice==null){flash('先选择一个国家');return}if(pending?.mode==='campaign'){confirmCampaignCountrySelect();return}openBattle(pending.battle,pending.map,{mode:'conquest',playerOwner:countryChoice,assignments:new Map()})};

/* ---------- HQ / Academy ---------- */
function rankHpAt(c,level){if(!c)return 0;const max=+PLAYER_OVERRIDES?.global?.rankMaxLevel||14,cap=+c.rankHpBonusCap||+PLAYER_OVERRIDES?.global?.rankHpBonusCap||500;return Math.round(cap*Math.max(0,Math.min(max,+level||0))/max)}
function nobilityHealAt(c,level){if(!c)return 0;const max=+PLAYER_OVERRIDES?.global?.nobilityMaxLevel||9,cap=+c.nobilityHealCap||+PLAYER_OVERRIDES?.global?.nobilityHealCap||25;return Math.round(cap*Math.max(0,Math.min(max,+level||0))/max)}
function openHQCommander(c,{playOpenSound=true}={}){
  detailCommander=c;if(playOpenSound)playNativeFormOpenSfx('form_generalinfo');const ec=effectiveCommander(c,true),owned=owns(c.id),skills=ec.skills||baseSkillIds(ec),canManage=owned&&activeScreenId()!=='battle';
  document.getElementById('gd-portrait').src=portrait(c.id);document.getElementById('gd-name').textContent=commanderName(c);document.getElementById('gd-country').textContent=`${c.country.toUpperCase()} · ${stars(c.star)}`;
  const rows=[['步兵',ec.infantry],['骑兵',ec.cavalry],['炮兵',ec.artillery],['海军',ec.warship],['要塞',ec.fort],['商业',ec.business],['行军',ec.movement],['训练',ec.training]];document.getElementById('gd-stats').innerHTML=rows.map(([n,v])=>`<div class="gd-stat"><span>${n}</span><b>${v}</b></div>`).join('');
  document.getElementById('gd-skills').innerHTML=skills.slice(0,4).map(id=>`<span class="gd-skill">${skillName(id)}</span>`).join('');const rl=rankLevel(c),nl=nobilityLevel(c);
  document.getElementById('gd-rank-display').textContent=`军衔 ${rl}/${EW4NativeGeneral.MILITARY_MAX}`;document.getElementById('gd-life').textContent=`HP +${rankHpAt(ec,rl)}`;document.getElementById('gd-nobility-display').textContent=`爵位 ${nl}/${EW4NativeGeneral.NOBILITY_MAX}`;document.getElementById('gd-apply').textContent=`恢复 +${nobilityHealAt(ec,nl)}`;
  const rg=document.getElementById('gd-regroup'),item=document.getElementById('gd-item');if(rg)rg.disabled=!canManage;if(item)item.disabled=!canManage;renderEquipmentSlots(c);document.getElementById('general-detail').classList.add('show')
}
let upgradeCommander=null,regroupTarget=null,regroupSource=null;
function closeGeneralUpgrade(){document.getElementById('general-upgrade')?.classList.remove('show');upgradeCommander=null}
function renderGeneralUpgrade(){
  const c=upgradeCommander;if(!c)return;const ec=effectiveCommander(c,true),r=rankLevel(c),rp=rankProgress(c),n=nobilityLevel(c),np=nobilityProgress(c),rn=Math.min(EW4NativeGeneral.MILITARY_MAX,r+1),nn=Math.min(EW4NativeGeneral.NOBILITY_MAX,n+1);
  document.getElementById('gu-military-from').textContent=`${r}级`;document.getElementById('gu-military-to').textContent=r>=EW4NativeGeneral.MILITARY_MAX?'已满':`${rn}级`;document.getElementById('gu-life-from').textContent=`HP +${rankHpAt(ec,r)}`;document.getElementById('gu-life-to').textContent=`HP +${rankHpAt(ec,rn)}`;
  document.getElementById('gu-nobility-from').textContent=`${n}级`;document.getElementById('gu-nobility-to').textContent=n>=EW4NativeGeneral.NOBILITY_MAX?'已满':`${nn}级`;document.getElementById('gu-apply-from').textContent=`恢复 +${nobilityHealAt(ec,n)}`;document.getElementById('gu-apply-to').textContent=`恢复 +${nobilityHealAt(ec,nn)}`;
  const mc=EW4NativeGeneral.nextMilitaryCost(r,rp),nc=EW4NativeGeneral.nextNobilityCost(n,np),ac=EW4NativeGeneral.allFullCost(r,rp,n,np);document.getElementById('gu-military-cost').textContent=mc;document.getElementById('gu-nobility-cost').textContent=nc;document.getElementById('gu-all-cost').textContent=ac;document.getElementById('gu-all-summary').textContent=`军衔→${EW4NativeGeneral.MILITARY_MAX}　爵位→${EW4NativeGeneral.NOBILITY_MAX}`;
  document.getElementById('gu-military').disabled=r>=EW4NativeGeneral.MILITARY_MAX;document.getElementById('gu-nobility').disabled=n>=EW4NativeGeneral.NOBILITY_MAX;document.getElementById('gu-all').disabled=r>=EW4NativeGeneral.MILITARY_MAX&&n>=EW4NativeGeneral.NOBILITY_MAX;
}
function openGeneralUpgrade(c){if(!c||!owns(c.id)||activeScreenId()==='battle')return;upgradeCommander=c;playNativeFormOpenSfx('form_generalupgrade');renderGeneralUpgrade();document.getElementById('general-upgrade').classList.add('show')}
function commitGeneralUpgrade(kind){
  const c=upgradeCommander;if(!c||!owns(c.id))return;let r=rankLevel(c),rp=rankProgress(c),n=nobilityLevel(c),np=nobilityProgress(c);
  if(kind==='military'&&r<EW4NativeGeneral.MILITARY_MAX){r++;rp=0}else if(kind==='nobility'&&n<EW4NativeGeneral.NOBILITY_MAX){n++;np=0}else if(kind==='all'){r=EW4NativeGeneral.MILITARY_MAX;rp=0;n=EW4NativeGeneral.NOBILITY_MAX;np=0}else return;
  // MOD: retain original displayed medal costs/controller flow, but player medal balance is infinite and is not decremented.
  setGeneralGrowth(c,{rank:r,militaryProgress:rp,nobility:n,nobleProgress:np});persist();playNativeSfxFile('sfx_lvup2.wav');renderGeneralUpgrade();if(deploymentContext==='hq')renderDeployment();flash(kind==='all'?'将领等级已升满':kind==='military'?'军衔提升':'爵位提升')
}
function generalCoreState(c){const ec=effectiveCommander(c,true);return{...ec,rank:rankLevel(c),militaryProgress:rankProgress(c),nobility:nobilityLevel(c),nobilityProgress:nobilityProgress(c),skills:ec.skills||baseSkillIds(ec)}}
function regroupCard(c,preview=null){if(!c)return'<div class="rg-card"><span>请选择</span></div>';const x=preview||generalCoreState(c),r=preview?.rank??rankLevel(c),n=preview?.nobility??nobilityLevel(c);return`<div class="rg-card${preview?' preview':''}"><img src="${portrait(c.id)}"><b>${commanderName(c)}</b><div class="rg-level">军${r} · 爵${n}</div><div class="rg-stats">步${x.stats?.infantry??x.infantry} 骑${x.stats?.cavalry??x.cavalry} 炮${x.stats?.artillery??x.artillery}<br>海${x.stats?.warship??x.warship} 塞${x.stats?.fort??x.fort} 商${x.stats?.business??x.business} 行${x.stats?.movement??x.movement}</div></div>`}
function currentRegroupPreview(){if(!regroupTarget||!regroupSource)return null;return EW4NativeGeneral.regroupPreview(generalCoreState(regroupTarget),generalCoreState(regroupSource))}
function renderRegroup(){
  if(!regroupTarget)return;const preview=currentRegroupPreview();document.getElementById('rg-target-card').innerHTML=regroupCard(regroupTarget);document.getElementById('rg-source-card').innerHTML=regroupCard(regroupSource);document.getElementById('rg-preview-card').innerHTML=regroupCard(regroupTarget,preview||generalCoreState(regroupTarget));document.getElementById('rg-open-confirm').disabled=!regroupSource||+regroupSource.id===+regroupTarget.id;
  const list=document.getElementById('rg-general-list');list.innerHTML='';for(const c of commanderList().filter(x=>owns(x.id)&&!PRINCESS_IDS.includes(+x.id))){const b=document.createElement('button');b.className='rg-list-general'+(+regroupSource?.id===+c.id?' source':'')+(+regroupTarget?.id===+c.id?' target':'');b.disabled=+c.id===+regroupTarget.id;b.innerHTML=`<img src="${portrait(c.id)}"><b>${commanderName(c)}</b>`;b.onclick=()=>{regroupSource=c;renderRegroup()};list.appendChild(b)}
}
function openRegroup(c){if(!c||!owns(c.id)||activeScreenId()==='battle')return;regroupTarget=c;regroupSource=commanderList().find(x=>owns(x.id)&&+x.id!==+c.id&&!PRINCESS_IDS.includes(+x.id))||null;document.getElementById('general-detail').classList.remove('show');playNativeFormOpenSfx('form_regroup');renderRegroup();document.getElementById('regroup-panel').classList.add('show')}
function closeRegroup(){document.getElementById('regroup-panel')?.classList.remove('show');document.getElementById('regroup-confirm')?.classList.remove('show');regroupTarget=null;regroupSource=null}
function openRegroupConfirm(){if(!regroupTarget||!regroupSource)return;document.getElementById('rg-confirm-source').innerHTML=regroupCard(regroupSource);const ids=equipmentSlotsForCommander(regroupSource);document.getElementById('rg-confirm-items').innerHTML=ids.map(id=>{const it=id!=null?ITEMS?.[String(id)]:null;return`<div class="rg-confirm-item">${it&&itemIcon(it)?`<img src="${itemIcon(it)}">`:''}<span>${it?itemName(it):'空'}</span></div>`}).join('');document.getElementById('regroup-confirm').classList.add('show')}
function commitRegroup(){
  if(!regroupTarget||!regroupSource||!owns(regroupTarget.id)||!owns(regroupSource.id)||+regroupTarget.id===+regroupSource.id)return;const target=regroupTarget,source=regroupSource,preview=currentRegroupPreview();if(!preview)return;const tid=String(target.id),sid=String(source.id);
  setGeneralGrowth(target,{rank:preview.rank,militaryProgress:preview.militaryProgress,nobility:preview.nobility,nobleProgress:preview.nobilityProgress});saveState.generalStats[tid]={...preview.stats};
  // Original Regroup deletes source and its equipped items. Re-recruiting that commander therefore must not resurrect base equipment.
  saveState.owned=saveState.owned.filter(id=>+id!==+source.id);delete saveState.rank[sid];delete saveState.nobility[sid];delete saveState.rankProgress[sid];delete saveState.nobilityProgress[sid];delete saveState.generalStats[sid];saveState.equipment[sid]=[null,null];
  persist();playNativeSfxFile('sfx_lvup2.wav');document.getElementById('regroup-confirm').classList.remove('show');document.getElementById('regroup-panel').classList.remove('show');regroupSource=null;regroupTarget=null;if(deploymentContext==='hq')renderDeployment();flash('整编完成')
}
let dismissCommander=null;
function dismissalReturnPreview(c){
  if(!c)return{ok:false,reason:'general'};let inventory=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS),returned=[];for(const id of equipmentSlotsForCommander(c)){if(id==null)continue;const it=ITEMS?.[String(id)],r=EW4ItemInventory.tryAdd(inventory,id,1,ITEMS);if(!r.ok)return{ok:false,reason:'full',inventory,returned};inventory=r.inventory;returned.push({id:+id,item:it})}return{ok:true,inventory,returned}
}
function openGeneralDismiss(c){
  if(!c||!owns(c.id)||PRINCESS_IDS.includes(+c.id)||activeScreenId()==='battle')return;dismissCommander=c;const preview=dismissalReturnPreview(c),items=document.getElementById('dismiss-items');document.getElementById('dismiss-text').textContent=`确定解雇 ${commanderName(c)}？已装备物品将返还物品栏。`;items.innerHTML=preview.returned.map(x=>`<div class="dismiss-return-item">${x.item&&itemIcon(x.item)?`<img src="${itemIcon(x.item)}">`:''}<span>${x.item?itemName(x.item):`物品${x.id}`}</span></div>`).join('')||'<span>无装备返还</span>';const ok=document.getElementById('dismiss-ok');ok.disabled=!preview.ok;if(!preview.ok)document.getElementById('dismiss-text').textContent='物品栏空间不足，无法安全解雇该将领。';playNativeFormOpenSfx('form_regroupconfirm');document.getElementById('general-dismiss-confirm').classList.add('show')
}
function closeGeneralDismiss(){document.getElementById('general-dismiss-confirm')?.classList.remove('show');dismissCommander=null}
function commitGeneralDismiss(){
  const c=dismissCommander;if(!c||!owns(c.id)||PRINCESS_IDS.includes(+c.id))return;const preview=dismissalReturnPreview(c);if(!preview.ok){flash('物品栏空间不足，无法解雇');return}const sid=String(c.id);saveState.itemInventory=preview.inventory;saveState.owned=saveState.owned.filter(id=>+id!==+c.id);delete saveState.rank[sid];delete saveState.nobility[sid];delete saveState.rankProgress[sid];delete saveState.nobilityProgress[sid];delete saveState.generalStats[sid];saveState.equipment[sid]=[null,null];persist();closeGeneralDismiss();document.getElementById('general-detail')?.classList.remove('show');detailCommander=null;if(deploymentContext==='hq')renderDeployment();playNativeSfxFile('sfx_cancel.wav');flash(`${commanderName(c)} 已解雇，装备已返还物品栏`)
}
let deployItemCommander=null,deployItemSlot=0,deployItemSelectedBankIndex=null;
function renderEquipmentSlots(c){
  const root=document.getElementById('gd-equipment');if(!root)return;root.innerHTML='';const ids=equipmentSlotsForCommander(c);
  for(let slot=0;slot<2;slot++){const id=ids[slot],it=id!=null?ITEMS?.[String(id)]:null,b=document.createElement('button');b.className='gd-eq-slot';b.disabled=!owns(c.id);b.title=it?`${itemName(it)}：${itemDesc(it)}`:'空装备槽';b.innerHTML=it?`${itemIcon(it)?`<img src="${itemIcon(it)}">`:''}<span>${itemName(it)}</span>`:`<span>空槽 ${slot+1}</span>`;b.onclick=()=>openDeployItem(c,slot);root.appendChild(b)}
}
function deployItemCommanders(){return commanderList().filter(c=>owns(c.id))}
function deployItemSelectedSlot(){const bank=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS),i=deployItemSelectedBankIndex;return Number.isInteger(i)&&i>=0&&i<bank.slots.length?bank.slots[i]:null}
function renderDeployItem(){
  const c=deployItemCommander;if(!c)return;const ec=effectiveCommander(c,true),slots=equipmentSlotsForCommander(c),bank=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS);saveState.itemInventory=bank;detailCommander=c;
  const portraitEl=document.getElementById('eq-portrait');if(portraitEl)portraitEl.src=portrait(c.id);document.getElementById('eq-name').textContent=commanderName(c);document.getElementById('eq-rank').textContent=`军衔 ${rankLevel(c)}`;document.getElementById('eq-nobility').textContent=`爵位 ${nobilityLevel(c)}`;document.getElementById('eq-life').textContent=`HP +${rankHpAt(ec,rankLevel(c))}`;document.getElementById('eq-apply').textContent=`恢复 +${nobilityHealAt(ec,nobilityLevel(c))}`;
  const equipped=document.getElementById('eq-equipped');equipped.innerHTML='';for(let slot=0;slot<2;slot++){const id=slots[slot],it=id==null?null:ITEMS?.[String(id)],b=document.createElement('button');b.className='eq-equipped-slot'+(slot===deployItemSlot?' sel':'');b.dataset.slot=String(slot);b.title=it?itemDesc(it)||itemName(it):'空装备槽';b.innerHTML=it?`${itemIcon(it)?`<img src="${itemIcon(it)}">`:''}<small>${itemName(it)}</small>`:'空';b.onclick=()=>{deployItemSlot=slot;renderDeployItem()};equipped.appendChild(b)}
  const grid=document.getElementById('eq-grid');grid.innerHTML='';bank.slots.forEach((entry,i)=>{const id=entry?.item>=0?+entry.item:null,it=id==null?null:ITEMS?.[String(id)],b=document.createElement('button');b.className='eq-item'+(deployItemSelectedBankIndex===i?' sel':'')+(id==null?' empty':'');b.dataset.bankIndex=String(i);if(it&&itemIcon(it))b.innerHTML=`<img src="${itemIcon(it)}"><small>${entry.count>1?`×${entry.count}`:''}</small>`;else b.innerHTML='<span>空</span>';b.title=it?`${itemName(it)}：${itemDesc(it)}`:'空库存位';b.onclick=()=>{deployItemSelectedBankIndex=i;renderDeployItem()};grid.appendChild(b)});
  const selected=deployItemSelectedSlot(),selectedId=selected?.item>=0?+selected.item:null,selectedItem=selectedId==null?null:ITEMS?.[String(selectedId)],current=slots[deployItemSlot],flagLocked=!!selectedItem?.flag&&!EW4Combat.hasSkill(ec,0),consumable=!!selectedItem?.consumable;
  document.getElementById('eq-desc').textContent=selectedItem?`${itemName(selectedItem)}\n${itemDesc(selectedItem)||''}${flagLocked?'\n需要“旗手”技能':''}${consumable?'\n战场消耗品不能装备':''}`:(current!=null?'选择空库存位可卸下当前装备':'选择库存中的装备');const equip=document.getElementById('eq-equip');equip.disabled=(selectedId==null&&current==null)||flagLocked||consumable;equip.textContent=selectedId==null?'卸　下':'装　备'
}
function openDeployItem(c,slot=0){
  if(!c||!owns(c.id)||activeScreenId()==='battle')return;deployItemCommander=c;deployItemSlot=slot===1?1:0;deployItemSelectedBankIndex=null;playNativeFormOpenSfx('form_deployitem');renderDeployItem();document.getElementById('equipment-picker').classList.add('show')
}
function cycleDeployItemCommander(delta){const list=deployItemCommanders();if(!deployItemCommander||!list.length)return;let i=list.findIndex(c=>+c.id===+deployItemCommander.id);if(i<0)i=0;i=(i+(delta<0?-1:1)+list.length)%list.length;deployItemCommander=list[i];deployItemSlot=0;deployItemSelectedBankIndex=null;renderDeployItem()}
function commitDeployItem(){
  const c=deployItemCommander;if(!c||!owns(c.id))return;const selected=deployItemSelectedSlot(),id=selected?.item>=0?+selected.item:null,it=id==null?null:ITEMS?.[String(id)],ec=effectiveCommander(c,true);if(it?.consumable){flash('战场消耗品不能装备');return}if(it?.flag&&!EW4Combat.hasSkill(ec,0)){flash('需要“旗手”技能');return}
  const r=EW4ItemInventory.changeSlot({inventory:saveState.itemInventory,slots:equipmentSlotsForCommander(c),slot:deployItemSlot,itemId:id,items:ITEMS});if(!r.ok){flash(r.reason==='insufficient'?'库存不足':'无法更换装备');return}saveState.itemInventory=r.inventory;saveState.equipment=saveState.equipment||{};saveState.equipment[String(c.id)]=r.slots;persist();playNativeSfxFile('sfx_click.wav');deployItemSelectedBankIndex=null;renderDeployItem();renderEquipmentSlots(c);flash(id==null?'装备已卸下':`${itemName(it)} 已装备`)
}
function closeDeployItem(){document.getElementById('equipment-picker')?.classList.remove('show');deployItemCommander=null;deployItemSelectedBankIndex=null}
function closeHQCommander(){document.getElementById('general-detail').classList.remove('show');closeDeployItem();detailCommander=null}


bindTutorialUI(document.getElementById('commerce-close'),'winbtn_close');document.getElementById('commerce-close').onclick=()=>document.getElementById('commerce-panel').classList.remove('show');
document.getElementById('gd-close').onclick=closeHQCommander;document.getElementById('gd-regroup').onclick=()=>detailCommander&&openRegroup(detailCommander);document.getElementById('gd-item').onclick=()=>{if(detailCommander&&owns(detailCommander.id))openDeployItem(detailCommander,0)};document.getElementById('eq-close').onclick=closeDeployItem;document.getElementById('eq-prev').onclick=()=>cycleDeployItemCommander(-1);document.getElementById('eq-next').onclick=()=>cycleDeployItemCommander(1);document.getElementById('eq-equip').onclick=commitDeployItem;document.getElementById('gu-close').onclick=closeGeneralUpgrade;document.getElementById('gu-military').onclick=()=>commitGeneralUpgrade('military');document.getElementById('gu-nobility').onclick=()=>commitGeneralUpgrade('nobility');document.getElementById('gu-all').onclick=()=>commitGeneralUpgrade('all');document.getElementById('rg-close').onclick=closeRegroup;document.getElementById('rg-open-confirm').onclick=openRegroupConfirm;document.getElementById('rg-confirm-cancel').onclick=()=>document.getElementById('regroup-confirm').classList.remove('show');document.getElementById('rg-confirm-ok').onclick=commitRegroup;document.getElementById('dismiss-cancel').onclick=closeGeneralDismiss;document.getElementById('dismiss-ok').onclick=commitGeneralDismiss;
document.querySelectorAll('.academy-tab').forEach(b=>b.onclick=()=>{academyPool=b.dataset.pool;saveState.academyPool=academyPool;academySelectedId=null;syncAcademyCandidates();persist();renderAcademy()});
document.getElementById('academy-refresh').onclick=()=>refreshAcademy();
function academyCandidateCount(){return EW4NativeAcademy.config(academyPool).count}
function ensureAcademyCandidatesPersisted(){
  if(!COMMANDERS||!window.EW4NativeAcademy)return false;
  const before=EW4NativeAcademy.normalizePools(saveState.academyCandidatesByPool),after=EW4NativeAcademy.ensurePools({commanders:COMMANDERS,owned:saveState.owned,pools:before});
  saveState.academyCandidatesByPool=after;syncAcademyCandidates();return true
}
function syncAcademyCandidates(){
  if(!COMMANDERS){academyCandidates=[];return academyCandidates}
  const ids=EW4NativeAcademy.normalizePools(saveState.academyCandidatesByPool)[academyPool]||[];
  academyCandidates=ids.map(id=>id==null?null:(COMMANDERS[String(id)]||null));return academyCandidates
}
function refreshAcademy(){
  if(!COMMANDERS||!window.EW4NativeAcademy)return;
  ensureAcademyCandidatesPersisted();
  saveState.academyCandidatesByPool=EW4NativeAcademy.refreshTier({commanders:COMMANDERS,owned:saveState.owned,pools:saveState.academyCandidatesByPool,tier:academyPool});
  syncAcademyCandidates();academySelectedId=null;persist();renderAcademy()
}
function academySelected(){return academyCandidates.find(c=>c&&+c.id===+academySelectedId)||null}

function closeGetGeneralTips(){document.getElementById('getgeneral-tips-shade')?.classList.remove('show');document.getElementById('getgeneral-tips')?.classList.remove('show')}
function openGetGeneralTips(c){if(!c)return;document.getElementById('getgeneral-tips-portrait').src=portrait(c.id);document.getElementById('getgeneral-tips-name').textContent=commanderName(c);document.getElementById('getgeneral-tips-shade').classList.add('show');document.getElementById('getgeneral-tips').classList.add('show');playNativeFormOpenSfx('form_getgeneraltips')}
function academySelect(id){academySelectedId=+id;renderAcademy()}
function academyAcquire(cur){const c=academySelected();if(!c)return;if(owns(c.id)){flash('该上将已拥有');return}if(!EW4NativeAcademy.canUseCurrency(c,cur))return;if(acquire(c.id)){saveState.academyCandidatesByPool=EW4NativeAcademy.clearCandidate(saveState.academyCandidatesByPool,academyPool,c.id);academySelectedId=null;syncAcademyCandidates();persist();renderAcademy();if(deploymentContext==='hq')renderDeployment();openGetGeneralTips(c)}}
function renderAcademy(){
  if(!COMMANDERS){loadDB().then(()=>{academyPool=saveState.academyPool||'6';ensureAcademyCandidatesPersisted();renderAcademy()});return}
  ensureAcademyCandidatesPersisted();syncAcademyCandidates();
  const poolPos={6:0,4:156,2:312},line=document.getElementById('academy-checkline');if(line)line.style.left=(poolPos[academyPool]??0)-5+'px';
  const root=document.getElementById('academy-list');root.innerHTML='';
  academyCandidates.forEach((c,idx)=>{const el=document.createElement('div');if(!c){el.className='academy-card academy-empty';el.setAttribute('aria-hidden','true');root.appendChild(el);return}const owned=owns(c.id),sel=+academySelectedId===+c.id;el.className='academy-card'+(sel?' sel':'');el.dataset.id=c.id;el.tabIndex=0;el.setAttribute('role','button');el.innerHTML=`<img class="academy-portrait" src="${portrait(c.id)}"><span class="academy-name">${commanderName(c)}</span><button class="academy-info" title="信息"></button>`;el.onclick=e=>{if(e.target.closest('.academy-info'))return;academySelect(c.id)};el.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();academySelect(c.id)}};el.querySelector('.academy-info').onclick=e=>{e.stopPropagation();openHQCommander(c)};if(owned)el.style.opacity='.58';root.appendChild(el)});
  const pair=document.getElementById('academy-buy-pair'),c=academySelected();
  if(c){const idx=Math.max(0,academyCandidates.findIndex(x=>x&&+x.id===+c.id)),slotLeft=25+idx*(78+10.2),left=Math.max(4,Math.min(449,slotLeft+39-57.5));pair.style.left=left+'px';pair.classList.add('show');const owned=owns(c.id),prices=EW4NativeAcademy.prices(c),medalBtn=document.getElementById('academy-buy-medal'),badgeBtn=document.getElementById('academy-buy-badge');document.getElementById('academy-medal-price').textContent=prices.medal||'';document.getElementById('academy-badge-price').textContent=prices.badge||'';medalBtn.hidden=prices.medal<=0;badgeBtn.hidden=prices.badge<=0;medalBtn.disabled=owned||prices.medal<=0;badgeBtn.disabled=owned||prices.badge<=0}else pair.classList.remove('show');
}
document.getElementById('academy-buy-medal').onclick=()=>academyAcquire('medal');document.getElementById('academy-buy-badge').onclick=()=>academyAcquire('badge');
document.getElementById('getgeneral-tips-ok').onclick=closeGetGeneralTips;document.getElementById('getgeneral-tips-shade').onclick=closeGetGeneralTips;

/* ---------- Native in-battle general deployment (form_deploygeneral) ---------- */
function deploymentTargetUnit(){
  if(!battleState||deploymentTargetUnitIndex==null)return null;
  return battleState.units.find(u=>+u.index===+deploymentTargetUnitIndex&&!u.dead)||null
}
function deployedGeneralIds(exceptUnitIndex=null){return battleState?EW4GeneralDeployment.deployedIds(battleState.units,battleState.playerOwner,exceptUnitIndex):new Set()}
function commanderHpBonusForDeployment(cid){const c=COMMANDERS?.[String(cid)];return c?Math.max(0,playerRankHpBonus(effectiveCommander(c,true))):0}
function openGeneralDeploymentForUnit(u){
  if(!battleState||!u||u.dead||!isMine(u))return;
  deploymentContext='battle';deploymentTargetUnitIndex=+u.index;selectedDeployGeneral=u.commander_id==null?null:+u.commander_id;renderDeployment();go('deploy');requestAnimationFrame(positionNativeTutorialHighlight)
}
function openHeadquartersDeployment(){
  deploymentContext='hq';deploymentTargetUnitIndex=null;selectedDeployGeneral=null;
  if(!COMMANDERS){loadDB().then(openHeadquartersDeployment);return}
  renderDeployment();go('deploy')
}
function renderDeployment(){
  const gRoot=document.getElementById('deploy-generals');if(!gRoot)return;
  const target=deploymentTargetUnit(),hqMode=deploymentContext==='hq';
  if(!hqMode&&!target)return;
  gRoot.innerHTML='';
  let shown=[];
  if(hqMode){
    shown=commanderList().filter(c=>owns(c.id));
  }else{
    const occupied=deployedGeneralIds(target.index),summoned=new Set((battleState?.summonedPrincesses||[]).map(Number));
    shown=commanderList().filter(c=>owns(c.id)&&(!PRINCESS_IDS.includes(+c.id)||summoned.has(+c.id)||+c.id===+target.commander_id)&&(!occupied.has(+c.id)||+c.id===+target.commander_id));
  }
  for(const [tutorialRow,c] of shown.entries()){
    const el=document.createElement('button'),isSel=!hqMode&&+selectedDeployGeneral===+c.id;
    el.className='deploy-native-general'+(isSel?' sel':'')+(hqMode?' hq-general':'');el.dataset.id=c.id;bindTutorialUI(el,'grid_general',tutorialRow);
    el.innerHTML=`<div class="frame"><img src="${portrait(c.id)}"></div><b>${commanderName(c)}</b><div class="stars">${stars(c.star)}</div>${hqMode?'<span class="hq-upgrade-hotspot" role="button" aria-label="升级"></span>':''}${hqMode&&!PRINCESS_IDS.includes(+c.id)?'<span class="hq-dismiss-hotspot" role="button" aria-label="解雇">退</span>':''}`;
    if(hqMode){el.querySelector('.hq-upgrade-hotspot')?.addEventListener('click',e=>{e.stopPropagation();openGeneralUpgrade(c)});el.querySelector('.hq-dismiss-hotspot')?.addEventListener('click',e=>{e.stopPropagation();openGeneralDismiss(c)})}el.onclick=()=>{if(hqMode){openHQCommander(c);return}selectedDeployGeneral=+c.id;renderDeployment()};gRoot.appendChild(el)
  }
  if(!shown.length)gRoot.innerHTML='<div style="grid-column:1/7;padding-top:70px;text-align:center;font-size:8px;color:#554e43">暂无可用将领</div>';
  document.getElementById('deploy-count').textContent=String(hqMode?shown.length:[...deployedGeneralIds()].length);
  const confirm=document.getElementById('deploy-confirm');if(confirm){confirm.disabled=!hqMode&&selectedDeployGeneral==null;confirm.setAttribute('aria-disabled',hqMode?'true':String(selectedDeployGeneral==null));}
  document.getElementById('deploy')?.classList.toggle('hq-context',hqMode);
  const shop=document.getElementById('deploy-shop');if(shop)shop.disabled=!hqMode;requestAnimationFrame(positionNativeTutorialHighlight);
}
function hidePrincessDeploymentPanel(){const p=document.getElementById('princess-panel');if(p)p.classList.remove('show')}
function renderPrincessDeploymentPanel(){
  const root=document.getElementById('princess-grid'),target=deploymentTargetUnit(),hqMode=deploymentContext==='hq';if(!root||(!hqMode&&!target))return;
  root.innerHTML='';const occupied=hqMode?new Set():deployedGeneralIds(target.index);
  ORIGINAL_PRINCESS_ORDER.forEach((cid,i)=>{const c=COMMANDERS?.[String(cid)];if(!c)return;const el=document.createElement('div'),row=i<4?1:2,col=(i%4)+1,deployedElsewhere=!hqMode&&occupied.has(+cid);el.className=`princess-entry r${row} c${col}`;
    const alreadyOwned=owns(cid),label=hqMode?(alreadyOwned?'已出征':(STRINGS?.btn_gobattle||'出征')):(deployedElsewhere?'已出征':(STRINGS?.btn_gobattle||'出征'));
    el.innerHTML=`<img class="portrait" src="${portrait(cid)}" alt=""><div class="name">${commanderName(c)}</div><button class="go" data-princess-id="${cid}" ${(hqMode&&alreadyOwned)||deployedElsewhere?'disabled':''}>${label}</button>`;
    const btn=el.querySelector('.go');
    if(hqMode&&!alreadyOwned)btn.onclick=()=>{saveState.owned=[...new Set([...(saveState.owned||[]),+cid])];persist();renderPrincessDeploymentPanel();renderDeployment()};
    else if(!hqMode&&!deployedElsewhere)btn.onclick=()=>{const arr=new Set((battleState.summonedPrincesses||[]).map(Number));arr.add(+cid);battleState.summonedPrincesses=[...arr];selectedDeployGeneral=+cid;hidePrincessDeploymentPanel();renderDeployment()};root.appendChild(el)
  })
}
function openPrincessDeploymentPanel(){if(deploymentContext!=='hq'&&!deploymentTargetUnit())return;renderPrincessDeploymentPanel();playNativeFormOpenSfx('form_princess');document.getElementById('princess-panel')?.classList.add('show')}
function commitGeneralDeployment(){
  if(deploymentContext!=='battle')return false;
  const target=deploymentTargetUnit();if(!target||selectedDeployGeneral==null)return false;const cid=+selectedDeployGeneral;if(!owns(cid)){flash('该将领尚未加入指挥部');return false}
  const assigned=EW4GeneralDeployment.assign(battleState.units,target.index,cid,battleState.playerOwner,commanderHpBonusForDeployment);if(!assigned)return false;
  battleState.assignments.set(+target.index,cid);writeBattleSave('auto',true);playSfx('select');return true
}
bindTutorialUI(document.getElementById('deploy-back'),'winbtn_back');document.getElementById('deploy-back').onclick=()=>{hidePrincessDeploymentPanel();deploymentTargetUnitIndex=null;selectedDeployGeneral=null;if(deploymentContext==='hq'){deploymentContext='battle';go('main');return}go('battle');renderBattleActions();renderBattle()};
document.getElementById('deploy-princess').onclick=openPrincessDeploymentPanel;
document.getElementById('princess-close').onclick=hidePrincessDeploymentPanel;
document.getElementById('deploy-clear').onclick=()=>{};
document.getElementById('deploy-college').onclick=()=>{hidePrincessDeploymentPanel();academyReturnScreen='deploy';go('academy')};
document.getElementById('deploy-shop').onclick=()=>{if(deploymentContext==='hq')openHeadquartersShop()};
document.getElementById('deploy-confirm').onclick=()=>{if(deploymentContext!=='battle')return;hidePrincessDeploymentPanel();if(commitGeneralDeployment()){const target=deploymentTargetUnit(),name=target?.commander_id?commanderName(COMMANDERS?.[String(target.commander_id)]):'';deploymentTargetUnitIndex=null;selectedDeployGeneral=null;go('battle');renderBattleActions();renderBattle();flash(name?`${name} 已部署到该部队`:'将领已部署')}};

/* ---------- Battle rendering ---------- */
function img(path){if(!path)return null;if(imageCache.has(path))return imageCache.get(path);const im=new Image();im.decoding='async';im.src=path;im.onload=()=>renderBattle();imageCache.set(path,im);return im}
function worldPoint(q,r){return EW4NativeHex.cellCenter(q,r)}
function screenPoint(q,r){const p=worldPoint(q,r),c=battleState.camera;return{x:(p.x-c.x)*c.zoom+284,y:(p.y-c.y)*c.zoom+160}}
function screenToWorld(x,y){const c=battleState.camera;return EW4NativeCamera.screenToWorld(c,x,y)}
const CAMERA_MIN_ZOOM=EW4NativeCamera.MIN_ZOOM,CAMERA_MAX_ZOOM=EW4NativeCamera.MAX_ZOOM,CAMERA_DETAIL_ZOOM=EW4NativeCamera.DETAIL_ZOOM;
function cameraMapSize(){const S=battleState,im=S?.mapImg,w=im?.naturalWidth||im?.width||((S?.world?.width||79)*EW4NativeHex.COL_STEP),h=im?.naturalHeight||im?.height||((S?.world?.height||68)*EW4NativeHex.ROW_STEP);return{w,h}}
function clampCamera(c=battleState?.camera,edgeMargin=0){if(!battleState||!c)return c;c.zoom=EW4NativeCamera.clampZoom(c.zoom);const size=cameraMapSize(),hx=284/c.zoom,hy=160/c.zoom,m=Math.max(0,+edgeMargin||0),minX=hx-m,maxX=size.w-hx+m,minY=hy-m,maxY=size.h-hy+m;c.x=minX<=maxX?Math.max(minX,Math.min(maxX,c.x)):size.w/2;c.y=minY<=maxY?Math.max(minY,Math.min(maxY,c.y)):size.h/2;return c}
function clearSelectionForNativeLowZoom(){if(!battleState||(battleState.camera?.zoom??1)>=CAMERA_DETAIL_ZOOM)return;if(battleState.selected||battleState.selectedObject||battleState.selectedCell){battleState.selected=null;battleState.selectedObject=null;battleState.selectedCell=null;battleState.reachable=new Map();closeBattlePanels();updateCellSummary(null,null);renderBattleActions()}}
function applyCameraPose(pose,edgeMargin=0){if(!battleState||!pose)return;const c=battleState.camera,wasDetail=EW4NativeCamera.detailInteractionEnabled(c.zoom);c.x=pose.x;c.y=pose.y;c.zoom=pose.zoom;clampCamera(c,edgeMargin);if(wasDetail&&!EW4NativeCamera.detailInteractionEnabled(c.zoom))clearSelectionForNativeLowZoom()}
function zoomCameraAt(nextZoom,sx=284,sy=160,worldAnchor=null){if(!battleState)return;applyCameraPose(EW4NativeCamera.zoomAt(battleState.camera,nextZoom,sx,sy,worldAnchor))}
function unitVisualZoom(z=battleState?.camera?.zoom||1){return Math.max(.76,Math.min(1.18,Math.pow(z,.46)))}
function nearestCell(wx,wy){const c=EW4NativeHex.worldToCell(wx,wy),h=battleState.battle.header;return c.q>=h.origin_x&&c.r>=h.origin_y&&c.q<h.origin_x+h.width&&c.r<h.origin_y+h.height?c:null}
function hexPath(x,y,scale=1){const pts=EW4NativeHex.vertices(x,y,scale);ctx.beginPath();pts.forEach(([px,py],i)=>i?ctx.lineTo(px,py):ctx.moveTo(px,py));ctx.closePath()}
function ownershipIndex(q,r){const b=battleState.battle,h=b.header,x=q-h.origin_x,y=r-h.origin_y;if(x<0||y<0||x>=h.width||y>=h.height)return-1;return y*h.width+x-(b.owner_index_bias??0)}
function ownerAt(q,r){const idx=ownershipIndex(q,r);if(idx<0)return 255;return battleState.ownership[idx]??255}
function nativeOwnerAtForBattle(b,q,r){const h=b?.header||{},x=+q-(+h.origin_x||0),y=+r-(+h.origin_y||0);if(x<0||y<0||x>=+h.width||y>=+h.height)return 255;const idx=y*(+h.width||0)+x-(b?.owner_index_bias??0);return idx>=0?(b?.ownership?.[idx]??255):255}
function setOwnerAt(q,r,owner){const idx=ownershipIndex(q,r);if(idx>=0&&idx<battleState.ownership.length)battleState.ownership[idx]=owner}
function countryColor(i,alpha=null){const c=battleState.battle.countries[i];if(!c)return`rgba(100,100,100,${alpha==null?40/255:alpha})`;const a=c.rgba||[100,100,100,40],aa=alpha==null?Math.max(0,Math.min(1,(+a[3]||40)/255)):alpha;return`rgba(${a[0]},${a[1]},${a[2]},${aa})`}
function countryCode(i){return battleState.battle.countries[i]?.code||'fra'}
function terrainCell(q,r){const w=battleState.world;if(q<0||r<0||q>=w.width||r>=w.height)return null;return w.cells[r*w.width+q]}
function armyStat(u){const code=countryCode(u.owner),key=`${u.army_name}|${u.grade}`;return ARMIES[code]?.[key]||Object.values(ARMIES).find(x=>x[key])?.[key]||{movement:6,minatk:1,maxatk:5,minatkrange:1,maxatkrange:1,type:'infantry',weapon:'gun',strength:u.max_hp||100,consumption:0}}
function ensureUnitTrainingState(u,{fromBTL=false}={}){if(!u)return u;if(u.trainingLevel==null){const raw=fromBTL&&Array.isArray(u.raw)?+u.raw[20]:0;u.trainingLevel=EW4NativeTraining.level(raw)}else u.trainingLevel=EW4NativeTraining.level(u.trainingLevel);if(u.trainingExp==null||!Number.isFinite(+u.trainingExp))u.trainingExp=0;else u.trainingExp=Math.max(0,Math.trunc(+u.trainingExp));return u}
function trainingDefenseBonus(u){return EW4NativeTraining.defenseBonus(u)}
function trainingRoundHeal(u){return EW4NativeTraining.roundHeal(u)}
function readyKey(u){if(['Privateer','Frigate','Battleship','Ironclad','Small Fortress','Fortress','Large Fortress','Coastal Fort'].includes(u.army_name))return u.army_name;const g=Math.max(1,(u.grade||0)+1),cc=countryCode(u.owner);return READY[`${u.army_name} ${cc} ${g}`]?`${u.army_name} ${cc} ${g}`:`${u.army_name} ${g}`}
let battleAnimUntil=0,battleAnimRaf=0,battleIdleRaf=0,battleIdleLast=0;
function currentGameSpeed(){return Math.max(1,Math.min(5,Math.trunc(+saveState.gameSpeed||EW4NativeCamera.DEFAULT_GAME_SPEED)))}
function showNativeGrid(){return !!saveState.showGrids}
function startNativeProgrammaticCamera(target,{targetZoom=null,gameSpeed=currentGameSpeed()}={}){
  if(!battleState||!target)return false;
  const probe={x:Number.isFinite(+target.x)?+target.x:battleState.camera.x,y:Number.isFinite(+target.y)?+target.y:battleState.camera.y,zoom:targetZoom==null?battleState.camera.zoom:EW4NativeCamera.clampZoom(targetZoom)};
  /* Native target setup clamps camera bounds before the velocity motor starts. */
  const bounded={...probe};clampCamera(bounded);
  const started=EW4NativeCamera.startProgrammaticMove(battleState.camera,bounded,{gameSpeed,targetZoom:targetZoom==null?null:bounded.zoom});
  applyCameraPose(started.camera);battleState.cameraMotion=started.motion.active?{...started.motion,lastTs:performance.now()}:null;
  if(battleState.cameraMotion)requestBattleAnimation(32);return !!battleState.cameraMotion;
}
function stepNativeProgrammaticCamera(now=performance.now()){
  const m=battleState?.cameraMotion;if(!m)return false;
  const dt=Math.max(0,Math.min(.1,(now-(m.lastTs||now))/1000||1/60)),step=EW4NativeCamera.stepProgrammaticMove(battleState.camera,m,dt);
  applyCameraPose(step.camera);battleState.cameraMotion=step.active?{...step.motion,lastTs:now}:null;
  if(!step.active&&battleState.cameraAfterMotion){const state=battleState,fn=state.cameraAfterMotion;state.cameraAfterMotion=null;state.cameraPresentationPending=false;state.cameraPresentationKind=null;setTimeout(()=>{if(battleState===state&&!state.ended)fn()},0)}
  return !!battleState.cameraMotion;
}
function nativePairFocusNeeded(source,target){
  if(!battleState||!source||!target)return false;const c=battleState.camera;
  if(!EW4NativeCamera.detailInteractionEnabled(c.zoom))return true;
  return !(EW4NativeCamera.focusRectVisible(c,EW4NativeHex.cellRect(source.q,source.r))&&EW4NativeCamera.focusRectVisible(c,EW4NativeHex.cellRect(target.q,target.r)));
}
function queueNativePlayerPairFocus(source,target,continuation){
  if(!battleState||!isMine(source)||typeof continuation!=='function'||!nativePairFocusNeeded(source,target))return false;
  const a=EW4NativeHex.cellCenter(source.q,source.r),b=EW4NativeHex.cellCenter(target.q,target.r),zoom=battleState.camera.zoom,targetZoom=zoom<CAMERA_DETAIL_ZOOM?1:null;
  const started=startNativeProgrammaticCamera({x:(a.x+b.x)*.5,y:(a.y+b.y)*.5},{targetZoom});
  if(!started)return false;
  battleState.cameraAfterMotion=continuation;battleState.cameraPresentationPending=true;battleState.cameraPresentationKind='player';closeBattlePanels();renderBattleActions();return true;
}
function queueNativeAIPairFocus(source,target,continuation){
  /* Native action presentation uses the same source/target focus controller for AI.
     The native skip-presentation flag bypasses this path, so Web AI fast-forward does too. */
  if(!battleState||battleState.phase!=='ai'||battleState.aiFastForward||typeof continuation!=='function'||!nativePairFocusNeeded(source,target))return false;
  const a=EW4NativeHex.cellCenter(source.q,source.r),b=EW4NativeHex.cellCenter(target.q,target.r),zoom=battleState.camera.zoom,targetZoom=zoom<CAMERA_DETAIL_ZOOM?1:null;
  const started=startNativeProgrammaticCamera({x:(a.x+b.x)*.5,y:(a.y+b.y)*.5},{targetZoom});
  if(!started)return false;
  battleState.cameraAfterMotion=continuation;battleState.cameraPresentationPending=true;battleState.cameraPresentationKind='ai';renderBattleActions();return true;
}
function requestBattleAnimation(ms=720){battleAnimUntil=Math.max(battleAnimUntil,performance.now()+ms);if(battleAnimRaf)return;const tick=()=>{battleAnimRaf=0;if(!battleState)return;const now=performance.now(),cameraMoving=stepNativeProgrammaticCamera(now);renderBattle();if(now<battleAnimUntil||cameraMoving)battleAnimRaf=requestAnimationFrame(tick)};battleAnimRaf=requestAnimationFrame(tick)}
function setUnitPresentationTransient(u,key,value){if(!u)return value;const d=Object.getOwnPropertyDescriptor(u,key);if(d&&d.enumerable===false)u[key]=value;else Object.defineProperty(u,key,{value,writable:true,configurable:true,enumerable:false});return value}
function attackAnimationProfile(u){
  const k=readyKey(u),a=ATTACK_POSES?.[k],r=RELOAD_POSES?.[k],f=FINISH_POSES?.[k];
  const ad=Math.max(1,+a?.duration||32),rd=Math.max(1,+r?.duration||0),fd=Math.max(1,+f?.duration||0),sum=ad+rd+fd;
  const totalMs=Math.max(760,Math.min(1580,Math.round(sum*11.2)));return{attackEnd:ad/sum,reloadEnd:(ad+rd)/sum,totalMs};
}
function nativeAnimationUnitName(u){const k=readyKey(u);return NATIVE_ANIM_PACK?.units?.[k]?k:null}
function nativeAnimationTargetClass(u){if(!u)return'';if(isFort(u))return'fort';return armyStat(u).type||''}
function startAttackAnim(u,target=null,ms=null){
  if(!u)return;const now=performance.now(),nativeName=nativeAnimationUnitName(u);
  if(nativeName&&window.EW4NativeAnimation){
    const st=armyStat(u),a0=EW4NativeHex.cellCenter(u.q,u.r),a1=target?EW4NativeHex.cellCenter(target.q,target.r):null,direction=a1?(a1.x<a0.x?'left':'right'):(u.nativeFacing||'right');u.nativeFacing=direction;const player=new EW4NativeAnimation.NativeAnimationPlayer(NATIVE_ANIM_PACK,nativeName,{weapon:st.weapon||'',targetClass:nativeAnimationTargetClass(target),direction},0);
    for(const phase of player.chain||[])if(phase?.asset?.resource)preloadCompactBileResource(phase.asset.resource);
    const speed=(battleState?.aiFastForward&&!isMine(u))?Math.max(1,player.activeDurationMs/90):1,realMs=Math.max(1,player.activeDurationMs/speed),attackPhase=(player.chain||[]).find(x=>x?.kind==='attack'),authoredAttackMs=attackPhase?.asset?EW4NativeAnimation.rawDurationMs(attackPhase.asset):player.activeDurationMs;
    setUnitPresentationTransient(u,'attackImpactDelayMs',Math.max(1,Math.min(realMs,authoredAttackMs/speed)));u.nativeAnim={player,start:now,presentationSpeed:speed,until:now+realMs,unitName:nativeName};u.attackAnimStart=0;u.attackPoseUntil=now+realMs;
    scheduleNativeAttackSfx(u,target,speed);if(battleState&&isMine(u))battleState.inputLockedUntil=Math.max(battleState.inputLockedUntil||0,now+realMs);requestBattleAnimation(realMs+40);return realMs;
  }
  const prof=attackAnimationProfile(u);ms=ms==null?prof.totalMs:ms;let presentationSpeed=1;if(battleState?.aiFastForward&&!isMine(u)){presentationSpeed=Math.max(1,ms/90);ms=Math.min(ms,90)}scheduleNativeAttackSfx(u,target,presentationSpeed);setUnitPresentationTransient(u,'attackImpactDelayMs',Math.max(1,Math.min(ms,ms*prof.attackEnd)));u.attackAnimStart=now;u.attackPoseUntil=now+ms;if(battleState&&isMine(u))battleState.inputLockedUntil=Math.max(battleState.inputLockedUntil||0,now+ms);requestBattleAnimation(ms+40);return ms
}
function attackImpactDelayMs(u,totalMs=0){const n=+u?.attackImpactDelayMs;return Number.isFinite(n)&&n>0?Math.min(Math.max(1,+totalMs||n),n):Math.max(1,+totalMs||1)}
function nativeAnimationSample(u,now=performance.now()){
  const a=u?.nativeAnim;if(!a||!NATIVE_ANIM_PACK)return null;
  const elapsed=Math.max(0,now-a.start)*(a.presentationSpeed||1),s=a.player.sample(elapsed),asset=NATIVE_ANIM_PACK.assets?.[s.assetId];
  if(now>=a.until){u.nativeAnim=null;return null}return{s,asset,unit:NATIVE_ANIM_PACK.units[a.unitName]};
}
function staticNativePoseRect(u,m,p,uz){
  if(!m)return null;const ready=READY?.[readyKey(u)]||m,ax=+ready.x||0,ay=+ready.y||0,minx=Number.isFinite(+m.minx)?+m.minx:0,miny=Number.isFinite(+m.miny)?+m.miny:0,scale=.5*uz;
  return{x:p.x+(ax+minx)*scale,y:p.y+(ay+miny)*scale,w:(+m.w||1)*scale,h:(+m.h||1)*scale};
}
function nativeFrameDrawSpec(u,p,uz,now=performance.now()){
  const sample=nativeAnimationSample(u,now);if(!sample?.asset)return null;const {s,asset,unit}=sample,compact=compactBileResource(asset.resource);
  // Production/lean path: draw the original BILE motion directly from its atlas.
  // Pre-expanded runtime_sheet.png files are development cache only and are not
  // required for rendering. Raw BILE coordinates are already world-relative, so
  // only the native Unit anchor is added here (no second world_union translation).
  if(compact?.bile&&compact?.atlas?.complete){const itemIndex=compact.bile.nameToItem[asset.motion_name],origin=EW4NativeAnimation.compactDrawOrigin(unit,p,uz);if(itemIndex!==undefined)return{kind:'compact',bile:compact.bile,atlas:compact.atlas,itemIndex,frameIndex:s.frameIndex,...origin}}
  return null;
}
function nativeReadyFrameDrawSpec(u,p,uz,now=performance.now()){
  const nativeName=nativeAnimationUnitName(u),unit=nativeName?NATIVE_ANIM_PACK?.units?.[nativeName]:null;if(!unit||!window.EW4NativeAnimation)return null;
  const direction=(isSeaUnit(u)||isFort(u))?(u.nativeFacing==='left'?'left':'right'):'all',motion=EW4NativeAnimation.pickMotion(unit,'ready',0,direction);if(!motion)return null;
  const asset=NATIVE_ANIM_PACK.assets?.[motion.asset],compact=asset?.resource?compactBileResource(asset.resource):null;if(!asset||!compact?.bile||!compact?.atlas?.complete)return null;
  const itemIndex=compact.bile.nameToItem[asset.motion_name];if(itemIndex===undefined)return null;const duration=Math.max(1,EW4NativeAnimation.rawDurationMs(asset)),phase=((+u.index||0)*97)%duration,frameIndex=EW4NativeAnimation.frameAtElapsed(asset,(now+phase)%duration),origin=EW4NativeAnimation.compactDrawOrigin(unit,p,uz);return{kind:'compact',bile:compact.bile,atlas:compact.atlas,itemIndex,frameIndex,...origin};
}
function ensureNativeReadyLoop(){
  if(battleIdleRaf||!battleState||!document.getElementById('battle')?.classList.contains('active'))return;const tick=now=>{if(!battleState||!document.getElementById('battle')?.classList.contains('active')){battleIdleRaf=0;return}battleIdleRaf=requestAnimationFrame(tick);if((battleState.camera?.zoom??1)<CAMERA_DETAIL_ZOOM||battleAnimRaf)return;if(now-battleIdleLast>=41){battleIdleLast=now;renderBattle()}};battleIdleRaf=requestAnimationFrame(tick)
}
function unitDisplayWorldPointAt(u,now=performance.now()){
  const a=u?.moveAnim;
  if(!a||!Array.isArray(a.path)||a.path.length<2||now>=a.until)return worldPoint(u.q,u.r);
  const span=Math.max(1,a.until-a.start),p=Math.max(0,Math.min(.999999,(now-a.start)/span));
  const segs=a.path.length-1,x=p*segs,i=Math.min(segs-1,Math.floor(x)),f=x-i;
  const A=worldPoint(a.path[i].q,a.path[i].r),B=worldPoint(a.path[i+1].q,a.path[i+1].r);if(isSeaUnit(u)||u.embarked)u.nativeFacing=B.x<A.x?'left':'right';
  return{x:A.x+(B.x-A.x)*f,y:A.y+(B.y-A.y)*f};
}
function unitDisplayWorldPoint(u){return unitDisplayWorldPointAt(u,performance.now())}
function unitScreenPoint(u){const p=unitDisplayWorldPoint(u),c=battleState.camera;return{x:(p.x-c.x)*c.zoom+284,y:(p.y-c.y)*c.zoom+160}}
function startMoveAnim(u,path){if(!u||!Array.isArray(path)||path.length<2)return;const now=performance.now(),a=worldPoint(path[0].q,path[0].r),b=worldPoint(path[1].q,path[1].r);if(isSeaUnit(u)||u.embarked||isFort(u))u.nativeFacing=b.x<a.x?'left':'right';const normal=Math.max(220,Math.min(1180,(path.length-1)*150)),ms=(battleState?.aiFastForward&&!isMine(u))?Math.min(80,normal):normal;u.moveAnim={path,start:now,until:now+ms};spawnNativeMovementEffect(u,u.moveAnim);if(battleState&&isMine(u))battleState.inputLockedUntil=Math.max(battleState.inputLockedUntil||0,now+ms);requestBattleAnimation(ms+30)}
function unitVisual(u){
  const k=readyKey(u),now=performance.now();
  if(u?.attackPoseUntil&&u?.attackAnimStart&&now<u.attackPoseUntil){
    const p=Math.max(0,Math.min(1,(now-u.attackAnimStart)/(u.attackPoseUntil-u.attackAnimStart))),prof=attackAnimationProfile(u);
    let src;
    if(p<prof.attackEnd)src=ATTACK_POSES?.[k];
    else if(p<prof.reloadEnd)src=RELOAD_POSES?.[k]||ATTACK_POSES?.[k];
    else src=FINISH_POSES?.[k]||RELOAD_POSES?.[k]||ATTACK_POSES?.[k];
    return src||READY?.[k]||null;
  }
  return READY?.[k]||null;
}
function unitImage(u){const m=unitVisual(u);return m?img(m.file):null}
function specialFacilityType(o){const n=+o?.extra||0;return n===1?'trade':n===2?'shop':n===3?'bar':null}
function specialFacilityMarker(o){const t=specialFacilityType(o);return t?`marker_${t}.png`:null}
function buildingKey(o){let lv=Math.max(1,o.level||1),code=countryCode(o.owner),east=['rus','tur','per'].includes(code),style=east?'east':'west';if(o.construction_type==='city')return`city_${style}_lv${Math.min(7,lv)}.png`;if(o.construction_type==='industry')return`factory_${style}_lv${Math.min(4,lv)}.png`;if(o.construction_type==='stable')return`stable_${style}_lv${Math.min(3,lv)}.png`;if(o.construction_type==='port')return`port_${Math.min(4,lv)}.png`;if(o.construction_type==='farmland')return`farm_${1+(o.q+o.r)%4}_lv${Math.min(3,lv)}.png`;return null}
function drawSpriteManifest(key,q,r,scale=.5){const m=SPRITES[key];if(!m)return;const im=img(m.file);if(!im?.complete)return;const p=screenPoint(q,r),s=scale*battleState.camera.zoom;ctx.drawImage(im,p.x-m.refx*s,p.y-m.refy*s,m.w*s,m.h*s)}
function terrainSprite(t){if(!t||t.terrain_id<1)return null;const td=WORLDS.terrains[t.terrain_id];if(!td?.tiles?.length)return null;const idx=(t.variant===255?0:t.variant)%td.tiles.length;return td.tiles[idx]?.image}
function drawTerrain(q,r){const t=terrainCell(q,r),name=terrainSprite(t);if(!name)return;const m=TERRAIN[name],im=m&&img(m.file);if(!im?.complete)return;const p=screenPoint(q,r),s=.5*battleState.camera.zoom;ctx.drawImage(im,p.x-m.refx*s,p.y-m.refy*s,m.w*s,m.h*s)}
function visibleBounds(){const w0=screenToWorld(-100,-100),w1=screenToWorld(668,420);return{minx:Math.min(w0.x,w1.x),maxx:Math.max(w0.x,w1.x),miny:Math.min(w0.y,w1.y),maxy:Math.max(w0.y,w1.y)}}
function cellVisible(q,r,b=visibleBounds()){const p=worldPoint(q,r);return p.x>b.minx-180&&p.x<b.maxx+180&&p.y>b.miny-180&&p.y<b.maxy+180}
function relationBetweenOwners(a,b){const spec=battleState?.mode==='campaign'?EW4NativeCampaign?.battleSpec?.(NATIVE_CAMPAIGN_TARGETS,battleState.battle):null;if(spec)return EW4NativeCampaign.campaignRelation(spec,+a,+b);return EW4CountryTurn.relation(battleState.battle,+a,+b,{mode:battleState.mode,playerOwner:battleState.playerOwner})}
function relationOwner(owner){if(owner===255||owner==null)return'neutral';if(+owner===+battleState.playerOwner)return'player';return relationBetweenOwners(battleState.playerOwner,owner)}
function isHostileOwner(owner){return relationOwner(owner)==='hostile'}
function isMine(u){return u&&u.owner===battleState.playerOwner}

function nativeBattleMeta(){return BATTLE_NATIVE?.battles?.[battleState?.battle?.file]||null}
function nativeObjectives(){return nativeBattleMeta()?.objectives||[]}
function nativeEvents(){return nativeBattleMeta()?.events||[]}
function nativeRoundDialogueEvents(round){return nativeEvents().filter(e=>+e.trigger_type===2&&+e.param_a===4&&+e.param_b===+round&&e.dialogue?.text).sort((a,b)=>(+a.sequence-+b.sequence)||(+a.event_id-+b.event_id))}
function nativeRoundFireEvents(round){return nativeEvents().filter(e=>+e.trigger_type===2&&+e.param_a===5&&+e.param_b===+round&&+e.param_c>0).sort((a,b)=>(+a.sequence-+b.sequence)||(+a.param_c-+b.param_c))}
function nativeRoundMoraleEvents(round){return nativeEvents().filter(e=>EW4NativeEvent.isRoundMoraleEvent(e,round)).sort((a,b)=>(+a.sequence-+b.sequence)||(+a.event_id-+b.event_id))}
function nativeEventCell(e){const pos=+e?.param_c||0,gw=battleState?.battle?.header?.map_id===2?55:79;return{pos,q:pos%gw,r:Math.floor(pos/gw)}}
function nativeEventKey(e){return`${e.trigger_type}:${e.param_a}:${e.param_b}:${e.sequence}:${e.event_id}:${e.param_c}`}
function nativeTriggerBindingList(kind){
  const f=battleState?.battle?.file;if(!f||!NATIVE_TRIGGER_TARGETS)return[];
  return (NATIVE_TRIGGER_TARGETS?.[kind]?.[f]||[]);
}
function nativeEventForBinding(type,binding){
  return nativeEvents().find(e=>+e.trigger_type===+type&&+e.sequence===+binding.sequence&&(!binding.event_id||+e.event_id===+binding.event_id))||null;
}
function applyNativeFireEvent(e){
  if(!battleState||+e?.param_c<=0)return{applied:false,blocked:false};
  battleState.fireCells??=new Set();const c=nativeEventCell(e);
  if(fireproofAt(c.q,c.r)){battleState.fireCells.delete(`${c.q},${c.r}`);return{applied:false,blocked:true,...c}}
  battleState.fireCells.add(`${c.q},${c.r}`);playSfx('fire');requestBattleAnimation(1100);return{applied:true,blocked:false,...c}
}
function applyNativeScriptEvent(e,reason='原生事件'){
  if(!battleState||!e)return false;battleState.nativeAppliedEvents??=new Set();const key=nativeEventKey(e);if(battleState.nativeAppliedEvents.has(key))return false;
  battleState.nativeAppliedEvents.add(key);const action=+e.param_a,morale=EW4NativeEvent.moraleForAction(action);let count=0,fire=null;
  if(morale!==null&&e.country)count=EW4NativeEvent.applyCountryMorale(battleState.units,e.country,action,battleState.round,countryCode);
  if(action===5)fire=applyNativeFireEvent(e);
  if(e.dialogue?.text)queueNativeDialogues([e]);
  const bits=[];if(morale!==null&&e.country)bits.push(`${e.country.toUpperCase()} 士气 ${morale>0?'+':''}${morale}（${count}支）`);if(fire?.applied)bits.push(`起火 ${fire.q},${fire.r}`);if(fire?.blocked)bits.push(`防火阻止 ${fire.q},${fire.r}`);
  renderBattle();if(bits.length)flash(`${reason}：${bits.join(' · ')}`,1900);if(!battleState.dialogueActive)writeBattleSave('auto',true);return true;
}
function fireNativeCaptureEventsForObject(o){
  if(!o)return 0;let n=0;for(const b of nativeTriggerBindingList('capture')){if(+b.target_index!==+o.index)continue;const e=nativeEventForBinding(0,b);if(e&&applyNativeScriptEvent(e,'占领触发'))n++}return n;
}
function fireNativeDeathEventsForUnit(u){
  if(!u)return 0;let n=0;for(const b of nativeTriggerBindingList('death')){if(+b.target_index!==+u.index)continue;const e=nativeEventForBinding(1,b);if(e&&applyNativeScriptEvent(e,'击毁触发'))n++}return n;
}
function fireproofUnit(u){if(!u||u.dead)return false;const c=effectiveCommanderForUnit(u);return EW4Combat.hasSkill(c,2)||hasEquipmentFunction(u,16)}
function fireproofAt(q,r){const u=unitAt(q,r);return !!(u&&fireproofUnit(u))}
function applyNativeRoundFireEvents(round){
  if(!battleState)return[];battleState.nativeAppliedEvents??=new Set();battleState.fireCells??=new Set();const applied=[],blocked=[];
  for(const e of nativeRoundFireEvents(round)){const key=nativeEventKey(e);if(battleState.nativeAppliedEvents.has(key))continue;battleState.nativeAppliedEvents.add(key);const c=nativeEventCell(e);if(fireproofAt(c.q,c.r)){battleState.fireCells.delete(`${c.q},${c.r}`);blocked.push({...e,...c});if(e.dialogue?.text)queueNativeDialogues([e]);continue}battleState.fireCells.add(`${c.q},${c.r}`);applied.push({...e,...c});if(e.dialogue?.text)queueNativeDialogues([e])}
  if(applied.length||blocked.length){playSfx('fire');requestBattleAnimation(1100);renderBattle();flash(`原生火灾事件：起火 ${applied.length}${blocked.length?` · 防火 ${blocked.length}`:''}`,1800)}return applied
}
function applyNativeRoundMoraleEvents(round){
  if(!battleState)return[];battleState.nativeAppliedEvents??=new Set();const applied=[];
  for(const e of nativeRoundMoraleEvents(round)){const key=nativeEventKey(e);if(battleState.nativeAppliedEvents.has(key))continue;battleState.nativeAppliedEvents.add(key);const base=EW4NativeEvent.moraleForAction(e.param_a),count=EW4NativeEvent.applyCountryMorale(battleState.units,e.country,e.param_a,round,countryCode);applied.push({...e,morale:base,unitCount:count});if(e.dialogue?.text)queueNativeDialogues([e])}
  if(applied.length){const up=applied.filter(x=>x.morale>0).reduce((n,x)=>n+x.unitCount,0),down=applied.filter(x=>x.morale<0).reduce((n,x)=>n+x.unitCount,0);renderBattle();flash(`原生士气事件：振奋 ${up} · 低落 ${down}`,1800)}
  return applied
}
function fireNativeRoundEvents(round){const morale=applyNativeRoundMoraleEvents(round);const fires=applyNativeRoundFireEvents(round);const talks=nativeRoundDialogueEvents(round);if(talks.length)queueNativeDialogues(talks);return{morale,fires,talks}}

function queueNativeDialogues(events){
  if(!battleState||!events?.length)return;
  battleState.dialogueQueue??=[];battleState.nativeFiredEvents??=new Set();
  for(const e of events){const key=`${e.sequence}:${e.event_id}`;if(battleState.nativeFiredEvents.has(key))continue;battleState.nativeFiredEvents.add(key);battleState.dialogueQueue.push(e)}
  if(!battleState.dialogueActive)showNextNativeDialogue();
}
function showNextNativeDialogue(){
  if(!battleState)return;const e=battleState.dialogueQueue?.shift(),el=document.getElementById('native-talk');
  if(!e){battleState.dialogueActive=false;el?.classList.remove('show','right');writeBattleSave('auto',true);return}
  battleState.dialogueActive=true;const d=e.dialogue||{},c=COMMANDERS?.[String(d.commander_id)],left=!!d.left;
  el.classList.toggle('right',!left);const pi=document.getElementById('native-talk-portrait'),pp=portrait(d.commander_id);if(pp){pi.src=pp;pi.style.display='block'}else pi.style.display='none';
  document.getElementById('native-talk-name').textContent=commanderName(c)||`将领 ${d.commander_id}`;document.getElementById('native-talk-text').textContent=d.text||'';el.classList.add('show');
}
function hideNativeDialogue(){const el=document.getElementById('native-talk');el?.classList.remove('show','right','system');if(battleState){battleState.dialogueActive=false;battleState.dialogueQueue=[];battleState.resultDialogueAfter=null}}
function fireNativeRoundDialogues(round){return fireNativeRoundEvents(round)}
function objectiveObjectByPosition(pos){return battleState?.objects?.find(o=>+o.pos===+pos)||null}
function nativeDisplayedTargets(){
  if(battleState?.mode==='campaign'&&window.EW4NativeCampaign){
    return[...EW4NativeCampaign.targetEntities(battleState,NATIVE_CAMPAIGN_TARGETS,1,ownerAt),...EW4NativeCampaign.targetEntities(battleState,NATIVE_CAMPAIGN_TARGETS,2,ownerAt)].map(x=>({...x,q:+x.q,r:+x.r,targetType:+x.type,legacy:false}))
  }
  return nativeObjectives().map(o=>{const obj=objectiveObjectByPosition(o.position);return{kind:'object',entity:obj,owner:obj?.owner,q:+o.q,r:+o.r,targetType:2,legacy:true,position:o.position}})
}
function targetStatus(t){
  if(t?.owner==null)return'unknown';if(+t.owner===+battleState.playerOwner)return'player';return isHostileOwner(+t.owner)?'hostile':'other'
}
function drawNativeObjectiveMarkers(){
  if(!battleState)return;const z=battleState.camera.zoom,star=SPRITES?.['stage_star.png'],im=star&&img(star.file),bounds=visibleBounds();
  for(const t of nativeDisplayedTargets()){
    if(t.q==null||t.r==null||!cellVisible(t.q,t.r,bounds))continue;
    const p=screenPoint(t.q,t.r),st=targetStatus(t),main=+t.targetType===1;
    ctx.save();ctx.globalAlpha=.96;
    if(im?.complete){const s=Math.max(12,18*z);ctx.drawImage(im,p.x-s/2,p.y-42*z,s,s)}
    else{ctx.fillStyle=main?'#ff5549':'#ffd965';ctx.font=`bold ${Math.max(10,13*z)}px sans-serif`;ctx.textAlign='center';ctx.fillText('★',p.x,p.y-27*z)}
    ctx.strokeStyle=main?'#ff5549':'#ffd965';ctx.lineWidth=Math.max(1.25,1.8*z);ctx.beginPath();ctx.arc(p.x,p.y-31*z,10*z,0,Math.PI*2);ctx.stroke();
    if(st==='player'){ctx.strokeStyle='#79df79';ctx.lineWidth=Math.max(1,1.1*z);ctx.beginPath();ctx.arc(p.x,p.y-31*z,13*z,0,Math.PI*2);ctx.stroke()}
    ctx.restore();
  }
}
function nativeObjectiveSummary(){
  const arr=nativeDisplayedTargets();if(!arr.length)return'本关 BTL 未记录战略目标点';
  return arr.map(t=>{const e=t.entity,name=e?.area_name||e?.construction_type||e?.unit_name||`格 ${t.q},${t.r}`,st=targetStatus(t),kind=+t.targetType===1?'红目标':'黄目标';return`${kind} ${name}${st==='player'?'✓':st==='hostile'?'⚔':'◆'}`}).join(' · ')
}
function nativeResultGeneralHtml(ids){
  const slots=[];for(let i=0;i<6;i++){const id=ids[i],c=id?COMMANDERS?.[String(id)]:null,p=id?portrait(id):'';if(!id||!c){slots.push('<div class="native-result-general empty"></div>');continue}slots.push(`<div class="native-result-general" data-commander="${id}">${p?`<img class="rg-portrait" src="${p}" alt="">`:''}<img class="rg-nameboard" src="assets/sprites/image_ui_hd/general_nameboard.png" alt=""><span class="rg-name">${commanderName(c)||c.name||id}</span></div>`)}return slots.join('')
}
function nativeResultDescription(kind,reason,result){return kind==='victory'&&result?.descriptionKey?(STRINGS?.[result.descriptionKey]||''):(STRINGS?.[`desc_failure ${reason==='turn-limit'?2:1}`]||reason||'')}
function showNativeResultNarration(text,after){
  if(!battleState){after?.();return}const el=document.getElementById('native-talk');if(!el||!text){after?.();return}hideNativeDialogue();battleState.dialogueActive=true;battleState.resultDialogueAfter=typeof after==='function'?after:null;el.classList.remove('right');el.classList.add('system','show');const pi=document.getElementById('native-talk-portrait');if(pi)pi.style.display='none';document.getElementById('native-talk-name').textContent='';document.getElementById('native-talk-text').textContent=text
}
function advanceNativeTalk(){
  if(!battleState?.dialogueActive)return;const cb=battleState.resultDialogueAfter;if(cb){battleState.resultDialogueAfter=null;const el=document.getElementById('native-talk');el?.classList.remove('show','right','system');battleState.dialogueActive=false;cb();return}showNextNativeDialogue()
}
function hideNativeVictoryText(){const el=document.getElementById('victory-text-overlay');el?.classList.remove('show');if(battleState?.victoryTextTimer){clearTimeout(battleState.victoryTextTimer);battleState.victoryTextTimer=null}}
function showNativeVictoryText(done){
  const el=document.getElementById('victory-text-overlay');if(!el){done?.();return}pauseBattleMusic();stopDefeatMusic();el.classList.remove('show');void el.offsetWidth;el.classList.add('show');playNativeSfxFile('sfx_celebrate.wav');const ref=battleState;const finish=()=>{if(ref!==battleState)return;el.classList.remove('show');if(battleState)battleState.victoryTextTimer=null;done?.()};battleState.victoryTextTimer=setTimeout(finish,4500)
}
function presentBattleResult(payload){
  if(!battleState||!payload)return;const{kind,result,battleName,lim,score,award,collect,generalIds}=payload,box=document.getElementById('battle-result'),title=document.getElementById('battle-result-title'),body=document.getElementById('battle-result-body');
  title.textContent=STRINGS?.[kind==='victory'?'title_victory':'title_failure']||(kind==='victory'?'胜  利':'失  败');box.classList.toggle('victory',kind==='victory');box.classList.toggle('defeat',kind!=='victory');
  const filled='assets/sprites/image_ui_hd/star_middle.png',empty='assets/sprites/image_ui_hd/diffcult_1.png',stars=Array.from({length:5},(_,i)=>`<img src="${i<score?filled:empty}" alt="">`).join('');
  body.innerHTML=`<div class="native-result-battle">${battleName}</div><div class="native-result-threshold"><img src="assets/sprites/image_ui_hd/star_board.png"><span>${lim.valid?lim.win:'-'}</span><span>${lim.valid?lim.best:'-'}</span></div><div class="native-result-round"><b>${STRINGS?.text_round||'回合'}</b><strong>${battleState.round}</strong></div><div class="native-result-stars">${stars}</div><div class="native-result-medals"><span>${STRINGS?.text_award||'奖励'}</span><img src="assets/sprites/image_ui_hd/medals.png"><b>${award}</b><span>${STRINGS?.text_gain||'获得'}</span><img src="assets/sprites/image_ui_hd/medals.png"><b>${collect}</b></div><div class="native-result-generals" aria-label="参战将领">${nativeResultGeneralHtml(generalIds)}</div>`;
  const retry=document.getElementById('battle-result-retry'),cont=document.getElementById('battle-result-continue'),exit=document.getElementById('battle-result-exit');if(kind==='victory'){cont.style.display='block';retry.style.display='none';exit.style.display='block'}else{cont.style.display='none';retry.style.display='block';exit.style.display='block'}
  box.classList.add('show');selectUnit(null);renderBattle();if(kind==='defeat'){const resultAudio=EW4NativeUIAudio?.battleResultAudio?.('defeat')||{};if(resultAudio.stopBattleMusic)pauseBattleMusic();stopDefeatMusic();if(resultAudio.bgm&&music){try{const d=document.getElementById('defeat-music');d.volume=bgVolume();d.currentTime=0;d.play().catch(()=>{})}catch(e){}}}
}
function showBattleResult(kind,reason=''){
  if(!battleState||battleState.ended)return;hideNativeDialogue();hideNativeVictoryText();battleState.ended=kind;pauseBattleMusic();stopDefeatMusic();
  const isCampaign=kind==='victory'&&battleState.mode==='campaign',campaignFile=isCampaign?campaignCanonicalFile(battleState.battle):'',previous=isCampaign?campaignBestRating(campaignFile):0,result=isCampaign&&window.EW4NativeResult?EW4NativeResult.result(battleState.round,battleState.battle,previous):null;if(result?.score){recordCampaignResult(battleState.battle,result.score);recordCampaignSecretUnlocks(battleState.battle)}
  if(kind==='victory'&&battleState.mode==='conquest')prepareConquestAchievementVictory();
  const battleName=battleState.battle.title_cn||battleState.battle.name_cn||battleState.battle.file,lim=result?.limits||nativeStageTurnLimits(battleState.battle),score=result?.score||0,award=result?.awardMedal||0,collect=Math.max(0,+battleState.collectMedal||0),generalIds=EW4NativeResult?.participatingGeneralIds?.(battleState.units,battleState.playerOwner,6)||[];
  const payload={kind,reason,result,battleName,lim,score,award,collect,generalIds},desc=nativeResultDescription(kind,reason,result);battleState.pendingResult=payload;selectUnit(null);renderBattle();
  showNativeResultNarration(desc,()=>{if(kind==='victory')showNativeVictoryText(()=>presentBattleResult(payload));else presentBattleResult(payload)})
}
function conquestAchievementContext(){return battleState?{mode:'conquest',victory:true,round:battleState.round,map:battleState.map,resources:battleState.resources}:null}
function prepareConquestAchievementVictory(){
  if(!battleState||battleState.mode!=='conquest'||battleState.ended!=='victory'||!window.EW4NativeConquestAchievement)return null;
  const prepared=EW4NativeConquestAchievement.prepareVictory(saveState,COMMANDERS,conquestAchievementContext());battleState.conquestAchievementPending=prepared;return prepared
}
function recordPreparedConquestAchievement(result){
  if(!battleState||!result||!window.EW4NativeConquestAchievement)return null;const out=EW4NativeConquestAchievement.recordResult(saveState,result);saveState=out.save;if(out.changed)persist();battleState.conquestAchievement=out.result;return out.result
}
function conquestScenarioMeta(){const m=String(battleState?.battle?.file||'').match(/^conquest(\d+)\.btl$/),idx=m?+m[1]:1;return conquests.find(x=>x.idx===idx)||conquests[0]}
function conquestRuleDigits(value){const v=Math.max(0,Math.min(999,Math.trunc(+value||0))),digits=String(v).padStart(3,'0').split('').map(Number);return digits.map((n,i)=>((i===0&&v<100)||(i===1&&v<10))?'':`<img src="assets/sprites/image_ui_hd/rule_${n}.png" alt="${n}">`).join('')}
function hideConquestComplete(){const el=document.getElementById('conquest-complete');el?.classList.remove('show');el?.setAttribute('aria-hidden','true')}
function showConquestSummary(result){
  if(!battleState||!result)return;const meta=conquestScenarioMeta(),title=document.getElementById('conquest-complete-title'),challenge=document.getElementById('conquest-challenge-group'),summary=document.getElementById('conquest-summary-group');if(title)title.textContent=STRINGS?.title_conquest_victory||'胜利征服';if(challenge)challenge.hidden=true;if(summary)summary.hidden=false;
  const pic=document.getElementById('conquest-complete-battle');if(pic)pic.src=`assets/textures/tex_conquest_${meta.tex}.png`;const archive=document.getElementById('conquest-complete-archive');if(archive)archive.src=`assets/sprites/image_ui_hd/button_rule_${result.kind==='europe'?'europa':result.kind}.png`;const digits=document.getElementById('conquest-complete-digits');if(digits)digits.innerHTML=conquestRuleDigits(result.storedValue??result.value);const round=document.getElementById('conquest-complete-round');if(round)round.textContent=String(Math.max(0,+battleState.round||0));const medal=document.getElementById('conquest-complete-medal');if(medal)medal.textContent=String(Math.max(0,+battleState.collectMedal||0));const el=document.getElementById('conquest-complete');el?.classList.add('show');el?.setAttribute('aria-hidden','false');playNativeFormOpenSfx('form_complete')
}
function showConquestChallenge(prepared){
  if(!battleState||!prepared?.asiaEligible)return false;const title=document.getElementById('conquest-complete-title'),challenge=document.getElementById('conquest-challenge-group'),summary=document.getElementById('conquest-summary-group'),home=document.getElementById('conquest-challenge-home'),desc=document.getElementById('conquest-challenge-desc');if(title)title.textContent=STRINGS?.title_challenge||'挑战';if(desc)desc.textContent=STRINGS?.desc_challenge||'阁下，是否要挑战亚洲？';if(home)home.textContent=STRINGS?.[battleState.map==='america'?'btn_chal_amer':'btn_chal_euro']||(battleState.map==='america'?'统治美洲':'统治欧洲');if(challenge)challenge.hidden=false;if(summary)summary.hidden=true;const el=document.getElementById('conquest-complete');el?.classList.add('show');el?.setAttribute('aria-hidden','false');playNativeFormOpenSfx('form_complete');return true
}
function continueConquestFromResult(){
  if(!battleState||battleState.mode!=='conquest'||battleState.ended!=='victory')return exitBattleResultToParent();const prepared=battleState.conquestAchievementPending||prepareConquestAchievementVictory();hideBattleResult();if(prepared?.asiaEligible){showConquestChallenge(prepared);return}const result=prepared?.normal?recordPreparedConquestAchievement(prepared.normal):null;if(result)showConquestSummary(result);else exitBattleResultToParent()
}
function chooseConquestChallenge(choice){const prepared=battleState?.conquestAchievementPending;if(!prepared)return;const candidate=choice==='asia'?prepared.asia:prepared.normal;if(!candidate)return;const result=recordPreparedConquestAchievement(candidate);if(result)showConquestSummary(result)}
function hideBattleResult(){document.getElementById('battle-result')?.classList.remove('show');hideNativeVictoryText();stopDefeatMusic()}
function campaignZoneForBattle(b){const m=String(b?.file||'').match(/^campaign(\d+)_/);return m?Math.max(1,Math.min(6,+m[1]||selectedZone)):selectedZone}
function campaignZoneCompleted(zone){return EW4NativeCampaignSession.zoneCompleted(saveState,zone)}
function recordCampaignZoneCompletion(zone,reward){const out=EW4NativeCampaignSession.recordZoneCompletion(saveState,zone,reward);if(!out.applied)return false;saveState=out.state;persist();return true}
function hideCampaignComplete(){document.getElementById('campaign-complete')?.classList.remove('show')}
function showCampaignComplete(zone){
  const already=campaignZoneCompleted(zone),reward=EW4NativeResult?.campaignCompletionReward?.(zone,already)||{medal:0,badge:0,score:0,image:'campaignend_fr.png'};if(!already)recordCampaignZoneCompletion(zone,reward);document.querySelector('.campaign-complete-title').textContent=STRINGS?.title_campaign_victory||'战役胜利';const pic=document.getElementById('campaign-complete-picture');pic.src=`assets/textures/${reward.image}`;document.getElementById('campaign-complete-medal').textContent=reward.medal;document.getElementById('campaign-complete-badge').textContent=reward.badge;document.getElementById('campaign-complete-score').textContent=reward.score;document.getElementById('campaign-complete')?.classList.add('show');playNativeFormOpenSfx('form_complete')
}
function continueCampaignFromResult(){
  if(!battleState?.battle)return;const zone=campaignZoneForBattle(battleState.battle),rows=campaignRows(zone),decision=EW4NativeResult?.campaignContinueDecision?.(rows,campaignCanonicalFile(battleState.battle))||{complete:false,continueBattle:0};hideBattleResult();if(decision.complete){continueBattlePendingZone=0;showCampaignComplete(zone);return}continueBattlePendingZone=decision.continueBattle>0?zone:0;go('main')
}

function renderBattle(){if(!battleState||!document.getElementById('battle').classList.contains('active'))return;ctx.clearRect(0,0,568,320);const S=battleState,c=S.camera;clampCamera(c);const h=S.battle.header,vb=visibleBounds(),mapSize=cameraMapSize(),ground=img('assets/maps/map_pt.png');
 /* Native map composition: repeated map_pt surface -> BTL territory tint -> transparent map coast/river overlay. */
 ctx.save();ctx.translate(284,160);ctx.scale(c.zoom,c.zoom);ctx.translate(-c.x,-c.y);if(ground?.complete){const pat=ctx.createPattern(ground,'repeat');if(pat){ctx.fillStyle=pat;ctx.fillRect(0,0,mapSize.w,mapSize.h)}}else{ctx.fillStyle='#77746d';ctx.fillRect(0,0,mapSize.w,mapSize.h)}ctx.restore();
 for(let q=h.origin_x;q<h.origin_x+h.width;q++)for(let r=h.origin_y;r<h.origin_y+h.height;r++){if(!cellVisible(q,r,vb))continue;const p=screenPoint(q,r),own=ownerAt(q,r);hexPath(p.x,p.y,c.zoom);if(own!==255){ctx.fillStyle=countryColor(own);ctx.fill()}if(showNativeGrid()){ctx.strokeStyle='rgba(30,42,37,.30)';ctx.lineWidth=Math.max(.45,c.zoom*.65);ctx.stroke()}}
 if(S.mapImg?.complete){ctx.save();ctx.translate(284,160);ctx.scale(c.zoom,c.zoom);ctx.translate(-c.x,-c.y);ctx.drawImage(S.mapImg,0,0);drawNativeMapTextWorld(S.map,c);ctx.restore()}
 for(let q=h.origin_x;q<h.origin_x+h.width;q++)for(let r=h.origin_y;r<h.origin_y+h.height;r++)if(cellVisible(q,r,vb))drawTerrain(q,r);
 for(const ins of S.installations||[]){if(!cellVisible(ins.q,ins.r,vb))continue;const d=INSTALLATIONS?.[ins.type];if(d?.image)drawSpriteManifest(d.image,ins.q,ins.r,.5)}
 if(S.selected){
  /* Original EW4 uses hollow destination/target rings rather than filling the whole hex. */
  for(const k of S.reachable.keys()){
    const[q,r]=k.split(',').map(Number),p=screenPoint(q,r),rz=unitVisualZoom(c.zoom);
    ctx.beginPath();ctx.ellipse(p.x,p.y+5*rz,10.5*rz,5.1*rz,0,0,Math.PI*2);
    ctx.strokeStyle='rgba(246,247,236,.88)';ctx.lineWidth=Math.max(1.1,1.45*rz);ctx.stroke();
  }
  for(const u of S.units){if(u.dead||!isHostilePair(S.selected,u))continue;if(inAttackRange(S.selected,u)){
    const p=unitScreenPoint(u),rz=unitVisualZoom(c.zoom);ctx.beginPath();ctx.ellipse(p.x,p.y+7*rz,24*rz,11*rz,0,0,Math.PI*2);ctx.strokeStyle='rgba(235,73,62,.92)';ctx.lineWidth=Math.max(1.4,2*rz);ctx.stroke()
  }}
 }
 [...S.objects].sort((a,b)=>a.r-b.r).forEach(o=>{if(!cellVisible(o.q,o.r,vb))return;const k=buildingKey(o);if(k)drawSpriteManifest(k,o.q,o.r,.5);const mk=specialFacilityMarker(o);if(mk)drawSpriteManifest(mk,o.q,o.r,.5);if(o.area_name&&['city','port'].includes(o.construction_type)){const p=screenPoint(o.q,o.r);ctx.font=`${7*c.zoom}px sans-serif`;ctx.textAlign='center';ctx.fillStyle='#f5ead2';ctx.strokeStyle='#15120f';ctx.lineWidth=2*c.zoom;ctx.strokeText(o.area_name,p.x,p.y+22*c.zoom);ctx.fillText(o.area_name,p.x,p.y+22*c.zoom)}});
 drawNativeFireCells();drawNativeObjectiveMarkers();const orderedUnits=[...S.units].filter(u=>unitPresentationVisible(u)&&cellVisible(u.q,u.r,vb)).sort((a,b)=>(a.r-b.r)||(a.q-b.q));orderedUnits.forEach(drawUnit);
 /* Native battle renderer services SelectUpper before the global effect manager. */
 if(S.selected&&!S.selected.dead){const p=unitScreenPoint(S.selected),uz=unitVisualZoom(c.zoom);ctx.beginPath();ctx.ellipse(p.x,p.y+8*uz,26*uz,12*uz,0,0,Math.PI*2);ctx.strokeStyle='rgba(250,244,203,.95)';ctx.lineWidth=Math.max(1.4,1.8*uz);ctx.stroke()}
 if(S.selectedObject){const p=screenPoint(S.selectedObject.q,S.selectedObject.r),uz=unitVisualZoom(c.zoom);ctx.beginPath();ctx.ellipse(p.x,p.y+8*uz,24*uz,11*uz,0,0,Math.PI*2);ctx.strokeStyle='rgba(250,244,203,.9)';ctx.lineWidth=Math.max(1.2,1.7*uz);ctx.stroke()}
 if(S.selectedCell){const p=screenPoint(S.selectedCell.q,S.selectedCell.r),uz=unitVisualZoom(c.zoom);ctx.beginPath();ctx.ellipse(p.x,p.y+8*uz,20*uz,9*uz,0,0,Math.PI*2);ctx.strokeStyle='rgba(250,244,203,.9)';ctx.lineWidth=Math.max(1.2,1.7*uz);ctx.stroke()}
 /* Original global particle/effect manager renders after all six battle layers. */
 drawNativeSimpleEffects();drawNativeGetMedalEffects();
 /* Native strategic markers are an additional low-zoom pass after particles. */
 if(c.zoom<CAMERA_DETAIL_ZOOM)orderedUnits.forEach(drawNativeLowZoomUnit);
 drawBattleFloats();positionNativeTutorialHighlight();ensureNativeReadyLoop()}
function drawNativeFireCells(){
  if(!battleState?.fireCells?.size)return;const atlas=img('assets/effects/anim_fire_hd.png'),z=battleState.camera.zoom,t=performance.now()/160;const frames=[[1,1,108,236],[110,1,105,230],[1,238,100,214],[110,232,98,214],[216,1,87,202],[304,1,96,191]];let i=0;
  for(const key of battleState.fireCells){const[q,r]=key.split(',').map(Number);if(!cellVisible(q,r,visibleBounds()))continue;const p=screenPoint(q,r),fr=frames[(Math.floor(t)+i++)%frames.length];ctx.save();ctx.globalAlpha=.86;if(atlas?.complete){const h=42*z,w=h*(fr[2]/fr[3]);ctx.drawImage(atlas,fr[0],fr[1],fr[2],fr[3],p.x-w/2,p.y-h+17*z,w,h)}else{ctx.fillStyle='rgba(255,110,30,.8)';ctx.beginPath();ctx.arc(p.x,p.y-10*z,9*z,0,Math.PI*2);ctx.fill()}ctx.restore()}
  if(performance.now()<battleAnimUntil)requestBattleAnimation(250)
}
function nativeLowZoomMarkerId(u){
  const raw=Number.isFinite(+u?.army_id)?+u.army_id:armyIdByName(u?.army_name),id=Math.trunc(raw);
  return id>=0&&id<=21?id:null;
}
function unitPresentationHp(u){return u?.presentationHp!=null&&Number.isFinite(+u.presentationHp)?+u.presentationHp:+u?.hp||0}
function unitPresentationVisible(u){return !!u&&(!u.dead||(Array.isArray(u.damagePresentationQueue)&&u.damagePresentationQueue.length>0))}
function drawNativeLowZoomUnit(u){
  /* Native zoom < 0.5 uses a screen-space strategic composition, not a tiny
     tactical model: relation ring -> dynamic HP arc -> mark_unit army icon. */
  const id=nativeLowZoomMarkerId(u),p=unitScreenPoint(u),rel=relationOwner(u.owner);
  const ringKey=EW4NativeLowZoom.relationSprite(rel),ring=SPRITES?.[ringKey],ringIm=ring&&img(ring.file);
  if(ringIm?.complete)ctx.drawImage(ringIm,p.x-ring.refx,p.y-ring.refy,ring.w,ring.h);

  const hpRatio=Math.max(0,Math.min(1,unitPresentationHp(u)/Math.max(1,+u.max_hp||1))),arc=EW4NativeLowZoom.hpArc(hpRatio);
  if(arc.sweep>0){ctx.save();ctx.beginPath();ctx.arc(p.x,p.y,arc.radius,arc.start,arc.end,false);ctx.strokeStyle=EW4NativeLowZoom.hpColorCss(hpRatio);ctx.lineWidth=arc.width;ctx.lineCap='butt';ctx.stroke();ctx.restore()}

  const m=id==null?null:SPRITES?.[`mark_unit_${id}.png`],im=m&&img(m.file);
  if(im?.complete){ctx.drawImage(im,p.x-m.refx,p.y-m.refy,m.w,m.h);return}
  /* Fallback only while the exact army marker atlas image is still loading. */
  ctx.save();ctx.fillStyle='rgba(245,241,222,.9)';ctx.beginPath();ctx.arc(p.x,p.y,3,0,Math.PI*2);ctx.fill();ctx.restore();
}
function drawNativeTacticalStatus(u,p,uz){
  /* Tactical battlefield status sprites are HD atlas assets. The native renderer
     converts them to the 568x320 logical canvas at 0.5 scale. Low-zoom markers
     are a separate screen-space path and intentionally stay full-size. */
  const k=.5*uz,rel=relationOwner(u.owner),ringKey=EW4NativeLowZoom.relationSprite(rel),ring=SPRITES?.[ringKey],ringIm=ring&&img(ring.file);
  if(ringIm?.complete)ctx.drawImage(ringIm,p.x-ring.refx*k,p.y-ring.refy*k,ring.w*k,ring.h*k);
  const hpRatio=Math.max(0,Math.min(1,unitPresentationHp(u)/Math.max(1,+u.max_hp||1))),arc=EW4NativeLowZoom.hpArc(hpRatio);
  if(arc.sweep>0){ctx.save();ctx.beginPath();ctx.arc(p.x,p.y,arc.radius*k,arc.start,arc.end,false);ctx.strokeStyle=EW4NativeLowZoom.hpColorCss(hpRatio);ctx.lineWidth=arc.width*k;ctx.lineCap='butt';ctx.stroke();ctx.restore()}
  const id=nativeLowZoomMarkerId(u),m=id==null?null:SPRITES?.[`mark_unit_${id}.png`],mi=m&&img(m.file);
  if(mi?.complete)ctx.drawImage(mi,p.x-m.refx*k,p.y-m.refy*k,m.w*k,m.h*k);
}
function nativeTransportProfile(u){const armored=hasEquipmentFunction(u,12);return{key:armored?'transportship2.png':'transportship1.png',naturalFacing:armored?'left':'right',armored}}
function drawNativeTransportShip(u,m,im,p,uz,naturalFacing='right'){if(!m||!im?.complete)return false;const k=.5*uz,desired=u.nativeFacing||naturalFacing,flip=desired!==naturalFacing;if(flip){ctx.save();ctx.translate(p.x,p.y);ctx.scale(-1,1);ctx.drawImage(im,-m.refx*k,-m.refy*k,m.w*k,m.h*k);ctx.restore()}else ctx.drawImage(im,p.x-m.refx*k,p.y-m.refy*k,m.w*k,m.h*k);return true}
function drawNativeUnitFlag(u,p,uz,now=performance.now()){
  /* Original battlefield flag = flagpole + four-frame nation cloth animation.
     flagpole's native ref (10,7) is the cloth attachment point, so both assets
     share the same top anchor and the pole naturally reaches the unit base. */
  const pole=SPRITES?.['flagpole.png'],pi=pole&&img(pole.file);if(!pole||!pi?.complete)return;
  const frame=1+((Math.floor(now/120)+Math.max(0,+u.index||0))%4),flag=SPRITES?.[`${countryCode(u.owner)}${frame}.png`],fi=flag&&img(flag.file);if(!flag||!fi?.complete)return;
  const k=.5*uz,ax=p.x-14*uz,ay=p.y-43*uz;
  ctx.drawImage(pi,ax-pole.refx*k,ay-pole.refy*k,pole.w*k,pole.h*k);
  ctx.drawImage(fi,ax,ay,flag.w*k,flag.h*k);
}
function drawUnit(u){
  const p=unitScreenPoint(u),z=battleState.camera.zoom;
  /* Native <0.5 tactical Object presentation is replaced by the later
     strategic-marker pass, which itself occurs after the effect manager. */
  if(z<CAMERA_DETAIL_ZOOM)return;
  const uz=unitVisualZoom(z),embarked=!!u.embarked&&!isSeaUnit(u),transport=embarked?nativeTransportProfile(u):null,m=embarked?SPRITES[transport.key]:unitVisual(u),im=embarked?(m&&img(m.file)):unitImage(u);

  /* Native visual order proven against original battlefield footage:
     flag/pole behind formation -> unit model -> relation+HP+class marker at feet
     -> commander bubble -> morale marker. */
  drawNativeUnitFlag(u,p,uz);

  const nativeSpec=!embarked?(nativeFrameDrawSpec(u,p,uz)||nativeReadyFrameDrawSpec(u,p,uz)):null;
  if(nativeSpec?.kind==='compact'){nativeSpec.bile.drawFrame(ctx,nativeSpec.itemIndex,nativeSpec.frameIndex,nativeSpec.atlas,nativeSpec.x,nativeSpec.y,nativeSpec.scale,1)}
  else if(im?.complete&&m){if(embarked)drawNativeTransportShip(u,m,im,p,uz,transport.naturalFacing);else{const rr=staticNativePoseRect(u,m,p,uz);ctx.drawImage(im,rr.x,rr.y,rr.w,rr.h)}}
  else{ctx.fillStyle=countryColor(u.owner,.9);ctx.beginPath();ctx.arc(p.x,p.y,11*uz,0,Math.PI*2);ctx.fill()}

  drawNativeTacticalStatus(u,p,uz);

  if(u.commander_id){const cc=COMMANDERS?.[String(u.commander_id)],cm=cc?SPRITES?.[`${cc.name}.png`]:null,ci=cm&&img(cm.file),bm=SPRITES?.['board_smallgenerals.png'],bi=bm&&img(bm.file);if(ci?.complete&&bi?.complete){const k=.5*uz,bx=p.x-bm.refx*k,by=p.y-bm.refy*k;ctx.drawImage(bi,bx,by,bm.w*k,bm.h*k);const px=bx+7*k,py=by+7*k;ctx.drawImage(ci,px,py,cm.w*k,cm.h*k)}}

  const mor=moraleState(u);if(mor!==0){const mk=mor>0?'morale_up.png':mor<=-3?'morale_down3.png':mor<=-2?'morale_down2.png':'morale_down1.png',mm=SPRITES[mk],mi=mm&&img(mm.file);if(mi?.complete){const hh=14*uz,ww=hh*(mm.w/mm.h);ctx.drawImage(mi,p.x+9*uz,p.y-31*uz,ww,hh)}}
}

/* ---------- Battle rules checkpoint ---------- */
function neighbors(q,r){return EW4NativeHex.neighbors(q,r)}
function oddrCube(q,r){return EW4NativeHex.oddrCube(q,r)}
function hexDist(a,b){return EW4NativeHex.distance(a,b)}
function isSeaUnit(u){return['Privateer','Frigate','Battleship','Ironclad'].includes(u.army_name)}
function isFort(u){return u.army_id>=18&&['Small Fortress','Fortress','Large Fortress','Coastal Fort'].includes(u.army_name)}
function isCavalryUnit(u){return !!u&&armyStat(u).type==='cavalry'}
function grantCavalryExtraAction(attacker,defender){
  /* Native tutorial rule: cavalry may act again after annihilating an enemy.
     Do not gate this behind player buffs; it is a base EW4 rule for both sides. */
  if(!attacker||attacker.dead||!defender?.dead||!isCavalryUnit(attacker))return false;
  attacker.moved=false;attacker.attacked=false;
  spawnBattleFloat(attacker.q,attacker.r,'再动','#ffe17a');
  if(isMine(attacker))battleState.reachable=computeReachable(attacker);
  return true;
}
function passable(u,q,r){const h=battleState.battle.header;if(q<h.origin_x||r<h.origin_y||q>=h.origin_x+h.width||r>=h.origin_y+h.height)return false;const t=terrainCell(q,r);if(!t)return false;const sea=t.type==='sea';if(isSeaUnit(u)){if(!sea)return false}else if(sea&&!u.embarked)return false;return !battleState.units.some(x=>!x.dead&&x!==u&&x.q===q&&x.r===r)}
function moveCost(u,q,r){const t=terrainCell(q,r),type=t?.type||'land',st=armyStat(u),c=effectiveCommanderForUnit(u);if(type==='sea')return isSeaUnit(u)?(WORLDS.terrain_types[type]?.movementcost||1):3;/* APK tutorial: Light Infantry retains full mobility in complex terrain. Geography/equipment grants terrain-ignore to other land troops. */if(u.army_name==='Light Infantry'||EW4Combat.hasSkill(c,1)||hasEquipmentFunction(u,0))return 3;return WORLDS.terrain_types[type]?.movementcost||3}
function computeReachable(u){const result=new Map(),stat=armyStat(u);if(isFort(u)||u.moved)return result;const max=effectiveMovePoints(u),queue=[[u.q,u.r,0]];result.set(`${u.q},${u.r}`,0);while(queue.length){const[q,r,cost]=queue.shift();for(const[nq,nr]of neighbors(q,r)){if(!passable(u,nq,nr))continue;const nc=cost+moveCost(u,nq,nr);if(nc>max)continue;const k=`${nq},${nr}`;if(result.has(k)&&result.get(k)<=nc)continue;result.set(k,nc);queue.push([nq,nr,nc])}}result.delete(`${u.q},${u.r}`);return result}
function movementPath(u,tq,tr){
  const start=`${u.q},${u.r}`,goal=`${tq},${tr}`,max=effectiveMovePoints(u),costs=new Map([[start,0]]),prev=new Map();let routeSerial=0;const queue=[[u.q,u.r,0,routeSerial++]];
  while(queue.length){queue.sort((a,b)=>a[2]-b[2]||a[3]-b[3]);const[q,r,cost]=queue.shift(),key=`${q},${r}`;if(cost!==costs.get(key))continue;if(key===goal)break;
    for(const[nq,nr]of neighbors(q,r)){if(!passable(u,nq,nr))continue;const nc=cost+moveCost(u,nq,nr);if(nc>max)continue;const nk=`${nq},${nr}`;if(costs.has(nk)&&costs.get(nk)<=nc)continue;costs.set(nk,nc);prev.set(nk,key);queue.push([nq,nr,nc,routeSerial++])}
  }
  if(!costs.has(goal))return[{q:u.q,r:u.r},{q:tq,r:tr}];const rev=[];let k=goal;while(k){const[q,r]=k.split(',').map(Number);rev.push({q,r});if(k===start)break;k=prev.get(k)}return rev.reverse();
}
function canRange(a,b,ignoreAction=false){if(!a||!b||a.dead||b.dead||!isHostilePair(a,b))return false;const st=armyStat(a),d=hexDist(a,b);return d>=+st.minatkrange&&d<=+st.maxatkrange&&(ignoreAction||!a.attacked)}
function isHostilePair(a,b){return !!a&&!!b&&relationBetweenOwners(a.owner,b.owner)==='hostile'}
function inAttackRange(a,b){return canRange(a,b,false)}
function itemTargetMatches(item,st){const t=item?.target;return t==='all'||t===st.type||(t==='navy'&&st.type==='warship')}
function equippedItemIds(u){const c=u.commander_id?COMMANDERS[String(u.commander_id)]:null;if(!c)return[];return equipmentSlotsForCommander(c).filter(id=>id!=null)}
function hasEquipmentFunction(u,fn){return equippedItemIds(u).some(id=>+ITEMS?.[String(id)]?.function===+fn)}
function equipmentFunctionValue(u,fn){let n=0;for(const id of equippedItemIds(u)){const it=ITEMS?.[String(id)];if(it&&+it.function===+fn)n+=+it.value||0}return n}
function friendlyAuraSource(src,target){if(!src||!target||src.dead||target.dead)return false;if(src===target)return false;if(hexDist(src,target)!==1)return false;return relationBetweenOwners(src.owner,target.owner)==='ally'}
function auraValueAround(u,fn){let n=0;for(const src of battleState?.units||[]){if(!friendlyAuraSource(src,u))continue;n+=equipmentFunctionValue(src,fn)}return n}
function combatUnit(u){return hasEquipmentFunction(u,4)?{...u,forceFullFormation:true}:u}
function attackModifiers(u){const st=armyStat(u);let fixed=(+u.attackBonus||0)+auraValueAround(u,14),lower=+u.attackMinBonus||0,upper=+u.attackMaxBonus||0;for(const id of equippedItemIds(u)){const it=ITEMS?.[String(id)];if(!it||!itemTargetMatches(it,st))continue;if(+it.function===11){/* Native EW4 weapon equipment is a fixed damage contribution, not a per-die panel interval increase. */fixed+=+it.value||0}}return{fixed,lower,upper}}
function attackInterval(u){const st=armyStat(u),m=attackModifiers(u),cmd=effectiveCommanderForUnit(u),sb=EW4Combat.skillIntervalBonus(cmd,st.type);return EW4Combat.effectiveAttackInterval({min:st.minatk,max:st.maxatk,isPlayer:isMine(u),lowerBonus:m.lower+sb.lower,upperBonus:m.upper+sb.upper})}
function damageProfile(u){const st=armyStat(u),cmd=effectiveCommanderForUnit(u),m=attackModifiers(u);return EW4Combat.damageBounds({unit:combatUnit(u),stat:st,commander:cmd,isPlayer:isMine(u),isFort:isFort(u),fixedBonus:m.fixed,lowerBonus:m.lower,upperBonus:m.upper})}
function hideNativeActionResource(){
  const p=document.getElementById('native-action-resource');if(!p)return;p.classList.remove('show');p.setAttribute('aria-hidden','true');p._confirmAction=null
}
function positionNativeActionResource(panel,anchor){
  const screen=document.getElementById('battle');if(!panel||!anchor||!screen)return;
  const sr=screen.getBoundingClientRect(),ar=anchor.getBoundingClientRect(),sx=sr.width/Math.max(1,screen.offsetWidth||568),sy=sr.height/Math.max(1,screen.offsetHeight||320);
  const cx=(ar.left-sr.left+ar.width/2)/Math.max(.001,sx),top=(ar.top-sr.top)/Math.max(.001,sy);
  panel.style.left=`${Math.max(0,Math.min(484,Math.round(cx-42)))}px`;panel.style.top=`${Math.max(0,Math.round(top-88))}px`
}
function openNativeActionResource(anchor,{money=0,secondary=0,secondaryKind='industry',onConfirm=null}={}){
  const p=document.getElementById('native-action-resource'),m=document.getElementById('native-funcres-money'),sv=document.getElementById('native-funcres-secondary'),si=document.getElementById('native-funcres-secondary-icon'),ok=document.getElementById('native-funcres-confirm');if(!p||!m||!sv||!si||!ok)return;bindTutorialUI(ok,'btn_done');
  const secondaryResource=secondaryKind==='food'?'food':'industry',secondaryIcon=secondaryKind==='food'?'marker_food.png':'marker_industry.png';
  m.textContent=String(Math.max(0,+money||0));sv.textContent=String(Math.max(0,+secondary||0));si.src=`assets/sprites/image_ui_hd/${secondaryIcon}`;
  const haveMoney=+battleState?.resources?.money||0,haveSecondary=+battleState?.resources?.[secondaryResource]||0,affordable=haveMoney>=(+money||0)&&haveSecondary>=(+secondary||0);
  m.classList.toggle('insufficient',haveMoney<(+money||0));sv.classList.toggle('insufficient',haveSecondary<(+secondary||0));ok.disabled=!affordable;ok.classList.toggle('gray',!affordable);
  p._confirmAction=affordable&&typeof onConfirm==='function'?onConfirm:null;ok.onclick=e=>{e.stopPropagation();const fn=p._confirmAction;if(!fn)return;hideNativeActionResource();fn()};
  positionNativeActionResource(p,anchor);p.classList.add('show');p.setAttribute('aria-hidden','false');requestAnimationFrame(positionNativeTutorialHighlight)
}
function hideUseItemPanel(){
  const p=document.getElementById('useitem-panel');if(!p)return;p.classList.remove('show');p.setAttribute('aria-hidden','true');p._unit=null;p._selectedId=null
}
function isUnlimitedBattleConsumable(id){return MODS.battleConsumables===Infinity&&EW4NativeUseItem.USE_ITEM_IDS.includes(+id)}
function useItemCount(id){const n=EW4ItemInventory.count(saveState.itemInventory,+id);return isUnlimitedBattleConsumable(id)?Math.max(1,n):n}
function renderUseItemPanel(){
  const p=document.getElementById('useitem-panel'),list=document.getElementById('useitem-list'),title=document.getElementById('useitem-desc-title'),desc=document.getElementById('useitem-desc-text'),ok=document.getElementById('useitem-confirm');
  const u=p?._unit;if(!p||!list||!title||!desc||!ok||!u||u.dead){hideUseItemPanel();return}
  const ids=EW4NativeUseItem.USE_ITEM_IDS,selected=ids.includes(+p._selectedId)?+p._selectedId:ids[0];p._selectedId=selected;list.innerHTML='';
  for(const id of ids){
    const it=ITEMS?.[String(id)],count=useItemCount(id),b=document.createElement('button');b.className='useitem-slot'+(+id===selected?' sel':'')+(count<=0?' empty':'');b.dataset.itemId=String(id);bindTutorialUI(b,'lbox_item',ids.indexOf(id));b.title=itemName(it);b.setAttribute('aria-label',`${itemName(it)} ×${count}`);
    const icon=itemIcon(it);b.innerHTML=`${icon?`<img src="${icon}" alt="">`:''}<span class="useitem-count">${count}</span>`;
    b.onclick=e=>{e.stopPropagation();p._selectedId=+id;renderUseItemPanel()};list.appendChild(b)
  }
  const it=ITEMS?.[String(selected)],count=useItemCount(selected),can=!!it&&count>0&&EW4NativeUseItem.canUse(it,u,moraleState(u));title.textContent=itemName(it);desc.textContent=itemDesc(it)||itemName(it);ok.disabled=!can;
  ok.onclick=e=>{e.stopPropagation();confirmBattleUseItem()};requestAnimationFrame(positionNativeTutorialHighlight)
}
function openBattleUseItem(u){
  if(!battleState||!u||u.dead||!isMine(u))return;const p=document.getElementById('useitem-panel');if(!p)return;
  document.getElementById('unit-card').style.display='none';document.getElementById('facility-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');hideNativeActionResource();
  p.dataset.title=STRINGS?.title_useitem||'物   品';p._unit=u;p._selectedId=EW4NativeUseItem.USE_ITEM_IDS[0];p.classList.add('show');p.setAttribute('aria-hidden','false');bindTutorialUI(document.getElementById('useitem-close'),'winbtn_close');document.getElementById('useitem-close').onclick=e=>{e.stopPropagation();hideUseItemPanel()};renderUseItemPanel();playNativeFormOpenSfx('form_useitem')
}
function confirmBattleUseItem(){
  const p=document.getElementById('useitem-panel'),u=p?._unit,id=+p?._selectedId,it=ITEMS?.[String(id)];if(!battleState||!p||!u||u.dead||!isMine(u)||!it)return;
  const currentMorale=moraleState(u);if(useItemCount(id)<=0||!EW4NativeUseItem.canUse(it,u,currentMorale)){renderUseItemPanel();return}
  const unlimited=isUnlimitedBattleConsumable(id),taken=unlimited?{ok:true,inventory:saveState.itemInventory}:EW4ItemInventory.remove(saveState.itemInventory,id,1,ITEMS);if(!taken.ok){renderUseItemPanel();return}
  const result=EW4NativeUseItem.apply(it,u,{round:battleState.round,currentMorale});if(!result.ok){renderUseItemPanel();return}
  if(!unlimited)saveState.itemInventory=taken.inventory;u.moved=true;u.attacked=true;battleState.reachable=new Map();persist();writeBattleSave('auto',true);playNativeActionSfx('supply');spawnNativeSimpleEffect('effect_recover',u.q,u.r);hideUseItemPanel();renderBattleActions();renderBattle();tutorialNotifyAction();showUnitCard(u)
}
function closeBattlePanels(){
  const u=document.getElementById('unit-card'),f=document.getElementById('facility-card'),m=document.getElementById('battle-action-menu'),c=document.getElementById('commerce-panel');
  if(u)u.style.display='none';if(f)f.style.display='none';if(m){m.classList.remove('show');m.innerHTML=''}if(c)c.classList.remove('show');hideNativeActionResource();hideUseItemPanel();hideNativeDefensePanel()
}
function nativeUnitCardRecruitCost(u){const c=CARDS?.[`${u.army_name}|${u.grade}`];return c?{money:+c.price||0,industry:+c.industry||0}:{money:0,industry:0}}
const NATIVE_UNITINFO_ART={
  'Militia':['image_recruit_hd2/recruit_militia.png','image_recruit_hd3/recruitmarker_militia.png'],
  'Line Infantry':['image_recruit_hd2/recruit_line.png','image_recruit_hd2/recruitmarker_line.png'],
  'Light Infantry':['image_recruit_hd/recruit_light.png','image_recruit_hd2/recruitmarker_light.png'],
  'Grenadier':['image_recruit_hd/recruit_grenadier.png','image_recruit_hd2/recruitmarker_grenadier.png'],
  'Guards':['image_recruit_hd/recruit_guard.png','image_recruit_hd2/recruitmarker_guard.png'],
  'Machine Gun':['image_recruit_hd2/recruit_machinegun.png','image_recruit_hd3/recruitmarker_machinegun.png'],
  'Light Cavalry':['image_recruit_hd2/recruit_lightcavalry.png','image_recruit_hd2/recruitmarker_lightcavalry.png'],
  'Heavy Cavalry':['image_recruit_hd/recruit_heavycavalry.png','image_recruit_hd2/recruitmarker_heavycavalry.png'],
  'Guards Cavalry':['image_recruit_hd2/recruit_musketcavalry.png','image_recruit_hd3/recruitmarker_musketcavalry.png'],
  'Armored Car':['image_recruit_hd/recruit_armoredcar.png','image_recruit_hd2/recruitmarker_armoredcar.png'],
  'Light Artillery':['image_recruit_hd2/recruit_lightartillery.png','image_recruit_hd2/recruitmarker_lightartillery.png'],
  'Heavy Artillery':['image_recruit_hd/recruit_heavyartillery.png','image_recruit_hd2/recruitmarker_heavyartillery.png'],
  'Siege Artillery':['image_recruit_hd/recruit_fortressartillery.png','image_recruit_hd2/recruitmarker_fortressartillery.png'],
  'Rocket':['image_recruit_hd2/recruit_rocket.png','image_recruit_hd3/recruitmarker_rocket.png'],
  'Privateer':['image_recruit_hd/recruit_cruiser.png','image_recruit_hd2/recruitmarker_cruiser.png'],
  'Frigate':['image_recruit_hd/recruit_frigate.png','image_recruit_hd2/recruitmarker_frigate.png'],
  'Battleship':['image_recruit_hd/recruit_battleship.png','image_recruit_hd2/recruitmarker_battleship.png'],
  'Ironclad':['image_recruit_hd/recruit_ironclads.png','image_recruit_hd2/recruitmarker_ironclads.png'],
  'Small Fortress':['image_recruit_hd3/build_smallfortress.png','image_recruit_hd2/buildmarker_smallfortress.png'],
  'Fortress':['image_recruit_hd2/build_mediumfortress.png','image_recruit_hd/buildmarker_mediumfortress.png'],
  'Large Fortress':['image_recruit_hd2/build_largefortress.png','image_recruit_hd/buildmarker_largefortress.png'],
  'Coastal Fort':['image_recruit_hd2/build_coastalartillery.png','image_recruit_hd/buildmarker_coastalartillery.png']
};
function nativeUnitInfoArt(u){const x=NATIVE_UNITINFO_ART[u?.army_name]||NATIVE_UNITINFO_ART.Militia;return{unit:`assets/sprites/${x[0]}`,marker:`assets/sprites/${x[1]}`}}
function nativeUnitAbilityCells(u,st,atk){
  const soldierCount=Math.max(1,Math.min(3,(+u.grade||0)+1));
  return [
    {kind:'icon',src:'assets/sprites/image_ui_hd/infomarker_attack.png',title:'攻击'},
    {kind:'text',value:`${atk.min}-${atk.max}`,title:'攻击'},
    {kind:'icon',src:'assets/sprites/image_ui_hd/button_upgrade_line.png',title:'编制'},
    {kind:'formation',count:soldierCount,title:'编制'},
    {kind:'icon',src:'assets/sprites/image_ui_hd/infomarker_hp.png',title:'生命'},
    {kind:'text',value:`${Math.max(0,Math.round(u.hp))}/${Math.max(1,Math.round(u.max_hp))}`,title:'生命'},
    {kind:'icon',src:'assets/sprites/image_ui_hd/infomarker_food.png',title:'粮食'},
    {kind:'text',value:String(+st.consumption||0),title:'粮食'},
    {kind:'icon',src:'assets/sprites/image_ui_hd/infomarker_range.png',title:'射程'},
    {kind:'text',value:`${+st.minatkrange||0}-${+st.maxatkrange||0}`,title:'射程'},
    {kind:'icon',src:'assets/sprites/image_ui_hd/infomarker_move.png',title:'移动'},
    {kind:'text',value:String(effectiveMovePoints(u)),title:'移动'}
  ]
}
function nativeUnitAbilityHTML(c){
  if(c.kind==='icon')return `<div class="unitinfo-ability unitinfo-ability-icon" title="${c.title}"><img src="${c.src}" alt=""></div>`;
  if(c.kind==='formation')return `<div class="unitinfo-ability unitinfo-formation" title="${c.title}">${Array.from({length:c.count},(_,i)=>`<img src="assets/sprites/image_ui_hd/infomarker_soldiernumber.png" alt="" style="--soldier-index:${i}">`).join('')}</div>`;
  return `<div class="unitinfo-ability unitinfo-ability-text" title="${c.title}"><span>${c.value}</span></div>`
}
function showUnitCard(u){
  const el=document.getElementById('unit-card');document.getElementById('facility-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');
  if(!u){el.style.display='none';el.className='';return}
  const st=armyStat(u),cmd=effectiveCommanderForUnit(u),atk=attackInterval(u),cost=nativeUnitCardRecruitCost(u),art=nativeUnitInfoArt(u),formationCount=Math.max(1,Math.min(3,(+u.grade||0)+1));
  const abilities=nativeUnitAbilityCells(u,st,atk).map(nativeUnitAbilityHTML).join('');
  const formationLayers=Array.from({length:formationCount},(_,i)=>`<span class="unitinfo-form-layer" style="--layer:${i}"><img class="unitinfo-form-back" src="assets/sprites/image_recruit_hd/buildmaker.png" alt=""><img class="unitinfo-form-icon" src="${art.marker}" alt=""></span>`).join('');
  el.className='native-user-window native-unitinfo show';el.dataset.title=STRINGS?.title_unitinfo||'信  息';
  el.innerHTML=`<button class="native-close unitinfo-close" aria-label="关闭"></button><div class="unitinfo-unit"><img class="unitinfo-recruit" src="${art.unit}" alt=""><div class="unitinfo-buildframe"></div>${formationLayers}<div class="unitinfo-cost money"><img src="assets/sprites/image_ui_hd/marker_money.png" alt=""><span>${cost.money}</span></div><div class="unitinfo-cost industry"><img src="assets/sprites/image_ui_hd/marker_industry.png" alt=""><span>${cost.industry}</span></div></div><div class="unitinfo-ability-grid">${abilities}</div><div class="unitinfo-commander">${cmd?`<img class="unitinfo-commander-portrait" src="${portrait(cmd.id)}" alt=""><b>${commanderName(cmd)}</b><button class="unitinfo-generalinfo" aria-label="将领信息"></button>`:'<span class="unitinfo-no-general">无将领</span>'}</div><div class="unitinfo-desc"><b class="unitinfo-desc-title"></b><div class="unitinfo-desc-text"></div></div>`;
  el.querySelector('.unitinfo-desc-title').textContent=armyName(u.army_name);el.querySelector('.unitinfo-desc-text').textContent=STRINGS?.[`desc_${u.army_name}`]||'';
  el.querySelector('.unitinfo-close').onclick=e=>{e.stopPropagation();el.style.display='none';el.classList.remove('show')};
  const gb=el.querySelector('.unitinfo-generalinfo');if(gb)gb.onclick=e=>{e.stopPropagation();showBattleCommanderInfo(u)};
  el.style.display='block';playNativeFormOpenSfx('form_unitinfo')
}
function showBattleCommanderInfo(u){
  if(!u?.commander_id)return;const c=effectiveCommanderForUnit(u);if(!c)return;closeBattlePanels();openHQCommander(c)
}
function battleActionTutorialAlias(asset){
  const map={button_items:'btn_item',button_buyship:'btn_ship',button_builddefense:'btn_defense',button_buildfortress:'btn_fortress',button_training:'btn_training',button_generals:'btn_general',button_buildupgrade:'btn_upgrade',button_trade:'btn_trading',button_factory:'btn_factory',button_stable:'btn_stable',button_dock:'btn_port'};
  if(asset==='button_city')return'btn_city'
  return map[asset]||null
}
function addBattleAction(asset,title,handler,disabled=false,folder='image_recruit_hd'){
  const root=document.getElementById('battle-actions'),b=document.createElement('button');b.className='battle-action-btn';b.style.backgroundImage=`url('assets/sprites/${folder}/${asset}.png')`;b.title=title;b.setAttribute('aria-label',title);b.disabled=disabled;const alias=battleActionTutorialAlias(asset);if(alias)bindTutorialUI(b,alias);b.onclick=e=>{e.stopPropagation();hideNativeActionResource();handler(b,e)};root.appendChild(b);return b
}
function commerceCommanderAt(o){
  const u=o?unitAt(o.q,o.r):null;return u&&!u.dead&&u.owner===o.owner&&u.commander_id?effectiveCommanderForUnit(u):null
}
function facilityBusinessStars(o){return EW4Commerce.businessStars(commerceCommanderAt(o)?.business||0)}
function marketResourceLabel(key){return key==='money'?'金币':key==='industry'?'工业':'粮食'}
function marketResourceIcon(key){return `assets/sprites/image_ui_hd/${key==='money'?'marker_money.png':key==='industry'?'marker_industry.png':'marker_food.png'}`}
function executeMarketQuote(o,quote){
  if(!o||o.owner!==battleState?.playerOwner||!quote)return;
  if(!EW4Commerce.applyQuote(battleState.resources,quote)){flash(`${marketResourceLabel(quote.payResource)}不足`);return}
  updateResources();openMarketPanel(o);playSfx('select');flash(`${marketResourceLabel(quote.payResource)} -${quote.pay}　${marketResourceLabel(quote.receiveResource)} +${quote.receive}`)
}
function initialBattleItemStores(file){
  const raw=BATTLE_ITEMSTORES?.battles?.[file]||{},out={};
  for(const [storeId,store] of Object.entries(raw))out[String(storeId)]={...store,slots:(store.slots||[]).map(x=>x?{item:+x.item,count:+x.count||1,active:true}:null)};
  return out
}
function battleItemStoreForObject(o){return o&&battleState?.itemStores?.[String(+o.pos)]||null}
function initialBattleTaverns(file){
  const raw=BATTLE_TAVERNS?.battles?.[file]||{},out={};
  for(const [id,t] of Object.entries(raw))out[String(id)]={object_index:+t.object_index,file_offset:+t.file_offset,count:Math.max(0,+t.count||0),slots:(t.slots||[]).slice(0,5).map(x=>x?{commander:+x.commander,money:+x.money||0,industry:+x.industry||0,medal:+x.medal||0,round:+x.round||0}:null)};
  return out
}
function battleTavernForObject(o){return o&&battleState?.taverns?.[String(+o.pos)]||null}
function tavernCandidateAvailable(slot){return !!(slot&&COMMANDERS?.[String(slot.commander)]&&!owns(slot.commander)&&battleState&&battleState.round>=Math.max(0,+slot.round||0)&&battleState.resources.money>=(+slot.money||0)&&battleState.resources.industry>=(+slot.industry||0))}
function recruitTavernCandidate(o,index){
  const tavern=battleTavernForObject(o),i=+index;if(!tavern||i<0||i>=Math.min(4,tavern.count||0))return;
  const slot=tavern.slots?.[i],c=slot&&COMMANDERS?.[String(slot.commander)];if(!slot||!c)return;
  if(owns(slot.commander)){flash('该将领已经在指挥部');return}
  if(battleState.round<Math.max(0,+slot.round||0)){flash(`回合 ${slot.round} 后可招募`);return}
  if(battleState.resources.money<(+slot.money||0)||battleState.resources.industry<(+slot.industry||0)){flash('资源不足，无法招募');return}
  battleState.resources.money-=+slot.money||0;battleState.resources.industry-=+slot.industry||0;
  // This build intentionally keeps medals infinite. Native medal cost is shown but not deducted.
  acquire(slot.commander);
  for(let k=i;k<4;k++)tavern.slots[k]=tavern.slots[k+1]||null;
  tavern.slots[4]=null;tavern.count=Math.max(0,(+tavern.count||0)-1);
  updateResources();writeBattleSave('auto',true);playSfx('select');openTavernPanel(o);flash(`${commanderName(c)} 已加入指挥部`)
}
function openTavernPanel(o){
  if(!battleState||!o||o.owner!==battleState.playerOwner||specialFacilityType(o)!=='bar')return;
  document.getElementById('unit-card').style.display='none';document.getElementById('facility-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');
  const panel=document.getElementById('commerce-panel'),body=document.getElementById('commerce-body'),tavern=battleTavernForObject(o);panel.dataset.mode='tavern';document.getElementById('commerce-title').textContent='酒　馆';
  if(!tavern){body.innerHTML='';panel.classList.add('show');return}
  body.innerHTML='<div class="tavern-grid native-tavern" data-tavern-grid></div>';
  const grid=body.querySelector('[data-tavern-grid]'),visible=Math.min(4,Math.max(0,+tavern.count||0));
  for(let i=0;i<4;i++){
    const slot=i<visible?tavern.slots?.[i]:null,c=slot&&COMMANDERS?.[String(slot.commander)],b=document.createElement('button');b.className='tavern-candidate';
    if(!slot||!c){b.disabled=true;b.innerHTML='<span style="position:absolute;left:0;right:0;top:18px;text-align:center;opacity:.35">—</span>';grid.appendChild(b);continue}
    const pic=portrait(c.id),roundLocked=battleState.round<Math.max(0,+slot.round||0),owned=owns(c.id),moneyLocked=battleState.resources.money<(+slot.money||0)||battleState.resources.industry<(+slot.industry||0);b.disabled=roundLocked||owned||moneyLocked;
    const state=roundLocked?`回合${slot.round}`:owned?'已拥有':moneyLocked?'资源不足':'招募';
    b.innerHTML=`${pic?`<img src="${pic}">`:''}<b>${commanderName(c)}</b><small>${stars(c.star)}<br>🏅 ${slot.medal}　💰 ${slot.money}<br>⚙️ ${slot.industry}${roundLocked?`　回合≥${slot.round}`:''}</small><span class="tavern-recruit-label">${state}</span>`;
    b.onclick=e=>{e.stopPropagation();recruitTavernCandidate(o,i)};grid.appendChild(b)
  }
  panel.classList.add('show')
}

function hqShopState(){
  saveState.hqShop=EW4SceneShop.ensureHQStore(saveState.hqShop,{items:ITEMS,inventory:saveState.itemInventory,equipment:saveState.equipment});persist();return saveState.hqShop
}
function battleShopContext(o){
  if(!battleState||!o||o.owner!==battleState.playerOwner||specialFacilityType(o)!=='shop')return null;
  const store=battleItemStoreForObject(o);if(!store)return null;
  return{kind:'battle',hq:false,business:facilityBusinessStars(o),store,buyer:shopBuyerCommander(o),object:o}
}
function hqShopContext(){return{kind:'hq',hq:true,business:0,store:hqShopState(),buyer:null,object:null}}
function shopItemBuyPrice(item,ctx){return EW4SceneShop.buyPrice(item,ctx?.business||0,ctx?.hq===true)}
function shopItemSellPrice(item,ctx){return EW4SceneShop.sellPrice(item,ctx?.business||0,ctx?.hq===true)}
function persistSceneShop(ctx,slots){
  if(!ctx)return;
  if(ctx.kind==='hq'){saveState.hqShop={...saveState.hqShop,slots};persist();ctx.store=saveState.hqShop}
  else if(ctx.kind==='battle'){ctx.store.slots=slots;writeBattleSave('auto',true)}
}
function buySceneShopSlot(ctx,slotIndex){
  const slot=ctx?.store?.slots?.[slotIndex],item=slot&&ITEMS?.[String(slot.item)];if(!ctx||!slot||!item)return;
  const price=shopItemBuyPrice(item,ctx),r=EW4SceneShop.buy({store:ctx.store,index:slotIndex,inventory:saveState.itemInventory,items:ITEMS});
  if(!r.ok){flash(r.reason==='full'?'物品栏已满':'无法购入该物品');return}
  saveState.itemInventory=r.inventory;persistSceneShop(ctx,r.slots);persist();playSfx('select');renderSceneShop(ctx);flash(`${itemName(item)} 已购入　🏅 ${price}`)
}
function sellSceneShopBankSlot(ctx,slotIndex){
  const bank=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS),slot=bank.slots?.[slotIndex],item=slot&&ITEMS?.[String(slot.item)];if(!ctx||!slot||slot.item<0||!item)return;
  const price=shopItemSellPrice(item,ctx),r=EW4SceneShop.sell({inventory:bank,slotIndex,items:ITEMS});if(!r.ok)return;
  saveState.itemInventory=r.inventory;persist();if(ctx.kind==='battle')writeBattleSave('auto',true);playSfx('select');renderSceneShop(ctx);flash(`${itemName(item)} 已出售　🏅 ${price}`)
}
function shopBuyerCommander(o){const u=o?unitAt(o.q,o.r):null;return u?.commander_id?effectiveCommanderForUnit(u):null}
function renderSceneShop(ctx){
  if(!ctx)return;activeShopContext=ctx;
  const panel=document.getElementById('commerce-panel'),body=document.getElementById('commerce-body'),buyer=ctx.buyer;
  panel.dataset.mode='shop';panel.dataset.shopContext=ctx.kind;document.getElementById('commerce-title').textContent='商　店';
  const rateText=ctx.hq?'总　部':`商业 ${ctx.business}/5`;
  body.innerHTML=`<div class="shop-merchant"><div class="portrait"></div><div class="name">商人</div></div><div class="shop-seller-grid" data-shop-seller></div><div class="commerce-rate">${rateText}</div><div class="shop-buyer-grid" data-shop-buyer></div><div class="shop-buyer">${buyer?`<img class="portrait" src="${portrait(buyer.id)}"><div class="name">${commanderName(buyer)}</div>`:'<div class="portrait"></div><div class="name">物品栏</div>'}</div>`;
  const seller=body.querySelector('[data-shop-seller]'),buyerGrid=body.querySelector('[data-shop-buyer]'),slots=EW4SceneShop.normalizeSeller(ctx.store?.slots);
  ctx.store.slots=slots;
  for(let i=0;i<EW4SceneShop.SELLER_SIZE;i++){
    const slot=slots[i],b=document.createElement('button');b.className='shop-slot';
    if(!slot||slot.active===false||slot.count<=0){b.classList.add('empty');b.disabled=true;b.innerHTML='<span>—</span>';seller.appendChild(b);continue}
    const it=ITEMS?.[String(slot.item)],icon=itemIcon(it),price=shopItemBuyPrice(it,ctx);b.disabled=!it;b.innerHTML=`${icon?`<img src="${icon}">`:''}<b>${it?itemName(it):`#${slot.item}`}</b><small>🏅 ${price}</small>`;b.title=it?(itemDesc(it)||itemName(it)):`Item ${slot.item}`;b.onclick=e=>{e.stopPropagation();buySceneShopSlot(ctx,i)};seller.appendChild(b)
  }
  const bank=EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS);
  for(let i=0;i<EW4ItemInventory.BANK_SIZE;i++){
    const slot=bank.slots[i],b=document.createElement('button');b.className='shop-slot';
    if(!slot||slot.item<0||slot.count<=0){b.classList.add('empty');b.disabled=true;b.innerHTML='<span>—</span>'}
    else{const it=ITEMS?.[String(slot.item)],icon=itemIcon(it),price=shopItemSellPrice(it,ctx);b.disabled=!it;b.innerHTML=`${icon?`<img src="${icon}">`:''}<b>${it?itemName(it):`#${slot.item}`}</b><small>×${slot.count}　🏅${price}</small>`;b.title=it?`${itemDesc(it)||itemName(it)} · 出售 ${price}`:`Item ${slot.item}`;b.onclick=e=>{e.stopPropagation();sellSceneShopBankSlot(ctx,i)}}buyerGrid.appendChild(b)
  }
  panel.classList.add('show')
}
function openShopPanel(o){
  const ctx=battleShopContext(o);if(!ctx)return;
  document.getElementById('unit-card').style.display='none';document.getElementById('facility-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');renderSceneShop(ctx)
}
function openHeadquartersShop(){if(deploymentContext!=='hq')return;if(!ITEMS){loadDB().then(openHeadquartersShop);return}renderSceneShop(hqShopContext())}


function openMarketPanel(o){
  if(!battleState||!o||o.owner!==battleState.playerOwner||specialFacilityType(o)!=='trade')return;
  document.getElementById('unit-card').style.display='none';document.getElementById('facility-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');
  const panel=document.getElementById('commerce-panel'),body=document.getElementById('commerce-body'),business=facilityBusinessStars(o),rate=EW4Commerce.tradeRate(business),pc=commerceCommanderAt(o);
  panel.dataset.mode='market';document.getElementById('commerce-title').textContent='贸　易';body.innerHTML=`<div class="exchange-buy-row" data-market-buy></div><div class="exchange-info"><div class="exchange-player">${pc?`<img src="${portrait(pc.id)}"><span>${commanderName(pc)}</span>`:'<span>驻城指挥官</span>'}</div><b>商业 ${business}/5</b><span>×${rate.toFixed(1)}</span></div><div class="exchange-sell-row" data-market-sell></div>`;
  const makeChoice=(q,alias)=>{const b=document.createElement('button');b.className='exchange-choice';if(alias)bindTutorialUI(b,alias);b.disabled=!EW4Commerce.canApplyQuote(battleState.resources,q);b.innerHTML=`<div class="exchange-line"><img src="${marketResourceIcon(q.payResource)}"><span>${marketResourceLabel(q.payResource)}</span><b>${q.pay}</b></div><div class="exchange-arrow">↓</div><div class="exchange-line"><img src="${marketResourceIcon(q.receiveResource)}"><span>${marketResourceLabel(q.receiveResource)}</span><b>${q.receive}</b></div>`;b.onclick=e=>{e.stopPropagation();executeMarketQuote(o,q)};return b};
  const buy=body.querySelector('[data-market-buy]'),sell=body.querySelector('[data-market-sell]');
  const buyAliases=['btn_buy_1','btn_buy_2','btn_buy_3','btn_buy_4'],sellAliases=['btn_sell_1','btn_sell_2','btn_sell_3','btn_sell_4'];
  for(let i=0;i<4;i++)buy.appendChild(makeChoice(EW4Commerce.marketBuyQuote(i,business),buyAliases[i]));
  for(let i=0;i<4;i++)sell.appendChild(makeChoice(EW4Commerce.marketSellQuote(i,business),sellAliases[i]));
  panel.classList.add('show');playNativeFormOpenSfx('form_exchange');requestAnimationFrame(positionNativeTutorialHighlight)
}

function renderBattleActions(){
  const root=document.getElementById('battle-actions');if(!root)return;root.innerHTML='';root.classList.remove('show');syncBattleUndoButton();
  const S=battleState;if(!S||S.ended||S.phase==='ai'||S.cameraPresentationPending)return;
  const u=S.selected,o=S.selectedObject,cell=S.selectedCell;
  if(u&&!u.dead){
    if(isMine(u))addBattleAction('button_items','物品',()=>openBattleUseItem(u),!!u.attacked,'image_recruit_hd3');
    if(isMine(u)&&canEmbark(u))addBattleAction('button_buyship','运输船',(button)=>promptEmbarkUnit(u,button));
    if(isMine(u)&&!isSeaUnit(u)&&!isFort(u)&&armyStat(u).type==='infantry'&&terrainCell(u.q,u.r)?.type!=='sea'&&!installationAt(u.q,u.r))addBattleAction('button_builddefense','修筑工事',()=>showBuildMenu(u),!!u.attacked);
    if(isMine(u)&&u.commander_id){const tc=effectiveCommanderForUnit(u),eligible=EW4NativeTraining.canManualTrain(u,tc);addBattleAction('button_training','训练',(button)=>promptManualTrainUnit(u,button),!eligible,'image_recruit_hd3')}
    if(isMine(u))addBattleAction('button_generals','部署将领',()=>openGeneralDeploymentForUnit(u),false,'image_ui_hd');
    if(u.commander_id)addBattleAction('button_generalinfo','将领信息',()=>showBattleCommanderInfo(u),false,'image_ui_hd');
    addBattleAction('button_info','部队信息',()=>showUnitCard(u));
  }else if(o){
    const lv=constructionLevel(o),mine=o.owner===S.playerOwner,special=specialFacilityType(o);
    if(mine&&special==='trade')addBattleAction('button_trade','市场',()=>openMarketPanel(o),false,'image_recruit_hd2');
    if(mine&&special==='shop')addBattleAction('button_shop','商店',()=>openShopPanel(o));
    if(mine&&special==='bar')addBattleAction('button_bar','酒馆',()=>openTavernPanel(o),false,'image_recruit_hd2');
    if(mine&&canUpgradeConstruction(o))addBattleAction('button_buildupgrade','升级建筑',(button)=>promptUpgradeConstruction(o,button));
    if(mine&&lv?.recruit?.length){const recruitAction=o.construction_type==='industry'?['button_factory','image_recruit_hd3']:o.construction_type==='stable'?['button_stable','image_recruit_hd3']:o.construction_type==='port'?['button_dock','image_recruit_hd3']:['button_city','image_recruit_hd'];addBattleAction(recruitAction[0],'征募部队',()=>showFacilityCard(o),false,recruitAction[1])}
    addBattleAction('button_info','设施信息',()=>showFacilityCard(o));
  }else if(cell&&ownerAt(cell.q,cell.r)===S.playerOwner&&terrainCell(cell.q,cell.r)?.type!=='sea'&&!unitAt(cell.q,cell.r)&&!objectAt(cell.q,cell.r)){
    addBattleAction('button_buildfortress','建造要塞',()=>openNativeDefensePanel({kind:'fortress',cell}));
  }
  syncBattleUndoButton();if(root.childElementCount)root.classList.add('show')
}
function hideNativeDefensePanel(){const p=document.getElementById('defense-panel');if(!p)return;p.classList.remove('show');p.setAttribute('aria-hidden','true');p._context=null;p._selected=0}
function nativeDefenseChoices(ctx){
  if(ctx.kind==='installation')return [['trench','Trench'],['fence','Fence'],['bunker','Bunker']].map(([type,name])=>{const card=BUILD_CARDS?.[name],img=INSTALLATIONS?.[type]?.image||'';return{type,label:armyName(name),card,cost:buildCostForInstallation(type,ctx.u?effectiveCommanderForUnit(ctx.u):null),imagePath:img?`assets/sprites/image_ui_hd/${img}`:'',desc:STRINGS?.[`desc_${name}`]||''}});
  const names=['Small Fortress','Fortress','Large Fortress'],cell=ctx.cell;if(cell&&neighbors(cell.q,cell.r).some(([q,r])=>terrainCell(q,r)?.type==='sea'))names.push('Coastal Fort');
  const visible=names.filter(name=>battleState?.mode!=='campaign'||EW4NativeUpgrade.recruitAllowed(activeBattleTechLevel(EW4NativeUpgrade.techIdForFort(name)))),fortImages={'Small Fortress':'assets/sprites/image_recruit_hd2/buildmarker_smallfortress.png','Fortress':'assets/sprites/image_recruit_hd/buildmarker_mediumfortress.png','Large Fortress':'assets/sprites/image_recruit_hd/buildmarker_largefortress.png','Coastal Fort':'assets/sprites/image_recruit_hd/buildmarker_coastalartillery.png'};
  return visible.map(name=>{const card=BUILD_CARDS?.[name];return{type:name,label:armyName(name),card,imagePath:fortImages[name]||'',desc:STRINGS?.[`desc_${name}`]||'',cost:{money:+card?.price||0,industry:+card?.industry||0}}})
}
function renderNativeDefensePanel(){
  const p=document.getElementById('defense-panel'),list=document.getElementById('defense-list'),title=document.getElementById('defense-desc-title'),desc=document.getElementById('defense-desc-text'),ok=document.getElementById('defense-confirm'),ctx=p?._context;if(!p||!list||!title||!desc||!ok||!ctx)return;const choices=nativeDefenseChoices(ctx),sel=choices.length?Math.max(0,Math.min(choices.length-1,+p._selected||0)):0;p._selected=sel;list.innerHTML='';
  choices.forEach((choice,i)=>{const b=document.createElement('button');b.className='defense-choice'+(i===sel?' sel':'');bindTutorialUI(b,'lbox_defense',i);const img=choice.imagePath?`<img src="${choice.imagePath}" alt="">`:'';b.innerHTML=`${img}<b>${choice.label}</b><small><span>💰${choice.cost?.money??0}</span><span>⚙️${choice.cost?.industry??0}</span></small>`;b.onclick=e=>{e.stopPropagation();p._selected=i;renderNativeDefensePanel()};list.appendChild(b)});
  const choice=choices[sel],c=choice?.cost||{money:0,industry:0},affordable=!!choice&&(battleState?.resources?.money||0)>=c.money&&(battleState?.resources?.industry||0)>=c.industry;title.textContent=choice?.label||'—';desc.textContent=choice?.desc||'当前战区科技尚未解锁可建造的防御设施。';ok.disabled=!choice||!affordable;bindTutorialUI(ok,'winbtn_ok');ok.onclick=e=>{e.stopPropagation();if(ok.disabled)return;const done=ctx.kind==='installation'?buildInstallation(ctx.u,choice.type):buildFortressAt(ctx.cell,choice.card);if(done!==false)hideNativeDefensePanel()}
}
function openNativeDefensePanel(ctx){if(!battleState||!ctx)return;const p=document.getElementById('defense-panel');if(!p)return;closeBattlePanels();p._context=ctx;p._selected=0;p.dataset.title=ctx.kind==='fortress'?'建造要塞':'防御工事';bindTutorialUI(document.getElementById('defense-close'),'winbtn_close');document.getElementById('defense-close').onclick=e=>{e.stopPropagation();hideNativeDefensePanel()};p.classList.add('show');p.setAttribute('aria-hidden','false');renderNativeDefensePanel();playNativeFormOpenSfx('form_defense');requestAnimationFrame(positionNativeTutorialHighlight)}
function showBuildMenu(u){if(!u||!isMine(u))return;openNativeDefensePanel({kind:'installation',u})}
function buildFortressAt(cell,card){
  if(!battleState||!cell||!card||ownerAt(cell.q,cell.r)!==battleState.playerOwner||terrainCell(cell.q,cell.r)?.type==='sea'||unitAt(cell.q,cell.r)||objectAt(cell.q,cell.r))return false;
  if(battleState.fortressBuiltRound===battleState.round){flash('本回合已经建造过要塞');return false}const money=+card.price||0,industry=+card.industry||0;if(battleState.resources.money<money||battleState.resources.industry<industry){flash('金币或工业不足');return false}
  battleState.resources.money-=money;battleState.resources.industry-=industry;const proto={owner:battleState.playerOwner,army_name:card.army||card.name,grade:+card.grade||0,max_hp:1},st=armyStat(proto),rounds=Math.max(1,+card.buildround||1),fortTechId=EW4NativeUpgrade.techIdForFort(proto.army_name),trainingLevel=battleState.mode==='campaign'&&fortTechId!=null?EW4NativeUpgrade.initialTrainingLevel(activeBattleTechLevel(fortTechId)):0,u={index:100000+battleState.units.length,q:cell.q,r:cell.r,army_id:armyIdByName(proto.army_name),army_name:proto.army_name,grade:proto.grade,hp:+st.strength||100,max_hp:+st.strength||100,commander_id:null,owner:battleState.playerOwner,dead:false,moved:true,attacked:true,trainingLevel,trainingExp:0,underConstruction:true,constructionRoundsRemaining:rounds,constructionTotalRounds:rounds};EW4PlayerUnitRules.applyBaseHp(u,true);battleState.units.push(u);battleState.fortressBuiltRound=battleState.round;battleState.selectedCell=null;battleState.selected=u;updateResources();playNativeActionSfx('buildInstallation');spawnNativeSimpleEffect('effect_build',cell.q,cell.r);renderBattleActions();renderBattle();flash(`${armyName(u.army_name)} 开始建造　${rounds} 回合`);return true
}
function advanceFortressConstruction(){if(!battleState)return;for(const u of battleState.units){if(u.dead||!u.underConstruction)continue;u.constructionRoundsRemaining=Math.max(0,(+u.constructionRoundsRemaining||1)-1);if(u.constructionRoundsRemaining>0){u.moved=true;u.attacked=true}else{u.underConstruction=false;u.moved=false;u.attacked=false;spawnNativeSimpleEffect('effect_build',u.q,u.r);if(isMine(u))flash(`${armyName(u.army_name)} 建造完成`)}}}

function canEmbark(u){if(!u||u.dead||!isMine(u)||isSeaUnit(u)||isFort(u)||u.embarked)return false;if(battleState.mode==='campaign'&&!EW4NativeUpgrade.canEmbarkArmy(u.army_name,activeBattleTechLevel(25)))return false;return neighbors(u.q,u.r).some(([q,r])=>terrainCell(q,r)?.type==='sea')}
function troopshipCost(u){const card=BUILD_CARDS?.Troopship;return{money:+card?.price||40,industry:+card?.industry||0}}
function promptEmbarkUnit(u,anchor){if(!canEmbark(u))return;const cost=troopshipCost(u);openNativeActionResource(anchor,{money:cost.money,secondary:cost.industry,secondaryKind:'industry',onConfirm:()=>embarkUnit(u)})}
function embarkUnit(u){
  if(!canEmbark(u))return;const cost=troopshipCost(u);
  if(battleState.resources.money<cost.money||battleState.resources.industry<cost.industry){flash('资源不足，无法建造运输船');return}
  battleState.resources.money-=cost.money;battleState.resources.industry-=cost.industry;u.embarked=true;if(battleState.selected===u)battleState.reachable=computeReachable(u);updateResources();closeBattlePanels();renderBattleActions();renderBattle();flash(`运输船准备完成　💰-${cost.money}`)
}
function installationAt(q,r){return (battleState?.installations||[]).find(x=>x.q===q&&x.r===r)||null}
function installationReductionAt(attacker,defender){const ins=installationAt(defender.q,defender.r);if(!ins)return 0;const st=armyStat(attacker),d=INSTALLATIONS?.[ins.type];return Math.max(0,+d?.[`penalty_${st.type}`]||0)}
function buildCostForInstallation(type,commander){
  const names={trench:'Trench',fence:'Fence',bunker:'Bunker'},card=BUILD_CARDS?.[names[type]];if(!card)return null;
  let money=+card.price||0,industry=+card.industry||0;
  return{money,industry,card};
}
function buildInstallation(u,type){
  if(!battleState||!u||!isMine(u)||u.dead||u.attacked||isFort(u)||isSeaUnit(u)||armyStat(u).type!=='infantry')return;
  if(terrainCell(u.q,u.r)?.type==='sea'){flash('海面不能修筑工事');return}
  if(installationAt(u.q,u.r)){flash('该位置已经存在野战工事');return}
  const cost=buildCostForInstallation(type,effectiveCommanderForUnit(u));if(!cost)return;
  if(battleState.resources.money<cost.money||battleState.resources.industry<cost.industry){flash('金币或工业不足');return}
  battleState.resources.money-=cost.money;battleState.resources.industry-=cost.industry;
  battleState.installations.push({q:u.q,r:u.r,type,owner:u.owner});u.attacked=true;u.moved=true;
  updateResources();closeBattlePanels();renderBattleActions();renderBattle();playNativeActionSfx('buildInstallation');tutorialNotifyAction();flash(`已修筑${type==='trench'?'战壕':type==='fence'?'栅栏':'掩体'}　💰-${cost.money} ⚙️-${cost.industry}`);return true
}
function selectUnit(u){battleState.selected=u;battleState.selectedObject=null;battleState.selectedCell=null;battleState.reachable=(u&&isMine(u)&&!u.dead)?computeReachable(u):new Map();closeBattlePanels();if(u)updateCellSummary(u.q,u.r);else updateCellSummary(null,null);renderBattleActions();if(u)playSfx('select');renderBattle()}
/* ---------- Native-style combat pipeline ---------- */
function moraleState(u){
  if(!u||u.dead)return 0;
  const c=effectiveCommanderForUnit(u),dirs=neighbors(u.q,u.r),hostile=dirs.map(([q,r])=>{const x=unitAt(q,r);return !!(x&&!x.dead&&isHostilePair(u,x))});
  let flank=0;
  if(hostile.every(Boolean))flank=-2;
  else if((hostile[0]&&hostile[3])||(hostile[1]&&hostile[4])||(hostile[2]&&hostile[5]))flank=-1;
  const base=EW4NativeEvent.eventMoraleBase(u,battleState?.round||1);
  return EW4NativeEvent.combinedMorale(base,flank,EW4Combat.hasSkill(c,3));
}
function terrainReductionAgainst(a,b){const st=armyStat(a),t=terrainCell(b.q,b.r),def=WORLDS.terrain_types[t?.type||'land']||{};return Math.max(0,+def[`penalty_${st.type}`]||0)}
function buildingReductionAt(u){const o=objectAt(u.q,u.r);if(!o)return 0;return Math.max(0,+constructionLevel(o)?.avoid||0)}
function hasConstructionAt(u){return !!(u&&objectAt(u.q,u.r))}
function defenseEquipmentBonus(u){const st=armyStat(u);let n=auraValueAround(u,15);for(const id of equippedItemIds(u)){const it=ITEMS?.[String(id)];if(!it||!itemTargetMatches(it,st))continue;if(+it.function===10)n+=+it.value||0}return n}

function spawnBattleFloat(q,r,text,color='#fff0c8'){if(!battleState)return;const now=performance.now();(battleState.floatTexts||(battleState.floatTexts=[])).push({q,r,text:String(text),color,start:now,until:now+850});requestBattleAnimation(900)}
function spawnNativeMovementEffect(u,moveAnim){
  if(!battleState||!u||!moveAnim||!NATIVE_SIMPLE_EFFECTS_DATA||!window.EW4NativeSimpleEffect||!window.EW4NativeMovementEffect)return false;
  const effectId=EW4NativeMovementEffect.effectForMovement(u,armyStat(u)),effect=NATIVE_SIMPLE_EFFECTS_DATA.effects?.[effectId];if(!effect)return false;
  const startCell=moveAnim.path?.[0],startWorld=startCell?worldPoint(startCell.q,startCell.r):worldPoint(u.q,u.r),now=performance.now();
  const rect={x0:startWorld.x,y0:startWorld.y,x1:startWorld.x,y1:startWorld.y},runtime=EW4NativeSimpleEffect.createInstance(effect,startWorld,{rect});if(!runtime)return false;
  const tail=Math.max(0,+effect.particle_life_max||+effect.particle_life_min||0)*1000+100;
  (battleState.simpleEffects||(battleState.simpleEffects=[])).push({effectId,worldSpace:true,moveUnitIndex:+u.index,moveUntil:+moveAnim.until,lastWorld:startWorld,start:now,last:now,until:+moveAnim.until+tail,runtime});
  img(NATIVE_SIMPLE_EFFECTS_DATA.atlas);requestBattleAnimation(Math.max(0,+moveAnim.until-now)+tail+30);return true;
}
function spawnNativeUnitLocalEffect(effectId,u,offsetX=0,offsetY=0,rotation=0){
  if(!battleState||!u||u.dead||!NATIVE_SIMPLE_EFFECTS_DATA||!window.EW4NativeSimpleEffect)return false;
  const base=NATIVE_SIMPLE_EFFECTS_DATA.effects?.[effectId];if(!base)return false;
  const rot=+rotation||0,effect=rot?{...base,angle_min:(+base.angle_min||0)+rot,angle_max:(+base.angle_max||0)+rot,rotangle_min:(+base.rotangle_min||0)+rot,rotangle_max:(+base.rotangle_max||0)+rot}:base;
  const now=performance.now(),runtime=EW4NativeSimpleEffect.createInstance(effect,{x:0,y:0});if(!runtime)return false;
  const duration=EW4NativeSimpleEffect.effectDuration(effect);
  (battleState.simpleEffects||(battleState.simpleEffects=[])).push({effectId,unitLocal:true,unitIndex:+u.index,offsetX:+offsetX||0,offsetY:+offsetY||0,start:now,last:now,until:now+duration*1000+80,runtime});
  img(NATIVE_SIMPLE_EFFECTS_DATA.atlas);requestBattleAnimation(duration*1000+100);return true;
}
function spawnNativeAttackTimelineEffect(effectFile,u,cue={}){
  const ids=NATIVE_SIMPLE_EFFECTS_DATA?.groups?.[effectFile]||[];let n=0;
  for(const id of ids)if(spawnNativeUnitLocalEffect(id,u,cue.x,cue.y,cue.rot))n++;
  return n>0;
}
function spawnNativeCellTimelineEffect(effectFile,q,r,cue={}){const ids=NATIVE_SIMPLE_EFFECTS_DATA?.groups?.[effectFile]||[];let n=0;for(const id of ids)if(spawnNativeCellLocalEffect(id,q,r,cue.x,cue.y,cue.rot))n++;return n>0}
function spawnNativeCellLocalEffect(effectId,q,r,offsetX=0,offsetY=0,rotation=0){
  if(!battleState||!NATIVE_SIMPLE_EFFECTS_DATA||!window.EW4NativeSimpleEffect)return false;const base=NATIVE_SIMPLE_EFFECTS_DATA.effects?.[effectId];if(!base)return false;
  const rot=+rotation||0,effect=rot?{...base,angle_min:(+base.angle_min||0)+rot,angle_max:(+base.angle_max||0)+rot,rotangle_min:(+base.rotangle_min||0)+rot,rotangle_max:(+base.rotangle_max||0)+rot}:base,now=performance.now(),runtime=EW4NativeSimpleEffect.createInstance(effect,{x:0,y:0});if(!runtime)return false;
  const duration=EW4NativeSimpleEffect.effectDuration(effect);(battleState.simpleEffects||(battleState.simpleEffects=[])).push({effectId,cellLocal:true,q:+q,r:+r,offsetX:+offsetX||0,offsetY:+offsetY||0,start:now,last:now,until:now+duration*1000+80,runtime});img(NATIVE_SIMPLE_EFFECTS_DATA.atlas);requestBattleAnimation(duration*1000+100);return true
}
function spawnNativeSimpleEffect(effectId,q,r){
  if(!battleState||!NATIVE_SIMPLE_EFFECTS_DATA||!window.EW4NativeSimpleEffect)return false;
  const effect=NATIVE_SIMPLE_EFFECTS_DATA.effects?.[effectId];if(!effect)return false;
  const now=performance.now(),runtime=EW4NativeSimpleEffect.createInstance(effect,{x:0,y:0});if(!runtime)return false;
  const duration=EW4NativeSimpleEffect.effectDuration(effect);
  (battleState.simpleEffects||(battleState.simpleEffects=[])).push({effectId,q:+q,r:+r,start:now,last:now,until:now+duration*1000+80,runtime});
  img(NATIVE_SIMPLE_EFFECTS_DATA.atlas);requestBattleAnimation(duration*1000+100);return true;
}
function drawNativeSimpleEffects(){
  if(!battleState?.simpleEffects?.length||!NATIVE_SIMPLE_EFFECTS_DATA||!window.EW4NativeSimpleEffect)return;
  const atlas=img(NATIVE_SIMPLE_EFFECTS_DATA.atlas),now=performance.now(),z=battleState.camera.zoom,c=battleState.camera;
  battleState.simpleEffects=battleState.simpleEffects.filter(inst=>{
    const dt=Math.max(0,Math.min(.1,(now-inst.last)/1000));inst.last=now;
    if(inst.worldSpace&&inst.moveUnitIndex!=null){
      const u=battleState.units.find(x=>+x.index===+inst.moveUnitIndex&&!x.dead),cur=u?unitDisplayWorldPointAt(u,now):inst.lastWorld;
      if(cur){const prev=inst.lastWorld||cur;inst.runtime.rect={x0:prev.x,y0:prev.y,x1:cur.x,y1:cur.y};inst.lastWorld=cur}
      if(!u||now>=inst.moveUntil)EW4NativeSimpleEffect.stopInstance(inst.runtime);
    }
    EW4NativeSimpleEffect.advance(inst.runtime,dt);
    if(!EW4NativeSimpleEffect.isAlive(inst.runtime)||now>=inst.until)return false;
    if(atlas?.complete){
      if(inst.unitLocal){
        const u=battleState.units.find(x=>+x.index===+inst.unitIndex&&!x.dead);if(!u)return false;
        const p=unitScreenPoint(u),uz=unitVisualZoom(z),anchor={x:p.x+(+inst.offsetX||0)*uz,y:p.y+(+inst.offsetY||0)*uz};
        EW4NativeSimpleEffect.drawInstance(ctx,atlas,inst.runtime,uz,anchor)
      }else if(inst.cellLocal){
        const p=screenPoint(inst.q,inst.r),anchor={x:p.x+(+inst.offsetX||0)*z,y:p.y+(+inst.offsetY||0)*z};EW4NativeSimpleEffect.drawInstance(ctx,atlas,inst.runtime,z,anchor)
      }else{
        const anchor=inst.worldSpace?{x:284-c.x*z,y:160-c.y*z}:screenPoint(inst.q,inst.r);
        EW4NativeSimpleEffect.drawInstance(ctx,atlas,inst.runtime,z,anchor)
      }
    }
    return true;
  });
}
function drawBattleFloats(){if(!battleState?.floatTexts?.length)return;const now=performance.now(),z=battleState.camera.zoom;ctx.save();ctx.textAlign='center';ctx.font=`bold ${Math.max(9,12*z)}px sans-serif`;battleState.floatTexts=battleState.floatTexts.filter(f=>{if(now>=f.until)return false;const p=screenPoint(f.q,f.r),t=(now-f.start)/(f.until-f.start);ctx.globalAlpha=Math.max(0,1-t);ctx.lineWidth=2;ctx.strokeStyle='#1b0b06';ctx.fillStyle=f.color;const y=p.y-20*z-t*20;ctx.strokeText(f.text,p.x,y);ctx.fillText(f.text,p.x,y);return true});ctx.restore();ctx.globalAlpha=1}
function combatResult(a,b,{multiplier=1,isCounter=false,rng=Math.random}={}){
  const st=armyStat(a),dst=armyStat(b),cmd=effectiveCommanderForUnit(a),dcmd=effectiveCommanderForUnit(b),m=attackModifiers(a),at=terrainCell(a.q,a.r);
  let out=EW4Combat.resolveDamage({
    attacker:combatUnit(a),defender:b,attackerStat:st,defenderStat:dst,attackerCommander:cmd,defenderCommander:dcmd,
    isPlayerAttacker:isMine(a),attackerIsFort:isFort(a),defenderIsFort:isFort(b),isCounter,
    fixedBonus:m.fixed,lowerBonus:m.lower,upperBonus:m.upper,
    attackerMorale:moraleState(a),defenderMorale:moraleState(b),
    attackerEmbarked:at?.type==='sea'&&st.type!=='warship'&&!hasEquipmentFunction(a,12),
    terrainReduction:terrainReductionAgainst(a,b),buildingReduction:buildingReductionAt(b),defenderHasConstruction:hasConstructionAt(b),installationReduction:installationReductionAt(a,b),countryReduction:0,
    defenderTrainingDefense:trainingDefenseBonus(b)
  },rng);
  let value=Math.max(1,Math.round(out.value*multiplier));
  const armor=defenseEquipmentBonus(b);if(armor>0){value=Math.max(1,value-armor);out.notes=[...out.notes,`armor-${armor}`]}
  return {...out,value};
}
function damageValue(a,b,rng=Math.random){return combatResult(a,b,{rng}).value}
function awardCombatTrainingExp(u,damage){
  if(!u||damage<=0)return null;ensureUnitTrainingState(u);
  const out=EW4NativeTraining.awardExp(u,damage,{hasCommander:u.commander_id!=null,unitType:armyStat(u).type});
  if(out.leveled){playNativeSfxFile('sfx_lvup.wav');spawnBattleFloat(u.q,u.r,`训练 ${out.after}级`,'#9be7ff')}
  return out
}
const NATIVE_ARMY_TYPE=Object.freeze({infantry:0,cavalry:1,artillery:2,warship:3,fort:4});
function maybeCollectBattleMedal(attacker,damage,rng=Math.random){
  if(!battleState||battleState.ended||!attacker||attacker.dead||!isMine(attacker)||!window.EW4NativeResult)return false;const st=armyStat(attacker),nativeType=NATIVE_ARMY_TYPE[st.type]??255,nativeLevel=Math.max(0,Math.trunc(+attacker.grade||0)),roll=Math.floor(Math.max(0,Math.min(.999999999,+rng()))*100);if(!EW4NativeResult.collectMedalProc(damage,roll,nativeType,nativeLevel))return false;battleState.collectMedal=Math.max(0,+battleState.collectMedal||0)+1;playNativeSfxFile('sfx_lvup.wav');spawnNativeGetMedalEffect(attacker);return true
}
function applyDamage(a,b,opts={}){if(typeof opts==='number')opts={multiplier:opts};const rng=typeof opts.rng==='function'?opts.rng:Math.random,wasAlive=!b.dead&&(+b.hp||0)>0,beforeHp=Math.max(0,+b.hp||0),out=combatResult(a,b,{...opts,rng});maybeCollectBattleMedal(a,out.value,rng);b.hp-=out.value;const killed=wasAlive&&b.hp<=0;if(b.hp<=0){b.hp=0;b.dead=true;if(wasAlive)fireNativeDeathEventsForUnit(b)}out.presentation={beforeHp,afterHp:Math.max(0,+b.hp||0),killed,damage:out.value,color:out.defenseTactic?'#9ad8ff':out.attackTactic?'#ffd35a':'#fff0c8'};if(!opts.deferVisual){spawnBattleFloat(b.q,b.r,`-${out.value}`,out.presentation.color);if(killed)spawnBattleFloat(b.q,b.r,'✦','#f6c66b')}awardNativeGeneralCombatGrowth(a,b,out.value,killed);return out}
function queueDamagePresentation(target,result,delayMs=0){if(!battleState||!target||!result?.presentation)return 0;const ref=battleState,p=result.presentation,now=performance.now();if(!Array.isArray(target.damagePresentationQueue))setUnitPresentationTransient(target,'damagePresentationQueue',[]);if(!target.damagePresentationQueue.length)setUnitPresentationTransient(target,'presentationHp',p.beforeHp);const last=target.damagePresentationQueue[target.damagePresentationQueue.length-1],due=Math.max(now+Math.max(0,+delayMs||0),(+last?.due||0)+1),entry={due,afterHp:p.afterHp,damage:p.damage,killed:!!p.killed,color:p.color};target.damagePresentationQueue.push(entry);const wait=Math.max(0,due-now);setTimeout(()=>{const q=target.damagePresentationQueue;if(!Array.isArray(q))return;const i=q.indexOf(entry);if(i<0)return;setUnitPresentationTransient(target,'presentationHp',entry.afterHp);q.splice(i,1);if(battleState===ref){spawnBattleFloat(target.q,target.r,`-${entry.damage}`,entry.color);if(entry.killed)spawnBattleFloat(target.q,target.r,'✦','#f6c66b')}if(!q.length){setUnitPresentationTransient(target,'damagePresentationQueue',null);setUnitPresentationTransient(target,'presentationHp',null)}if(battleState===ref){requestBattleAnimation(260);renderBattle()}},wait);requestBattleAnimation(wait+280);return wait}
function scheduleVictoryAfterPresentation(delayMs=0){const ref=battleState;if(!ref)return;const token=(ref.presentationVictoryToken||0)+1;ref.presentationVictoryToken=token;setTimeout(()=>{if(battleState===ref&&ref.presentationVictoryToken===token)checkVictory()},Math.max(0,+delayMs||0)+20)}
function resolvePlayerAttack(a,b){if(!battleState||!a||!b||!inAttackRange(a,b))return;const st=armyStat(a),attackMs=startAttackAnim(a,b),impactMs=attackImpactDelayMs(a,attackMs);let actionMs=attackMs,presentationMs=impactMs;const hit=applyDamage(a,b,{multiplier:1,isCounter:false,deferVisual:true});scheduleNativeImpactTimeline(a,b,hit.value,impactMs);queueDamagePresentation(b,hit,impactMs);a.attacked=true;a.undoState=null;if(+battleState.undoUnitIndex===+a.index)battleState.undoUnitIndex=null;let counter=null;if(!b.dead&&st.type!=='artillery'&&canRange(b,a,true)){const counterMs=startAttackAnim(b,a),counterImpactMs=attackImpactDelayMs(b,counterMs);actionMs=Math.max(actionMs,counterMs);presentationMs=Math.max(presentationMs,counterImpactMs);counter=applyDamage(b,a,{multiplier:.68,isCounter:true,deferVisual:true});scheduleNativeImpactTimeline(b,a,counter.value,counterImpactMs);queueDamagePresentation(a,counter,counterImpactMs)}awardCombatTrainingExp(a,hit.value);if(counter)awardCombatTrainingExp(b,counter.value);const extra=grantCavalryExtraAction(a,b);const fx=[hit.attackTactic?'致命一击':'',hit.defenseTactic?'防御战术':'',extra?'骑兵再动':'',...(hit.notes||[]).filter(x=>!['attack-tactics','defense-tactics'].includes(x))].filter(Boolean);flash(`${armyName(a.army_name)} → ${armyName(b.army_name)}　-${hit.value}${fx.length?` [${fx.join('·')}]`:''}${counter?`　反击 -${counter.value}`:''}`);if(!extra)battleState.reachable=new Map();scheduleVictoryAfterPresentation(presentationMs);closeBattlePanels();renderBattleActions();renderBattle();tutorialNotifyAction(Math.max(80,actionMs+30));setTimeout(()=>{if(battleState)renderBattle()},760);return{hit,counter,extra,presentationMs}}
function attack(a,b){if(!inAttackRange(a,b))return;if(queueNativePlayerPairFocus(a,b,()=>resolvePlayerAttack(a,b)))return{deferred:true};return resolvePlayerAttack(a,b)}
function captureAt(u){
  if(!u||u.dead)return;let captured=[],eventCount=0;
  for(const o of battleState.objects){if(o.q!==u.q||o.r!==u.r||o.owner===u.owner)continue;if(relationBetweenOwners(u.owner,o.owner)!=='hostile')continue;o.owner=u.owner;captured.push(o.area_name||o.construction_type);eventCount+=fireNativeCaptureEventsForObject(o)}
  if(captured.length){setOwnerAt(u.q,u.r,u.owner);playNativeActionSfx('occupy');if(isMine(u)&&!eventCount)flash(`占领 ${captured.filter(Boolean).join(' / ')||'设施'}`);checkVictory()}
}
function resolvePlayerMove(u,q,r){if(!battleState||!u||u.dead||!battleState.reachable.has(`${q},${r}`))return;const path=movementPath(u,q,r),captures=battleState.objects.some(o=>o.q===q&&o.r===r&&o.owner!==u.owner&&relationBetweenOwners(u.owner,o.owner)==='hostile');if(!captures){u.undoState={q:u.q,r:u.r,embarked:!!u.embarked,moved:!!u.moved,attacked:!!u.attacked,path:path.map(x=>({q:x.q,r:x.r}))};battleState.undoUnitIndex=+u.index}else{u.undoState=null;battleState.undoUnitIndex=null}startMoveAnim(u,path);const moveMs=Math.max(20,(u.moveAnim?.until||performance.now())-performance.now());u.q=q;u.r=r;if(u.embarked&&terrainCell(q,r)?.type!=='sea')u.embarked=false;if(fireproofUnit(u))battleState.fireCells?.delete(`${q},${r}`);u.moved=true;battleState.reachable=new Map();battleState.selected=u;battleState.selectedCell=null;captureAt(u);playNativeMovementSfx(u);closeBattlePanels();renderBattleActions();renderBattle();tutorialNotifyAction(moveMs+30)}
function moveUnit(u,q,r){if(!battleState.reachable.has(`${q},${r}`))return;const target={q,r};if(queueNativePlayerPairFocus(u,target,()=>resolvePlayerMove(u,q,r)))return{deferred:true};return resolvePlayerMove(u,q,r)}
function battleUndoUnit(){if(!battleState||battleState.phase==='ai'||battleState.undoUnitIndex==null)return null;const u=battleState.units.find(x=>+x.index===+battleState.undoUnitIndex&&!x.dead);return u?.undoState&&!u.attacked?u:null}
function syncBattleUndoButton(){const b=document.getElementById('battle-undo');if(!b)return;const u=battleUndoUnit();b.classList.toggle('show',!!u);b.disabled=!u;bindTutorialUI(b,'btn_undo')}
function performBattleUndo(){const u=battleUndoUnit();if(!u)return false;const snap=u.undoState,rev=[...(snap.path||[])].reverse();if(rev.length>=2)startMoveAnim(u,rev);const moveMs=Math.max(20,(u.moveAnim?.until||performance.now())-performance.now());u.q=snap.q;u.r=snap.r;u.embarked=!!snap.embarked;u.moved=!!snap.moved;u.attacked=!!snap.attacked;u.undoState=null;battleState.undoUnitIndex=null;battleState.selected=u;battleState.selectedObject=null;battleState.selectedCell=null;battleState.reachable=computeReachable(u);playNativeMovementSfx(u);closeBattlePanels();renderBattleActions();renderBattle();tutorialNotifyAction(moveMs+30);flash('部队已立即返回',700);return true}
function unitAt(q,r){return battleState.units.find(u=>!u.dead&&u.q===q&&u.r===r)}
function objectAt(q,r){return battleState.objects.find(o=>o.q===q&&o.r===r&&o.construction_type)}
function constructionLevel(o){const d=CONSTRUCTIONS[o.construction_type],levels=d?.levels||[];return levels.find(x=>+x.idx===+o.level)||levels[Math.max(0,Math.min(levels.length-1,+o.level||0))]||null}
function upgradeConstructionCost(o){
  if(!o)return null;
  const g=unitAt(o.q,o.r),c=g&&g.owner===o.owner&&g.commander_id?effectiveCommanderForUnit(g):null;
  return EW4NativeConstruction.upgradeCost(o.construction_type,{architecture:!!(c&&EW4Combat.hasSkill(c,30))});
}
function nextConstructionLevel(o){const levels=CONSTRUCTIONS[o?.construction_type]?.levels||[],cur=+o?.level||0;return levels.filter(x=>+x.idx>cur).sort((a,b)=>+a.idx-+b.idx)[0]||null}
function canUpgradeConstruction(o){return !!(o&&o.owner===battleState?.playerOwner&&nextConstructionLevel(o)&&upgradeConstructionCost(o))}
function promptUpgradeConstruction(o,anchor){
  if(!canUpgradeConstruction(o))return;const cost=upgradeConstructionCost(o);openNativeActionResource(anchor,{money:cost.money,secondary:cost.industry,secondaryKind:'industry',onConfirm:()=>upgradeConstruction(o)})
}
function upgradeConstruction(o){
  if(!canUpgradeConstruction(o))return;const cost=upgradeConstructionCost(o),next=nextConstructionLevel(o);
  if(battleState.resources.money<cost.money||battleState.resources.industry<cost.industry){flash('金币或工业不足');return}
  battleState.resources.money-=cost.money;battleState.resources.industry-=cost.industry;o.level=+next.idx;
  updateResources();closeBattlePanels();renderBattleActions();playNativeActionSfx('upgradeConstruction');tutorialNotifyAction();spawnNativeSimpleEffect('effect_build',o.q,o.r);renderBattle();flash(`建筑升级　💰-${cost.money} ⚙️-${cost.industry}`)
}
function updateFacilitySummary(o){
  const el=document.getElementById('facility-summary');if(!el)return;if(!o){el.classList.remove('show');return}
  const lv=constructionLevel(o)||{},entries=EW4NativeConstruction.summaryEntries(lv);renderCellSummaryEntries(entries)
}
function renderCellSummaryEntries(entries){const el=document.getElementById('facility-summary');if(!el)return;entries=Array.isArray(entries)?entries:[];for(let i=0;i<4;i++){const cell=el.querySelector(`.slot${i+1}`),img=document.getElementById(`facility-summary-icon${i+1}`),val=document.getElementById(`facility-summary-value${i+1}`),entry=entries[i];if(!cell||!img||!val)continue;cell.classList.toggle('empty',!entry);if(entry){img.src=entry.icon?.includes('/')?entry.icon:`assets/sprites/image_ui_hd/${entry.icon}`;img.alt='';val.textContent=String(entry.value)}}el.classList.toggle('show',entries.length>0);requestAnimationFrame(positionNativeTutorialHighlight)}
function updateCellSummary(q,r){if(!battleState||q==null||r==null){document.getElementById('facility-summary')?.classList.remove('show');return}const o=objectAt(+q,+r);if(o){updateFacilitySummary(o);return}const t=terrainCell(+q,+r),d=WORLDS?.terrain_types?.[t?.type||'land'];if(!d){document.getElementById('facility-summary')?.classList.remove('show');return}const entries=[{icon:'infomarker_move.png',value:+d.movementcost||0},{icon:'marker_dfs_infantry.png',value:+d.penalty_infantry||0},{icon:'marker_dfs_cavalry.png',value:+d.penalty_cavalry||0},{icon:'marker_dfs_artillery.png',value:+d.penalty_artillery||0}];renderCellSummaryEntries(entries)}
function recruitSelectionStats(rec,card){
  const proto={owner:battleState.playerOwner,army_name:rec.name,grade:+rec.grade},st=armyStat(proto);return{st,card}
}
function showFacilityCard(o){
  if(!o)return;document.getElementById('unit-card').style.display='none';document.getElementById('battle-action-menu').classList.remove('show');
  const el=document.getElementById('facility-card'),lv=constructionLevel(o),mine=o.owner===battleState.playerOwner,recruitCaps=(lv?.recruit||[]).filter(cap=>battleState.mode!=='campaign'||EW4NativeUpgrade.recruitAllowed(activeArmyTechLevel(cap.name)));if(!mine||!recruitCaps.length){el.style.display='none';if(mine&&lv?.recruit?.length)flash('当前战区科技尚未解锁可征募兵种');return}
  el.className='native-user-window native-recruit show';el.dataset.title='征募部队';el.innerHTML='<button class="native-close recruit-native-close" aria-label="关闭"></button><div class="recruit-native-list" data-recruit-list></div><div class="recruit-native-info" data-recruit-info></div><div class="recruit-native-desc" data-recruit-desc></div><button class="native-recruit-confirm" data-recruit-confirm aria-label="确定"></button>';bindTutorialUI(el.querySelector('.recruit-native-close'),'winbtn_close');bindTutorialUI(el.querySelector('[data-recruit-confirm]'),'winbtn_ok');el.querySelector('.recruit-native-close').onclick=e=>{e.stopPropagation();el.style.display='none';el.classList.remove('show')};
  const list=el.querySelector('[data-recruit-list]'),info=el.querySelector('[data-recruit-info]'),desc=el.querySelector('[data-recruit-desc]'),confirm=el.querySelector('[data-recruit-confirm]');let selected=0,selectedGrade=0;
  function selectedRecruit(){const cap=recruitCaps[selected];if(!cap)return null;return{name:cap.name,grade:Math.max(0,Math.min(+cap.grade||0,selectedGrade)),maxGrade:+cap.grade||0}}
  function renderSel(){
    [...list.children].forEach((x,i)=>x.classList.toggle('sel',i===selected));const rec=selectedRecruit();if(!rec){confirm.disabled=true;return}const card=CARDS[`${rec.name}|${rec.grade}`],{st}=recruitSelectionStats(rec,card),atk=EW4Combat.effectiveAttackInterval({min:+st.minatk||0,max:+st.maxatk||0,isPlayer:true}),hp=EW4PlayerUnitRules.effectiveBaseHp(+st.strength||0,true),mv=EW4PlayerUnitRules.effectiveMovement(+st.movement||0,st.type,true);
    info.innerHTML=`<span>HP<br>${hp}</span><span>攻<br>${atk.min}-${atk.max}</span><span>移<br>${mv}</span><span>粮<br>${+st.consumption||0}</span><span>射程<br>${+st.minatkrange||0}-${+st.maxatkrange||0}</span><span>💰<br>${card?.price??'?'}</span><span>⚙️<br>${card?.industry??'?'}</span><span>编队<br>${rec.grade+1}/${rec.maxGrade+1}</span><span></span><span></span><span></span><span></span>`;
    desc.innerHTML=`<b>${armyName(rec.name)} · ${rec.grade+1}编</b>${STRINGS?.[`desc_${String(rec.name).toLowerCase().replace(/ /g,'_')}`]||'重复点击同一兵种可提高编队数量。'}`;confirm.disabled=!card;confirm.onclick=e=>{e.stopPropagation();recruitAt(o,{name:rec.name,grade:rec.grade},card)}
  }
  recruitCaps.forEach((cap,i)=>{const b=document.createElement('button');b.className='recruit-native-card';bindTutorialUI(b,'lbox_unit',i);const key=READY[`${cap.name} ${countryCode(o.owner)} 1`]?`${cap.name} ${countryCode(o.owner)} 1`:`${cap.name} 1`,m=READY[key],pic=m?.file||'';b.innerHTML=`${pic?`<img src="${pic}">`:''}<b>${armyName(cap.name)}</b><small>最多 ${+cap.grade+1} 编</small>`;b.onclick=e=>{e.stopPropagation();if(selected===i)selectedGrade=Math.min(+cap.grade||0,selectedGrade+1);else{selected=i;selectedGrade=0}renderSel()};list.appendChild(b)});
  renderSel();el.style.display='block';playSfx('select');requestAnimationFrame(positionNativeTutorialHighlight)
}
function selectFacility(o){battleState.selected=null;battleState.selectedCell=null;battleState.reachable=new Map();battleState.selectedObject=o;closeBattlePanels();if(o)updateCellSummary(o.q,o.r);else updateCellSummary(null,null);renderBattleActions();if(o)playSfx('select');renderBattle()}
function selectEmptyCell(cell){if(!battleState||!cell)return;battleState.selected=null;battleState.selectedObject=null;battleState.selectedCell={q:+cell.q,r:+cell.r};battleState.reachable=new Map();closeBattlePanels();updateCellSummary(cell.q,cell.r);renderBattleActions();playSfx('select');renderBattle()}

function recruitAt(o,rec,card){if(o.owner!==battleState.playerOwner)return;if(unitAt(o.q,o.r)){flash('该设施上已有部队，无法征募');return}if(!card){flash('原版征募卡数据未找到');return}if(battleState.resources.money<card.price||battleState.resources.industry<card.industry){flash('金币或工业不足');return}const proto={owner:battleState.playerOwner,army_name:rec.name,grade:+rec.grade};const st=armyStat(proto);battleState.resources.money-=card.price;battleState.resources.industry-=card.industry;const trainingLevel=battleState.mode==='campaign'?EW4NativeUpgrade.initialTrainingLevel(activeArmyTechLevel(rec.name)):0,u={index:100000+battleState.units.length,q:o.q,r:o.r,army_id:armyIdByName(rec.name),army_name:rec.name,grade:+rec.grade,hp:+st.strength||100,max_hp:+st.strength||100,commander_id:null,owner:battleState.playerOwner,dead:false,moved:true,attacked:true,trainingLevel,trainingExp:0};EW4PlayerUnitRules.applyBaseHp(u,true);battleState.units.push(u);updateResources();closeBattlePanels();renderBattleActions();playNativeActionSfx('recruit');renderBattle();tutorialNotifyAction();flash(`${armyName(rec.name)} ${+rec.grade+1}编 已征募`)}
function promptManualTrainUnit(u,anchor){
  if(!battleState||!u||u.dead||!isMine(u)||!u.commander_id)return;const c=effectiveCommanderForUnit(u),st=armyStat(u);ensureUnitTrainingState(u);if(!EW4NativeTraining.canManualTrain(u,c))return;const cost=EW4NativeTraining.manualCost(u,st);openNativeActionResource(anchor,{money:cost.money,secondary:cost.food,secondaryKind:'food',onConfirm:()=>manualTrainUnit(u)})
}
function manualTrainUnit(u){
  if(!battleState||!u||u.dead||!isMine(u)||!u.commander_id)return;
  const c=effectiveCommanderForUnit(u),st=armyStat(u);ensureUnitTrainingState(u);
  if(!EW4NativeTraining.canManualTrain(u,c)){flash('当前上将的训练能力无法继续提升该部队');return}
  const cost=EW4NativeTraining.manualCost(u,st);
  if(!EW4NativeTraining.canAfford(battleState.resources,cost)){flash(`训练资源不足　需要 💰${cost.money}　🌾${cost.food}`);return}
  const out=EW4NativeTraining.manualTrain(u,c,st,battleState.resources);if(!out.ok)return;
  /* Native 0x52381/0x5238d: successful manual training sets current movement to 0 and the turn-action flag to 1. */
  u.moved=true;u.attacked=true;battleState.reachable=new Map();
  updateResources();playNativeActionSfx('training');spawnBattleFloat(u.q,u.r,`训练 ${out.after}级`,'#9be7ff');
  closeBattlePanels();renderBattleActions();renderBattle();tutorialNotifyAction();flash(`部队训练提升至 ${out.after} 级　💰-${out.cost.money} 🌾-${out.cost.food}${out.heal?`　HP +${out.heal}`:''}`);
}
function handleTap(x,y){if(!battleState||battleState.cameraPresentationPending||battleState.cameraMotion||performance.now()<(battleState.inputLockedUntil||0)||!EW4NativeCamera.detailInteractionEnabled(battleState.camera.zoom))return;const w=screenToWorld(x,y),cell=nearestCell(w.x,w.y);if(!cell)return;tutorialNotifyArea(cell.q,cell.r);const u=unitAt(cell.q,cell.r),sel=battleState.selected;if(sel&&u&&isHostilePair(sel,u)&&inAttackRange(sel,u)){attack(sel,u);return}if(sel&&isMine(sel)&&battleState.reachable.has(`${cell.q},${cell.r}`)){moveUnit(sel,cell.q,cell.r);return}if(u){selectUnit(u);return}const o=objectAt(cell.q,cell.r);if(o){selectFacility(o);return}selectEmptyCell(cell)}
function resetNativeCountryFailure(){
  const o=document.getElementById('country-failure-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');
  if(battleState){battleState.countryFailureActive=false;battleState.countryFailureQueue=[];battleState.countryFailureWaiters=[]}
}
function renderNativeCountryFailure(owner){
  const code=countryCode(+owner),c=battleState?.battle?.countries?.find(x=>+x.index===+owner),flag=spriteFile(`${code}1.png`),im=document.getElementById('country-failure-flag'),name=document.getElementById('country-failure-name');
  if(im){if(flag){im.src=flag;im.style.display='block'}else{im.removeAttribute('src');im.style.display='none'}im.alt=c?.name_cn||code.toUpperCase()}
  if(name)name.textContent=c?.name_cn||code.toUpperCase()
}
function openNextNativeCountryFailure(){
  if(!battleState||battleState.ended)return false;const owner=battleState.countryFailureQueue?.shift();if(owner==null)return false;
  battleState.countryFailureActive=true;renderNativeCountryFailure(owner);playNativeFormOpenSfx('form_failure');const o=document.getElementById('country-failure-overlay');o?.classList.add('show');o?.setAttribute('aria-hidden','false');return true
}
function closeNativeCountryFailure(){
  if(!battleState)return;const o=document.getElementById('country-failure-overlay');o?.classList.remove('show');o?.setAttribute('aria-hidden','true');battleState.countryFailureActive=false;
  if(openNextNativeCountryFailure())return;
  checkVictory();if(battleState?.ended){battleState.countryFailureWaiters=[];return}
  const waiters=[...(battleState.countryFailureWaiters||[])];battleState.countryFailureWaiters=[];for(const fn of waiters)setTimeout(()=>{if(battleState&&!battleState.ended)fn()},0)
}
function syncConquestDefeatedOwners({announce=true}={}){
  if(!battleState||battleState.mode!=='conquest'||!window.EW4NativeConquestExtinction)return[];
  battleState.defeatedOwners ||= new Set();battleState.countryFailureQueue ||= [];
  const current=EW4NativeConquestExtinction.defeatedOwners(battleState,u=>armyStat(u).type),fresh=[];
  for(const owner of current){if(battleState.defeatedOwners.has(+owner))continue;battleState.defeatedOwners.add(+owner);fresh.push(+owner);if(announce)battleState.countryFailureQueue.push(+owner)}
  if(announce&&fresh.length&&!battleState.countryFailureActive)openNextNativeCountryFailure();return fresh
}
function conquestCountryStatus(owner){
  if(!battleState||battleState.mode!=='conquest'||!window.EW4NativeConquestExtinction)return null;
  return EW4NativeConquestExtinction.countryStatus(battleState,+owner,u=>armyStat(u).type)
}
function conquestCountryDefeated(owner){return !!conquestCountryStatus(owner)?.defeated}
function checkVictory(){
  if(!battleState||battleState.ended)return;
  const me=battleState.units.some(u=>!u.dead&&isMine(u)),enemy=battleState.units.some(u=>!u.dead&&isHostileOwner(u.owner));
  if(battleState.mode==='campaign'&&window.EW4NativeCampaign){
    const objective=EW4NativeCampaign.mainObjectiveOutcome(battleState,NATIVE_CAMPAIGN_TARGETS,battleState.nativeCampaignInitialTargets,ownerAt,me,enemy);
    if(objective){showBattleResult(objective.kind,objective.reason);return}
    const lim=nativeStageTurnLimits(battleState.battle);if(lim.valid&&battleState.round>lim.win){showBattleResult('defeat','turn-limit');return}
    return
  }
  if(battleState.mode==='conquest'&&window.EW4NativeConquestExtinction){
    const fresh=syncConquestDefeatedOwners();if(fresh.length||battleState.countryFailureActive)return;
    const outcome=EW4NativeConquestExtinction.outcome(battleState,{playerOwner:battleState.playerOwner,unitType:u=>armyStat(u).type,relation:(a,b)=>relationBetweenOwners(a,b)});
    if(outcome){showBattleResult(outcome.kind,outcome.reason);return}
    return
  }
  if(!me){showBattleResult('defeat','annihilated');return}if(!enemy){showBattleResult('victory','objective');return}
}
function facilityIncome(owner){let money=0,industry=0,food=0;for(const o of battleState.objects){if(o.owner!==owner)continue;const l=constructionLevel(o);if(!l)continue;let mult=1;const u=unitAt(o.q,o.r);if(u&&!u.dead&&u.owner===owner&&u.commander_id){const c=effectiveCommanderForUnit(u);if(EW4Combat.hasSkill(c,24))mult=Math.max(mult,1.8);else if(EW4Combat.hasSkill(c,23))mult=Math.max(mult,1.4);for(const id of equippedItemIds(u)){const it=ITEMS?.[String(id)];if(it&&+it.function===3)mult=Math.max(mult,(+it.value||100)/100)}}money+=Math.floor((+l.tax||0)*mult);industry+=Math.floor((+l.industry||0)*mult);food+=Math.floor((+l.food||0)*mult)}return{money,industry,food}}
function upkeep(owner){return battleState.units.filter(u=>!u.dead&&u.owner===owner).reduce((a,u)=>{const c=effectiveCommanderForUnit(u);return a+(EW4Combat.hasSkill(c,22)?0:(+armyStat(u).consumption||0))},0)}
function resourceLedger(owner){const k=String(+owner);if(!battleState.countryResources[k])battleState.countryResources[k]={money:0,industry:0,food:0};return battleState.countryResources[k]}
function settleCountryEconomy(owner){const r=resourceLedger(owner),inc=facilityIncome(owner),cost=upkeep(owner);if(battleState?.mode==='campaign'&&+owner===+battleState.playerOwner){inc.food+=EW4NativeUpgrade.economicBonus(activeBattleTechLevel(22),'food');inc.money+=EW4NativeUpgrade.economicBonus(activeBattleTechLevel(23),'money');inc.industry+=EW4NativeUpgrade.economicBonus(activeBattleTechLevel(24),'industry')}r.money+=inc.money;r.industry+=inc.industry;r.food=Math.max(0,r.food+inc.food-cost);return{inc,cost,resources:r}}
function facilitySupplyFor(u){const o=objectAt(u.q,u.r);if(!o||o.owner!==u.owner)return 0;return Math.max(0,+constructionLevel(o)?.supply||0)}
function applyTrainingRecoveryAll(){
  let total=0;for(const u of battleState?.units||[]){if(u.dead)continue;ensureUnitTrainingState(u);total+=EW4NativeTraining.applyRoundHeal(u)}return total
}
function applyFacilitySupplyAll(){
  /* APK tutorial/def_construction rule: every owned construction supplies a wounded friendly unit stationed on it.
     This is a base EW4 rule, so it must apply to player, allies and AI alike. */
  const totals=new Map();
  for(const u of battleState.units){
    if(u.dead||u.hp>=u.max_hp)continue;
    const supply=facilitySupplyFor(u);if(supply<=0)continue;
    const before=u.hp;u.hp=Math.min(u.max_hp,u.hp+supply);const got=u.hp-before;
    if(got>0)totals.set(u.owner,(totals.get(u.owner)||0)+got);
  }
  return totals;
}
function settlePlayerRound(){
  const settled=settleCountryEconomy(battleState.playerOwner),inc=settled.inc,cost=settled.cost;
  battleState.resources=settled.resources;
  const trainingHealed=applyTrainingRecoveryAll(),supplyTotals=applyFacilitySupplyAll(),facilityHealed=supplyTotals.get(battleState.playerOwner)||0;
  let playerSpecialHealed=0;
  for(const u of battleState.units){
    if(u.dead||!isMine(u)||u.hp>=u.max_hp)continue;
    const c=effectiveCommanderForUnit(u),noble=c?playerNobilityHeal(c):0,flag=auraValueAround(u,13),outside=!objectAt(u.q,u.r),tent=(!u.attacked&&outside)?equipmentFunctionValue(u,5):0,h=noble+flag+tent;
    if(h>0){const before=u.hp;u.hp=Math.min(u.max_hp,u.hp+h);playerSpecialHealed+=u.hp-before}
  }
  updateResources();
  const healed=trainingHealed+facilityHealed+playerSpecialHealed;
  return{money:+inc.money||0,industry:+inc.industry||0,foodAdd:+inc.food||0,foodDel:+cost||0,healed,trainingHealed,facilityHealed,playerSpecialHealed};
}
function updateResources(){const r=battleState?.resources;if(!r)return;document.getElementById('money-val').textContent=Math.floor(r.money);document.getElementById('industry-val').textContent=Math.floor(r.industry);document.getElementById('food-val').textContent=Math.floor(r.food)}
function aiTargetsFor(u){return battleState.units.filter(x=>!x.dead&&relationBetweenOwners(u.owner,x.owner)==='hostile'&&(battleState.mode!=='conquest'||!conquestCountryDefeated(x.owner)))}
function aiAttackableFrom(u,q,r,targets){const st=armyStat(u);return targets.filter(t=>{const d=hexDist({q,r},t);return d>=+st.minatkrange&&d<=+st.maxatkrange})}
function chooseAIDestination(u,targets){
  if(isFort(u)||u.moved)return{q:u.q,r:u.r,path:[{q:u.q,r:u.r}],target:null};
  const reach=computeReachable(u),cells=[{q:u.q,r:u.r},...[...reach.keys()].map(k=>{const[q,r]=k.split(',').map(Number);return{q,r}})];
  let best=null;
  for(const cell of cells){
    const attackable=aiAttackableFrom(u,cell.q,cell.r,targets).sort((a,b)=>(a.hp-b.hp)||hexDist(cell,a)-hexDist(cell,b));
    const nearest=targets.reduce((m,t)=>Math.min(m,hexDist(cell,t)),9999);
    // Prefer a legal firing cell, then a low-HP target, then closing distance.
    const score=(attackable.length?100000-attackable[0].hp*4:0)-nearest*100-(reach.get(`${cell.q},${cell.r}`)||0);
    if(!best||score>best.score)best={...cell,score,target:attackable[0]||null};
  }
  if(!best)return{q:u.q,r:u.r,path:[{q:u.q,r:u.r}],target:null};
  return{q:best.q,r:best.r,target:best.target,path:(best.q===u.q&&best.r===u.r)?[{q:u.q,r:u.r}]:movementPath(u,best.q,best.r)};
}

function setNativeAIAction(owner=null,visible=false){
  const box=document.getElementById('native-ai-action'),flag=document.getElementById('native-ai-action-flag');
  if(!box||!flag)return;
  const show=!!visible&&battleState&&owner!=null;
  box.classList.toggle('show',show);box.setAttribute('aria-hidden',show?'false':'true');
  if(!show){flag.removeAttribute('src');return}
  const code=countryCode(+owner),file=spriteFile(`${code}1.png`);if(file)flag.src=file;else flag.removeAttribute('src');
}

function setBattlePhase(phase){
  if(!battleState)return;const S=battleState;S.phase=phase;if(phase!=='ai')S.aiFastForward=false;
  const btn=document.getElementById('round-btn'),back=document.getElementById('battle-back');if(!btn)return;
  const ai=phase==='ai';if(!ai)setNativeAIAction(null,false);btn.style.backgroundImage=`url('assets/sprites/image_recruit_hd/${ai?'button_skip':'button_round'}.png')`;
  btn.style.setProperty('left',ai?'0px':'541px','important');btn.style.setProperty('top','293px','important');if(back)back.style.display=ai?'none':'block';
  btn.title=ai?'快进敌军行动':'结束回合';btn.setAttribute('aria-label',btn.title);btn.disabled=!!S.ended;renderBattleActions();
}
function aiDelay(fn,ms){setTimeout(()=>{if(battleState?.countryFailureActive){(battleState.countryFailureWaiters||(battleState.countryFailureWaiters=[])).push(fn);return}fn()},battleState?.aiFastForward?10:ms)}
function enemyTurn(){
  const S=battleState;if(!S||S.phase==='ai'||S.ended)return;setBattlePhase('ai');
  const owners=EW4CountryTurn.aiTurnOrder(S.battle,S.units,S.playerOwner,S.mode).filter(owner=>S.mode!=='conquest'||!conquestCountryDefeated(owner));let oi=0;
  function finishRound(){
    if(S.ended)return;S.round++;const roundSummary=settlePlayerRound();S.units.forEach(u=>{u.moved=false;u.attacked=false});advanceFortressConstruction();setBattlePhase('player');
    document.getElementById('turn-label').textContent=`回合 ${S.round} · 我方行动`;checkVictory();renderBattle();
    if(!S.ended)openNativeRoundTurn(roundSummary,()=>aiDelay(()=>{fireNativeRoundDialogues(S.round);if(!S.dialogueActive)writeBattleSave('auto',true)},90))
  }
  function runNextCountry(){
    if(S.ended)return;if(oi>=owners.length){finishRound();return}
    const owner=owners[oi++];if(S.mode==='conquest'&&conquestCountryDefeated(owner)){runNextCountry();return}setNativeAIAction(owner,true);const name=S.battle.countries[owner]?.name_cn||countryCode(owner).toUpperCase();
    document.getElementById('turn-label').textContent=`回合 ${S.round} · ${name}行动`;
    const units=S.units.filter(u=>!u.dead&&u.owner===owner);let i=0;
    function endCountry(){
      const settled=settleCountryEconomy(owner);S.activeAIResource={owner,...settled.resources};
      aiDelay(runNextCountry,80)
    }
    function step(){
      if(S.ended)return;if(i>=units.length){endCountry();return}
      const u=units[i++];if(u.dead){step();return}
      let targets=aiTargetsFor(u);if(!targets.length){step();return}
      targets.sort((a,b)=>hexDist(u,a)-hexDist(u,b));
      if(canRange(u,targets[0],false)){
        const target=targets[0],runAttack=()=>{let rr=null;if(battleState===S&&!S.ended&&!u.dead&&!target.dead)rr=attackAI(u,target);if(rr?.extra)i--;aiDelay(step,Math.max(145,(+rr?.presentationMs||0)+40))};
        if(queueNativeAIPairFocus(u,target,runAttack))return;runAttack();return
      }
      const plan=chooseAIDestination(u,targets),moved=plan.q!==u.q||plan.r!==u.r;
      const continueAfterMove=()=>{
        if(battleState!==S||S.ended)return;renderBattle();
        const afterTargets=aiTargetsFor(u),attackable=aiAttackableFrom(u,u.q,u.r,afterTargets).sort((a,b)=>(a.hp-b.hp)||hexDist(u,a)-hexDist(u,b));
        if(attackable.length&&!u.attacked){
          aiDelay(()=>{const target=attackable[0],runAttack=()=>{let rr=null;if(battleState===S&&!S.ended&&!u.dead&&!target.dead)rr=attackAI(u,target);if(rr?.extra)i--;aiDelay(step,Math.max(120,(+rr?.presentationMs||0)+40))};if(queueNativeAIPairFocus(u,target,runAttack))return;runAttack()},moved?135:20)
        }else aiDelay(step,moved?145:75)
      };
      const applyMove=()=>{
        if(battleState!==S||S.ended||u.dead)return;
        if(moved){const path=plan.path,oq=u.q,or=u.r;u.q=plan.q;u.r=plan.r;if(u.embarked&&terrainCell(u.q,u.r)?.type!=='sea')u.embarked=false;u.moved=true;startMoveAnim(u,path?.length>1?path:[{q:oq,r:or},{q:u.q,r:u.r}]);captureAt(u)}else u.moved=true;
        continueAfterMove()
      };
      if(moved&&queueNativeAIPairFocus(u,{q:plan.q,r:plan.r},applyMove))return;applyMove()
    }
    step()
  }
  runNextCountry()
}
function attackAI(a,b){const st=armyStat(a),attackMs=startAttackAnim(a,b),impactMs=attackImpactDelayMs(a,attackMs);let presentationMs=impactMs;const hit=applyDamage(a,b,{multiplier:1,isCounter:false,deferVisual:true});scheduleNativeImpactTimeline(a,b,hit.value,impactMs);queueDamagePresentation(b,hit,impactMs);a.attacked=true;let counter=null;if(!b.dead&&st.type!=='artillery'&&canRange(b,a,true)){const counterMs=startAttackAnim(b,a),counterImpactMs=attackImpactDelayMs(b,counterMs);presentationMs=Math.max(presentationMs,counterImpactMs);counter=applyDamage(b,a,{multiplier:.68,isCounter:true,deferVisual:true});scheduleNativeImpactTimeline(b,a,counter.value,counterImpactMs);queueDamagePresentation(a,counter,counterImpactMs)}awardCombatTrainingExp(a,hit.value);if(counter)awardCombatTrainingExp(b,counter.value);if(b.hp<=0)b.dead=true;const extra=grantCavalryExtraAction(a,b);renderBattle();scheduleVictoryAfterPresentation(presentationMs);return{hit,counter,extra,presentationMs}}

async function openBattle(b,mapOverride,opts={}){
  resetNativeStageIntro();resetNativeCountryFailure();
  await loadDB();selectedBattle=b||selectedBattle;if(!b)return;
  const restored=opts.restore?EW4BattleSave.normalize(opts.restore):null;
  const mode=restored?.mode||opts.mode||'campaign';if(mode==='campaign'){const zm=String(b.file||'').match(/^campaign([1-6])_/);if(zm)selectedZone=+zm[1]}const playerOwner=restored?.playerOwner??opts.playerOwner??b.player_owner_default??0,map=restored?.map||mapOverride||(b.header.map_id===2?'america':'europe'),world=WORLDS.worlds[map],h=b.header;
  const assignments=restored?.assignments||opts.assignments||new Map();
  const campaignTech=mode==='campaign'?(Array.isArray(restored?.campaignTech)&&restored.campaignTech.length===EW4NativeUpgrade.TECH_COUNT?restored.campaignTech.slice(0,EW4NativeUpgrade.TECH_COUNT):campaignTechRow(campaignZoneForBattle(b)).slice(0,EW4NativeUpgrade.TECH_COUNT)):null,campaignTechZone=mode==='campaign'?(+restored?.campaignTechZone||campaignZoneForBattle(b)):0;
  const units=restored?restored.units.map(u=>({...u,moveAnim:null,nativeAnim:null,attackAnimStart:0,attackPoseUntil:0})):b.units.map(u=>{const x={...u,dead:false,moved:false,attacked:false,nativeAnim:null};if(assignments.has(u.index))x.commander_id=assignments.get(u.index);return x});
  const countryResources=EW4CountryTurn.buildLedgers(b,{mode,playerOwner,restored:restored?.countryResources});
  if(restored&&!restored.countryResources)countryResources[String(+playerOwner)]={...restored.resources};
  const resources=countryResources[String(+playerOwner)]||EW4CountryTurn.headerResources(b);
  const restoredNativeCamera=restored?.cameraGeometry===EW4NativeHex.GEOMETRY_ID,openingFocus=EW4NativeCamera.openingFocusUnit(units,+playerOwner),fallbackStart=EW4NativeHex.battleRectCenter(h),openingPoint=openingFocus?.unit?EW4NativeHex.cellCenter(openingFocus.unit.q,openingFocus.unit.r):fallbackStart;const camera=restoredNativeCamera?{...restored.camera}:{x:openingPoint.x,y:openingPoint.y,zoom:restored?.camera?.zoom||1};
  battleState={battle:b,world,map,mode,campaignTech,campaignTechZone,cameraGeometry:EW4NativeHex.GEOMETRY_ID,playerOwner:+playerOwner,round:restored?.round||1,phase:'player',aiFastForward:false,musicTrack:chooseOriginalBattleMusic(),units,summonedPrincesses:[...new Set(units.filter(u=>u&&u.commander_id!=null&&PRINCESS_IDS.includes(+u.commander_id)&&+u.owner===+playerOwner).map(u=>+u.commander_id))],objects:restored?restored.objects.map(o=>({...o})):b.objects.map(o=>({...o})),ownership:restored?[...restored.ownership]:[...b.ownership],countryResources,resources,camera,cameraMotion:null,cameraAfterMotion:null,cameraPresentationPending:false,cameraPresentationKind:null,openingFocusReason:restoredNativeCamera?'restored-native-camera':(openingFocus?.reason||'battle-rect-fallback'),openingFocusExact:restoredNativeCamera?true:!!openingFocus?.exact,assignments:new Map(assignments),selected:null,selectedObject:null,selectedCell:null,undoUnitIndex:null,fortressBuiltRound:null,reachable:new Map(),dragging:false,installations:restored?restored.installations.map(x=>({...x})):[],fireCells:restored?new Set(restored.fireCells):new Set(),floatTexts:[],simpleEffects:[],getMedalEffects:[],collectMedal:Math.max(0,+restored?.collectMedal||0),dialogueQueue:[],defeatedOwners:new Set(),countryFailureQueue:[],countryFailureWaiters:[],countryFailureActive:false,nativeFiredEvents:restored?new Set(restored.nativeFiredEvents):new Set(),nativeAppliedEvents:restored?new Set(restored.nativeAppliedEvents):new Set(),itemStores:restored?.itemStores||initialBattleItemStores(b.file),taverns:restored?.taverns||initialBattleTaverns(b.file),dialogueActive:false,ended:restored?.ended||null,mapImg:img(`assets/maps/${map}.png`)};
  if(mode==='campaign'&&window.EW4NativeCampaign&&NATIVE_CAMPAIGN_TARGETS){const initialState={battle:b,units:b.units||[],objects:b.objects||[],playerOwner:+playerOwner};battleState.nativeCampaignInitialTargets=EW4NativeCampaign.initialTargetSnapshot(initialState,NATIVE_CAMPAIGN_TARGETS,(q,r)=>nativeOwnerAtForBattle(b,q,r))}
  loadNativeMapText(map);
  setBattleMusicTrack(battleState.musicTrack);
  if(mode==='conquest')syncConquestDefeatedOwners({announce:false});
  clampCamera(battleState.camera);for(const u of battleState.units){ensureUnitTrainingState(u,{fromBTL:!restored});EW4PlayerUnitRules.applyBaseHp(u,isMine(u));if(!restored){if(!isSeaUnit(u)&&!isFort(u)&&terrainCell(u.q,u.r)?.type==='sea')u.embarked=true;applyPlayerCommanderHp(u)}}
  hideBattleResult();hideCampaignComplete();hideConquestComplete();hideNativeDialogue();hideBattleModals();stopDefeatMusic();const nativeTargetSpec=mode==='campaign'?EW4NativeCampaign?.battleSpec?.(NATIVE_CAMPAIGN_TARGETS,b):null,nativeRedTargets=nativeTargetSpec?[...(nativeTargetSpec.map_targets||[]),...(nativeTargetSpec.unit_targets||[])].filter(x=>+x.type===1).length:0,nativeYellowTargets=nativeTargetSpec?[...(nativeTargetSpec.map_targets||[]),...(nativeTargetSpec.unit_targets||[])].filter(x=>+x.type===2).length:0;document.getElementById('battle-note').textContent=`${b.title_cn||b.name_cn||b.file}｜原 BTL：${b.runtime_counts?.units??b.units.length} 支部队 / ${b.runtime_counts?.objects??b.objects.length} 个地图对象；${nativeTargetSpec?`原生目标 红${nativeRedTargets} / 黄${nativeYellowTargets}`:`trigger ${BATTLE_NATIVE?.battles?.[b.file]?.event_count||0} 条`}。`;
  document.getElementById('turn-label').textContent=`回合 ${battleState.round} · 我方行动`;setBattlePhase('player');const back=document.getElementById('battle-back');back.dataset.go=mode==='conquest'?'conquest':mode==='tutorial'?'tutorial':'campaignList';closeBattlePanels();renderBattleActions();updateResources();go('battle');primeAssets();renderBattle();
  if(mode==='tutorial')setTimeout(()=>{if(battleState&&!battleState.ended&&battleState.mode==='tutorial')startNativeTutorialForBattle()},120);else if(!restored&&mode==='campaign')setTimeout(()=>{if(battleState&&!battleState.ended&&battleState.mode==='campaign')openNativeStageIntro(b,beginNativeCampaignBattleAfterIntro)},120);else if(!restored)setTimeout(()=>{if(battleState&&!battleState.ended){fireNativeRoundDialogues(1);if(!battleState.dialogueActive)writeBattleSave('auto',true)}},220)
}
function primeAssets(){if(!battleState)return;loadNativeGetMedalEffect();const S=battleState;S.units.forEach(u=>{unitImage(u);const k=readyKey(u);for(const db of [ATTACK_POSES,RELOAD_POSES,FINISH_POSES]){const m=db?.[k];if(m)img(m.file)}const nu=NATIVE_ANIM_PACK?.units?.[k];if(nu)for(const rec of nu.motions||[]){const a=NATIVE_ANIM_PACK.assets?.[rec.asset];if(a?.resource)preloadCompactBileResource(a.resource)}});S.objects.forEach(o=>{const k=buildingKey(o),m=k&&SPRITES[k];if(m)img(m.file);const mk=specialFacilityMarker(o),mm=mk&&SPRITES[mk];if(mm)img(mm.file)});S.battle.countries.forEach(c=>{const m=SPRITES[`${c.code}1.png`];if(m)img(m.file)});requestAnimationFrame(renderBattle)}
bindTutorialUI(document.getElementById('round-btn'),'btn_next');bindTutorialUI(document.getElementById('battle-undo'),'btn_undo');document.getElementById('battle-undo').onclick=e=>{e.stopPropagation();performBattleUndo()};
document.getElementById('country-failure-ok')?.addEventListener('click',e=>{e.stopPropagation();closeNativeCountryFailure()});
document.getElementById('battle-pause').onclick=openPausePanel;
document.getElementById('pause-close').onclick=hideBattleModals;
document.getElementById('roundturn-close').onclick=closeNativeRoundTurn;
document.getElementById('save-close').onclick=()=>{document.getElementById('save-panel').classList.remove('show');if(activeScreenId()==='battle')document.getElementById('pause-panel').classList.add('show');else document.getElementById('battle-modal-shade').classList.remove('show')};
document.getElementById('battle-modal-shade').onclick=hideBattleModals;
document.getElementById('pause-save').onclick=()=>openSavePanel('save');
document.getElementById('pause-restart').onclick=()=>{hideBattleModals();if(battleState)openBattle(battleState.battle,battleState.map,{mode:battleState.mode,playerOwner:battleState.playerOwner,assignments:new Map(battleState.assignments||[])})};
document.getElementById('pause-exit').onclick=()=>{const tut=battleState?.mode==='tutorial',dest=battleState?.mode==='conquest'?'conquest':tut?'tutorial':'campaignList';writeBattleSave('auto',true);hideBattleModals();if(tut)clearNativeTutorialRuntime();go(dest)};
document.getElementById('pause-option').onclick=()=>{optionsReturnScreen='battle';hideBattleModals();go('options')};
document.getElementById('campaign-load').onclick=()=>openSavePanel('load');document.getElementById('conquest-load').onclick=()=>openSavePanel('load');
document.getElementById('battle-back').addEventListener('click',()=>{writeBattleSave('auto',true);if(battleState?.mode==='tutorial')clearNativeTutorialRuntime()});
const academyBack=document.getElementById('academy-back');if(academyBack){academyBack.onclick=()=>{const d=academyReturnScreen||'deploy';academyReturnScreen='deploy';if(d==='deploy')renderDeployment();go(d)}}
const optionsBack=document.querySelector('#options .back');if(optionsBack){optionsBack.removeAttribute('data-go');optionsBack.onclick=()=>closeNativeOptions(true)}
document.getElementById('round-btn').onclick=()=>{if(!battleState||battleState.ended||battleState.dialogueActive)return;if(battleState.phase==='ai'){battleState.aiFastForward=true;flash('快进敌军行动',700);return}if(battleState.cameraPresentationPending||battleState.cameraMotion)return;if(performance.now()<(battleState.inputLockedUntil||0))return;selectUnit(null);battleState.undoUnitIndex=null;for(const u of battleState.units)u.undoState=null;syncBattleUndoButton();enemyTurn()};
function exitBattleResultToParent(){hideBattleResult();if(battleState?.mode==='conquest')go('conquest');else if(battleState?.mode==='tutorial'){clearNativeTutorialRuntime();go('tutorial')}else openZone(selectedZone)}
document.getElementById('battle-result-continue').onclick=()=>{if(battleState?.mode==='campaign'&&battleState?.ended==='victory')continueCampaignFromResult();else if(battleState?.mode==='conquest'&&battleState?.ended==='victory')continueConquestFromResult();else exitBattleResultToParent()};document.getElementById('battle-result-retry').onclick=()=>{if(battleState)openBattle(battleState.battle,battleState.map,{mode:battleState.mode,playerOwner:battleState.playerOwner,assignments:new Map(battleState.assignments||[])})};document.getElementById('battle-result-exit').onclick=exitBattleResultToParent;
const campaignCompleteOk=document.getElementById('campaign-complete-ok');if(campaignCompleteOk)campaignCompleteOk.onclick=()=>{hideCampaignComplete();go('main')};
document.getElementById('conquest-challenge-asia')?.addEventListener('click',()=>chooseConquestChallenge('asia'));document.getElementById('conquest-challenge-home')?.addEventListener('click',()=>chooseConquestChallenge('normal'));document.getElementById('conquest-complete-ok')?.addEventListener('click',()=>{hideConquestComplete();go('conquest')});

document.getElementById('native-talk').onclick=()=>{if(battleState?.dialogueActive)advanceNativeTalk()};

/* ---------- Gestures ---------- */
let pointers=new Map(),gesture={down:null,hadMultiTouch:false};
function pointerPair(){return[...pointers.values()]}
function battlePointerPoint(e){
  /* offsetX/offsetY under a transformed canvas has varied across WebKit builds.
     Resolve from the actual on-screen rect so taps/pinch stay registered to the
     recovered 568x320 map geometry regardless of CSS scale or HiDPI backing. */
  const r=canvas.getBoundingClientRect(),rw=Math.max(.001,r.width),rh=Math.max(.001,r.height);
  return{x:(e.clientX-r.left)*(BATTLE_LOGICAL_W/rw),y:(e.clientY-r.top)*(BATTLE_LOGICAL_H/rh)}
}
canvas.addEventListener('pointerdown',e=>{if(!battleState||battleState.dialogueActive||battleState.cameraPresentationPending||battleState.cameraMotion)return;if(music&&au?.paused)startBattleMusic();const pt=battlePointerPoint(e);canvas.setPointerCapture(e.pointerId);pointers.set(e.pointerId,pt);if(pointers.size===1){gesture.down={...pt};gesture.hadMultiTouch=false}else if(pointers.size===2){gesture.hadMultiTouch=true}});
canvas.addEventListener('pointermove',e=>{if(!pointers.has(e.pointerId)||!battleState)return;const previous=pointers.get(e.pointerId),current=battlePointerPoint(e);if(pointers.size===1&&gesture.down){const pose=EW4NativeCamera.panStep(battleState.camera,previous,current);pointers.set(e.pointerId,current);applyCameraPose(pose,EW4NativeCamera.PAN_EDGE_MARGIN);renderBattle()}else if(pointers.size===2){const otherEntry=[...pointers.entries()].find(([id])=>id!==e.pointerId),stationary=otherEntry?.[1];const step=EW4NativeCamera.pinchStep(battleState.camera,previous,current,stationary);pointers.set(e.pointerId,current);gesture.hadMultiTouch=true;if(step.applied){applyCameraPose(step.camera);renderBattle()}}else pointers.set(e.pointerId,current)});
canvas.addEventListener('pointerup',e=>{const wasSingle=pointers.size===1,start=gesture.down,end=battlePointerPoint(e),canTap=wasSingle&&!gesture.hadMultiTouch&&EW4NativeCamera.isNativeTap(start,end);if(canTap&&battleState)handleTap(end.x,end.y);pointers.delete(e.pointerId);if(pointers.size===1){const [p]=pointerPair();gesture.down={x:p.x,y:p.y};gesture.hadMultiTouch=true}else{gesture.down=null;gesture.hadMultiTouch=false}});function clearNativePointerGesture(pointerId=null){if(pointerId==null)pointers.clear();else pointers.delete(pointerId);if(!pointers.size){gesture.down=null;gesture.hadMultiTouch=false}else gesture.hadMultiTouch=true}canvas.addEventListener('pointercancel',e=>clearNativePointerGesture(e.pointerId));canvas.addEventListener('lostpointercapture',e=>clearNativePointerGesture(e.pointerId));addEventListener('blur',()=>clearNativePointerGesture());
canvas.addEventListener('wheel',e=>{if(!battleState)return;e.preventDefault();const p=battlePointerPoint(e);zoomCameraAt(battleState.camera.zoom*(e.deltaY<0?1.12:.89),p.x,p.y);renderBattle()},{passive:false});

const au=document.getElementById('battle-music'),defeatAudio=document.getElementById('defeat-music');
function chooseOriginalBattleMusic(){return ORIGINAL_BATTLE_MUSIC[Math.floor(Math.random()*ORIGINAL_BATTLE_MUSIC.length)]}
function setBattleMusicTrack(file){if(!au||!ORIGINAL_BATTLE_MUSIC.includes(file))return false;if(au.dataset.track===file)return true;pauseBattleMusic(true);au.dataset.track=file;au.src=`assets/audio/${file}`;try{au.load()}catch(e){}return true}
let optionDraft=null;
function beginNativeOptions(){
  optionDraft={bgVol:clampSettingPercent(saveState.bgVol),seVol:clampSettingPercent(saveState.seVol),gameSpeed:currentGameSpeed(),showGrids:showNativeGrid()};
  syncNativeOptionControls();
}
function syncNativeOptionAudio(){
  const src=optionDraft||saveState,bg=document.getElementById('option-bgvol'),se=document.getElementById('option-sevol'),bgt=document.getElementById('option-bg-value'),set=document.getElementById('option-se-value');
  if(bg)bg.value=clampSettingPercent(src.bgVol);if(se)se.value=clampSettingPercent(src.seVol);
  if(bgt)bgt.textContent=String(clampSettingPercent(src.bgVol));if(set)set.textContent=String(clampSettingPercent(src.seVol));
}
function syncNativeOptionControls(){
  syncNativeOptionAudio();const src=optionDraft||saveState,speed=Math.max(1,Math.min(5,+src.gameSpeed||2));
  document.querySelectorAll('.option-speed-brick').forEach(b=>{const n=+b.dataset.speed;b.classList.toggle('active',n<=speed);b.setAttribute('aria-pressed',n===speed?'true':'false')});
  const grid=document.getElementById('option-grid-toggle');if(grid){grid.classList.toggle('checked',!!src.showGrids);grid.setAttribute('aria-pressed',src.showGrids?'true':'false')}
}
function previewOptionVolumes(){
  if(!optionDraft)return;const bg=clampSettingPercent(optionDraft.bgVol)/100,se=clampSettingPercent(optionDraft.seVol)/100;
  if(au)au.volume=bg;if(defeatAudio)defeatAudio.volume=bg;for(const a of Object.values(audio))try{a.volume=se}catch(e){}
}
function setOptionDraftVolume(kind,v){if(!optionDraft)beginNativeOptions();optionDraft[kind]=clampSettingPercent(v);previewOptionVolumes();syncNativeOptionAudio()}
function setNativeGameSpeed(v){if(!optionDraft)beginNativeOptions();optionDraft.gameSpeed=Math.max(1,Math.min(5,Math.trunc(+v||2)));syncNativeOptionControls();playSfx('select')}
function toggleNativeGrid(){if(!optionDraft)beginNativeOptions();optionDraft.showGrids=!optionDraft.showGrids;syncNativeOptionControls();playSfx('select')}
function commitNativeOptions(){
  if(!optionDraft)beginNativeOptions();saveState.bgVol=clampSettingPercent(optionDraft.bgVol);saveState.seVol=clampSettingPercent(optionDraft.seVol);saveState.gameSpeed=Math.max(1,Math.min(5,+optionDraft.gameSpeed||2));saveState.showGrids=!!optionDraft.showGrids;music=saveState.bgVol>0;saveState.music=music;persist();optionDraft=null;
  if(au)au.volume=bgVolume();if(defeatAudio)defeatAudio.volume=bgVolume();for(const a of Object.values(audio))try{a.volume=seVolume()}catch(e){};closeNativeOptions(false)
}
function closeNativeOptions(cancel=true){
  if(cancel&&optionDraft){optionDraft=null;if(au)au.volume=bgVolume();if(defeatAudio)defeatAudio.volume=bgVolume();for(const a of Object.values(audio))try{a.volume=seVolume()}catch(e){}}
  const d=optionsReturnScreen;optionsReturnScreen='main';go(d);if(d==='battle')setTimeout(()=>{if(battleState&&!battleState.ended)openPausePanel()},0)
}
function setBackgroundVolume(v){saveState.bgVol=clampSettingPercent(v);music=saveState.bgVol>0;saveState.music=music;persist();if(au)au.volume=bgVolume();if(defeatAudio)defeatAudio.volume=bgVolume();if(!music){pauseBattleMusic(false);stopDefeatMusic()}syncNativeOptionControls()}
function setSoundVolume(v){saveState.seVol=clampSettingPercent(v);persist();for(const a of Object.values(audio))try{a.volume=seVolume()}catch(e){}syncNativeOptionControls()}
function pauseBattleMusic(reset=false){if(!au)return;try{au.pause();if(reset)au.currentTime=0}catch(e){}}
function stopDefeatMusic(){if(!defeatAudio)return;try{defeatAudio.pause();defeatAudio.currentTime=0}catch(e){}}
async function startBattleMusic(){if(!music||bgVolume()<=0||activeScreenId()!=='battle'||!battleState||battleState.ended)return false;stopDefeatMusic();setBattleMusicTrack(battleState.musicTrack||chooseOriginalBattleMusic());try{au.volume=bgVolume();await au.play();battleState.musicArmed=false;return true}catch(e){battleState.musicArmed=true;return false}}
const bgSlider=document.getElementById('option-bgvol'),seSlider=document.getElementById('option-sevol');
if(bgSlider)bgSlider.addEventListener('input',()=>setOptionDraftVolume('bgVol',bgSlider.value));
if(seSlider)seSlider.addEventListener('input',()=>setOptionDraftVolume('seVol',seSlider.value));
document.querySelectorAll('.option-speed-brick').forEach(b=>b.onclick=()=>setNativeGameSpeed(b.dataset.speed));
document.getElementById('option-grid-toggle')?.addEventListener('click',toggleNativeGrid);
document.getElementById('option-ok')?.addEventListener('click',commitNativeOptions);
document.getElementById('option-close')?.addEventListener('click',()=>closeNativeOptions(true));
syncNativeOptionControls();
if('serviceWorker'in navigator&&location.protocol.startsWith('http'))navigator.serviceWorker.register('./sw.js').catch(()=>{});
bootNativeApp();
