'use strict';
const fs=require('fs'),assert=require('assert');
const css=fs.readFileSync('r14_native_forms.css','utf8');
const html=fs.readFileSync('index.html','utf8');
const sw=fs.readFileSync('sw.js','utf8');
const xml=fs.readFileSync('assets/data/original_layout-568h.xml','utf8');

// Geometry remains frozen to native form_game evidence.
assert(/id="btn_pause"[^>]*x="541" y="0" w="37" h="37"/.test(xml));
assert(/id="btn_undo"[^>]*x="0" y="293" w="37" h="37"/.test(xml));
assert(/id="btn_next"[^>]*x="541" y="293" w="37" h="37"/.test(xml));
assert(css.includes('#battle-pause{left:541px!important;top:0!important;width:37px!important;height:37px!important'));
assert(css.includes('#battle-undo{left:0!important;top:293px!important;width:37px!important;height:37px!important'));
assert(css.includes('#round-btn{left:541px!important;top:293px!important;width:37px!important;height:37px!important'));

// Browser-added Web effects must not reprocess native battle HUD artwork.
assert(css.includes('#battle .hud-icon{\n  filter:none!important;\n  opacity:1!important;'));
assert(css.includes('#battle .hud-icon:active{\n  transform:none!important;'));
assert(css.includes('#battle-actions .battle-action-btn{\n  filter:none!important;\n  transform:none!important;'));
assert(css.includes('#battle-actions .battle-action-btn:active{\n  transform:none!important;'));
assert(css.includes('#battle-actions .battle-action-btn:disabled{\n  filter:grayscale(.45)!important;'));
assert(css.includes('.hud .res{\n  text-shadow:none!important;'));
assert(css.includes('#native-ai-action{\n  text-shadow:none!important;'));

// group_funcres keeps the original asymmetric second-row baseline instead of a shared Web row baseline.
assert(/id="image_apply"[^>]*x="15" y="29"/.test(xml));
assert(/id="text_needapply"[^>]*x="32" y="28"/.test(xml));
assert(css.includes('.native-funcres-row span{\n  text-shadow:none!important;'));
assert(css.includes('.native-funcres-row.row-secondary{\n  left:15px!important;\n  top:28px!important;'));
assert(css.includes('.native-funcres-row.row-secondary img{\n  top:1px!important;'));
assert(css.includes('.native-funcres-row.row-secondary span{\n  left:17px!important;'));

// P36 anchor/hextend rules remain present; P37 is not allowed to move them.
assert(css.includes('.hud .res:nth-of-type(2){left:3px!important;width:48px!important}'));
assert(css.includes('.hud .res:nth-of-type(3){left:53px!important;width:48px!important}'));
assert(css.includes('.hud .res:nth-of-type(4){left:103px!important;width:61px!important}'));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_resources.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_buttons.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_terrain_info.png')!important"));
assert(html.includes('id="native-ai-action"'));
assert(sw.includes('p36-native-hud-p37-deweb'));
console.log('PASS test_p37_native_hud_deweb');
