'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const html=fs.readFileSync('index.html','utf8'),app=fs.readFileSync('app.js','utf8');
const sprites=JSON.parse(fs.readFileSync('assets/sprite_manifest.json','utf8'));
const items=JSON.parse(fs.readFileSync('assets/data/items.json','utf8'));
// StageIntro: exact 360x219 geometry remains centered and the empty native user-window
// title still leaves the native 28px chrome/header band.
assert(html.includes('#stageintro-panel{position:absolute;left:104px;top:50px;width:360px;height:219px'));
assert(html.includes('#stageintro-panel::before{content:"";position:absolute;left:0;right:0;top:0;height:28px'));
assert(html.includes('.stageintro-condition .num{position:absolute;left:0;top:30px;width:180px;text-align:center'));
// HD pattern is 63x36 -> 31.5x18 logical on 568x320 canvas; allow 32px CSS box for half-pixel raster width.
assert.deepStrictEqual([sprites['pattern_stage_intro.png'].w,sprites['pattern_stage_intro.png'].h],[63,36]);
assert(html.includes("#stageintro-flower{position:absolute;left:164px;top:195px;width:32px;height:18px;background:url('assets/sprites/image_ui_hd/pattern_stage_intro.png') center/31.5px 18px no-repeat}"));
// form_talk x=10 to content x=88 implies 78 logical px portrait; mirrored content is 17px from left.
assert(html.includes('#native-talk .talk-portrait{position:absolute;left:10px;top:7px;width:78px;height:78px'));
assert(html.includes('#native-talk.right .talk-content{left:17px}'));
assert.deepStrictEqual([sprites['gray_board_dialoguearrow.png'].w,sprites['gray_board_dialoguearrow.png'].h],[15,14]);
assert(html.includes("#native-talk .talk-next{position:absolute;right:7px;bottom:5px;width:8px;height:7px;background:url('assets/sprites/image_ui_hd/gray_board_dialoguearrow.png') center/7.5px 7px no-repeat"));
// Transport selection is explicit and single-sourced: function 12 is the original Armored Carrier item family.
const armored=Object.values(items).filter(x=>+x.function===12);
assert(armored.length>=1&&armored.every(x=>x.name==='Armored Carrier'));
assert(app.includes("function nativeTransportProfile(u){const armored=hasEquipmentFunction(u,12);return{key:armored?'transportship2.png':'transportship1.png',naturalFacing:armored?'left':'right',armored}}"));
assert.deepStrictEqual([sprites['transportship1.png'].refx,sprites['transportship1.png'].refy],[70,107]);
assert.deepStrictEqual([sprites['transportship2.png'].refx,sprites['transportship2.png'].refy],[94,119]);
// Area names are world-scaled at low zoom instead of being pinned to a Web-only 6px screen-space floor.
assert(app.includes("ctx.font=`${7*c.zoom}px sans-serif`"));
assert(app.includes('ctx.lineWidth=2*c.zoom'));
assert(!app.includes('Math.max(6,7*c.zoom)'));
// Protected save core must remain untouched.
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
assert.strictEqual(sha('battle_save_core.js'),'4858c7f862dac736d3624b8e64567af1484382b63bd8482aa544cd3204272dc2');
console.log('P34 final visual closure contracts PASS');
