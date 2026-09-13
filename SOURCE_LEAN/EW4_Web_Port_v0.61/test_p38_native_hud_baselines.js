'use strict';
const fs=require('fs'),assert=require('assert');
const css=fs.readFileSync('r14_native_forms.css','utf8');
const xml=fs.readFileSync('assets/data/original_layout-568h.xml','utf8');
const sw=fs.readFileSync('sw.js','utf8');

// Native evidence: group_incom second-row markers are y=26 while text is y=30.
assert(/id="image_icon_2"[^>]*x="2" y="26"/.test(xml));
assert(/id="text_value_2"[^>]*x="20" y="30"/.test(xml));
assert(/id="image_icon_4"[^>]*x="48" y="26"/.test(xml));
assert(/id="text_value_4"[^>]*x="67" y="30"/.test(xml));
assert(css.includes('#facility-summary .facility-summary-cell.slot2 span,\n#facility-summary .facility-summary-cell.slot4 span{\n  top:4px!important;'));

// Native btn_done geometry is 33x33; its bitmap must fill the same control box.
assert(/id="btn_done"[^>]*x="33" y="55" w="33" h="33"/.test(xml));
assert(css.includes('#native-funcres-confirm{\n  background-size:33px 33px!important;'));

// Native AI action text box is 40x23 at x=44,y=7; keep the height instead of Web-shortening it.
assert(/id="text_playing"[^>]*x="44" y="7" w="40" h="23"/.test(xml));
assert(css.includes('#native-ai-action-text{\n  height:23px!important;'));

// Frozen P35/P36/P37 invariants must remain present.
assert(css.includes('#battle-pause{left:541px!important;top:0!important;width:37px!important;height:37px!important'));
assert(css.includes('#battle-undo{left:0!important;top:293px!important;width:37px!important;height:37px!important'));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_resources.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_buttons.png')!important"));
assert(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_terrain_info.png')!important"));
assert(sw.includes('p36-native-hud-p37-deweb-p38-baselines'));
console.log('PASS test_p38_native_hud_baselines');
