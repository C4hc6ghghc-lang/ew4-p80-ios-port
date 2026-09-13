'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const app=fs.readFileSync('app.js','utf8');
const html=fs.readFileSync('index.html','utf8');
const css=fs.readFileSync('r14_native_forms.css','utf8');
const xml=fs.readFileSync('assets/data/original_layout-568h.xml','utf8');
const sw=fs.readFileSync('sw.js','utf8');

// 1) Frozen logical space + HiDPI backing. Do not resize the game world to chase sharpness.
assert(app.includes('const BATTLE_LOGICAL_W=568,BATTLE_LOGICAL_H=320,MAX_BATTLE_BACKING_SCALE=4'));
assert(html.includes('#stage{position:absolute;left:50%;top:50%;width:568px;height:320px;transform-origin:center center;overflow:hidden;background:#151a18}'));
assert(html.includes('#battle-canvas{position:absolute;inset:0;width:568px;height:320px;touch-action:none}'));
assert(app.includes('ctx.setTransform(battleBackingScale,0,0,battleBackingScale,0,0)'));
assert(app.includes("ctx.imageSmoothingQuality='high'"));

// 2) Frozen transformed pointer inversion. WebKit offsetX/offsetY must not return.
assert(app.includes('function battlePointerPoint(e)'));
assert(app.includes('(e.clientX-r.left)*(BATTLE_LOGICAL_W/rw)'));
assert(app.includes('(e.clientY-r.top)*(BATTLE_LOGICAL_H/rh)'));
const gestures=app.slice(app.indexOf('/* ---------- Gestures ---------- */'),app.indexOf('const au=document.getElementById'));
assert(!gestures.includes('e.offsetX')&&!gestures.includes('e.offsetY'));

// 3) Frozen unit presentation scale/native-anchor route. Never enlarge units as a blur workaround.
assert(app.includes('function unitVisualZoom(z=battleState?.camera?.zoom||1){return Math.max(.76,Math.min(1.18,Math.pow(z,.46)))}'));
assert(app.includes('scale=.5*uz'));
assert(app.includes('const k=.5*uz'));
assert(app.includes('EW4NativeAnimation.compactDrawOrigin(unit,p,uz)'));
assert(app.includes('function unitScreenPoint(u){const p=unitDisplayWorldPoint(u),c=battleState.camera;return{x:(p.x-c.x)*c.zoom+284,y:(p.y-c.y)*c.zoom+160}}'));

// 4) Native form_game button/HUD geometry remains authoritative.
for(const sig of [
  'id="btn_pause" type="button" frm1="button_pause.png" x="541" y="0" w="37" h="37"',
  'id="btn_undo" type="button" frm1="button_return.png" x="0" y="293" w="37" h="37"',
  'id="btn_next" type="button" frm1="button_round.png" x="541" y="293" w="37" h="37"',
  'id="group_func" type="groupbox" x="140" y="309" w="270" h="11"',
  'id="group_incom" type="groupbox" x="0" y="31" w="110" h="48"',
  'id="group_aiaction" type="groupbox" x="506" y="298" w="137" h="22"'
]) assert(xml.includes(sig),sig);
assert(css.includes('#battle-pause{left:541px!important;top:0!important;width:37px!important;height:37px!important'));
assert(css.includes('#battle-undo{left:0!important;top:293px!important;width:37px!important;height:37px!important'));
assert(css.includes('#round-btn{left:541px!important;top:293px!important;width:37px!important;height:37px!important'));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_resources.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_buttons.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_terrain_info.png')!important"));

// 5) Explicit anti-Web processing on frozen battlefield layers/native HUD artwork.
assert(css.includes('/* P39 NOON-REGRESSION LOCK'));
assert(css.includes('#battle-map,\n#battle-canvas{\n  transform:none!important;\n  filter:none!important;\n  opacity:1!important;'));
assert(css.includes('#battle-canvas{\n  image-rendering:auto!important;'));
assert(css.includes('#battle .hud-icon{\n  filter:none!important;\n  opacity:1!important;'));
assert(css.includes('#battle-actions .battle-action-btn{\n  filter:none!important;\n  transform:none!important;'));
assert(sw.includes('p36-native-hud-p37-deweb-p38-baselines-p39-safety-lock'));
assert(sw.includes("'./r14_native_forms.css'"));

console.log('PASS test_p39_noon_regression_lock: frozen map/unit/touch/HUD invariants guarded');
