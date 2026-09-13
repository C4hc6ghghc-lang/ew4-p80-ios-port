'use strict';
const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
assert(app.includes('let continueBattlePendingZone=0;'));
assert(/continueBattlePendingZone=decision\.continueBattle>0\?zone:0;go\('main'\)/.test(app));
assert(/if\(id==='main'&&continueBattlePendingZone>0\)/.test(app));
assert(!/go\('main'\);if\(decision\.continueBattle>0\)requestAnimationFrame\(\(\)=>openZone\(zone\)\)/.test(app));
for(const asset of [
  './assets/sprites/image_ui_hd/board_victory.png',
  './assets/effects/anim_upgrade/anim_upgrade.bin','./assets/effects/anim_upgrade/anim_upgrade.xml','./assets/effects/anim_upgrade/anim_upgrade.png',
  './assets/textures/campaignend_fr.png','./assets/textures/campaignend_coalitiont.png','./assets/textures/campaignend_holyroma.png','./assets/textures/campaignend_east.png','./assets/textures/campaignend_us.png','./assets/textures/campaignend_gb.png'
]) assert(sw.includes(asset),`missing SW precache: ${asset}`);
console.log('P16 integration PASS: ContinueBattle SceneMain handoff + offline result assets');
