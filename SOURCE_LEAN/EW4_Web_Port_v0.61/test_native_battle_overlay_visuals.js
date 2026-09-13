'use strict';
const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8');
const sprites=JSON.parse(fs.readFileSync('assets/sprite_manifest.json','utf8'));
assert(app.includes('SPRITES?.[`${cc.name}.png`]'),'battle commander must use commandermark sprite by commander native name');
assert(app.includes("bm=SPRITES?.['board_smallgenerals.png']"),'battle commander must use native board_smallgenerals bubble');
assert(/const k=\.5\*uz/.test(app),'battle overlays must render HD atlases at 0.5 native logical scale');
assert(app.includes('p.x-m.refx*k,p.y-m.refy*k,m.w*k,m.h*k'),'transport ships must use native refx/refy at 0.5 scale');
assert(!app.includes('const k=.58*uz'),'guessed transport 0.58 scale must be removed');
assert(!/ctx\.clip\(\);ctx\.drawImage\(pi/.test(app),'large commander portrait must not be CSS/canvas circle-cropped on battlefield');

assert(app.includes('function drawNativeUnitFlag'),'battle units must render native flagpole + animated nation cloth');
assert(app.includes("SPRITES?.['flagpole.png']"),'battle flag must use native flagpole sprite');
assert(app.includes('Math.floor(now/120)'),'battle flag must animate through native four-frame cloth sequence');
assert(app.includes('const k=.5*uz,rel=relationOwner'),'tactical status HD assets must use native 0.5 logical scale');
assert(app.includes('`mark_unit_${id}.png`'),'tactical status must include original white unit-class marker');

for(const k of ['Napoleon.png','Davout.png','Lannes.png','Murat.png','Massena.png','Suchet.png','Soult.png','board_smallgenerals.png','hpbar_green.png','hpbar_blue.png','hpbar_red.png','hpbar_black.png','hpbar_hp.png'])assert(sprites[k],`missing native overlay sprite ${k}`);
console.log('P32 native battle overlay visuals PASS');
