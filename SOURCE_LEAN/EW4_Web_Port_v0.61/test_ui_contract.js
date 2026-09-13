'use strict';
const fs=require('fs'),assert=require('assert');
const h=fs.readFileSync('index.html','utf8'),a=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
for(const id of ['battle-pause','pause-panel','save-panel','save-grid','campaign-load','conquest-load'])assert(h.includes(`id="${id}"`),id);
assert(h.includes('battle_save_core.js'));
assert(h.includes('country_turn_core.js'));
assert(h.includes('item_inventory_core.js'));
assert(sw.includes('./item_inventory_core.js'));
assert(a.includes('itemInventory'));
assert(a.includes('EW4ItemInventory.changeSlot'));
assert(!a.includes('function equipmentPool()'));

assert(a.includes('EW4CountryTurn.aiTurnOrder'));
assert(a.includes('countryResources'));
assert(sw.includes('./country_turn_core.js'));
assert(sw.includes('ew4-port-v061-r14')); 
assert(!/id="battle-pause"[^>]*data-go="main"/.test(h));
for(const x of ['openPausePanel','writeBattleSave','loadBattleSave','nativeStageTurnLimits'])assert(a.includes(x),x);
for(const x of ['./battle_save_core.js','./assets/effects/anim_fire_hd.png','./assets/audio/sfx_fire.wav'])assert(sw.includes(x),x);
console.log('ui/runtime contract PASS: pause save/load fire turn-limits country-turn-ledger r14');

assert(h.includes('campaign-stage-caption'), 'campaign stage caption missing');
assert(h.includes('id="intro-portrait"'), 'campaign intro portrait missing');
assert(a.includes('campaignIntroCommander'), 'campaign original-style intro commander logic missing');
assert(a.includes('最高评价'), 'campaign native 5-grade result status missing');
