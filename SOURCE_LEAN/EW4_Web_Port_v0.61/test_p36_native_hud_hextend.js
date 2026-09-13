const fs=require('fs');
const path=require('path');
const ROOT=__dirname;
const css=fs.readFileSync(path.join(ROOT,'r14_native_forms.css'),'utf8');
const xml=fs.readFileSync(path.join(ROOT,'assets/data/original_layout-568h.xml'),'utf8');
function ok(cond,msg){if(!cond){throw new Error(msg)}}

// Authoritative native evidence exists.
ok(/id="btn_undo"[^>]*x="0" y="293" w="37" h="37"/.test(xml),'native btn_undo geometry missing');
ok(/name="board_buttons\.png" DrawMode="hextend"/.test(xml),'board_buttons hextend evidence missing');
ok(/name="board_resources\.png" w="165" DrawMode="hextend"/.test(xml),'board_resources hextend evidence missing');
ok(/name="board_terrain_info\.png" w="110" DrawMode="hextend"/.test(xml),'board_terrain_info hextend evidence missing');
ok(/name="marker_money\.png" x="3" y="3"/.test(xml) && /id="text_money"[^>]*x="21" y="0"/.test(xml),'money anchors missing');
ok(/name="marker_industry\.png" x="53" y="3"/.test(xml) && /id="text_industry"[^>]*x="70" y="0"/.test(xml),'industry anchors missing');
ok(/name="marker_food\.png" x="103" y="3"/.test(xml) && /id="text_food"[^>]*x="125" y="0"/.test(xml),'food anchors missing');

// P36 CSS must preserve the native geometry and extension semantics.
ok(css.includes('#battle-undo{left:0!important;top:293px!important;width:37px!important;height:37px!important;background-size:37px 37px!important'),'P36 undo geometry missing');
ok(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_resources.png')!important"),'resource-board hextend renderer missing');
ok(css.includes('border-image-slice:0 15 0 0 fill!important'),'resource-board cap preservation missing');
ok(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_buttons.png')!important"),'battle-actions hextend renderer missing');
ok(css.includes('border-image-slice:0 19 0 20 fill!important'),'battle-actions cap preservation missing');
ok(css.includes("border-image-source:url('assets/sprites/image_ui_hd/board_terrain_info.png')!important"),'facility-summary hextend renderer missing');
ok(css.includes('border-image-slice:0 32 0 0 fill!important'),'terrain-info cap preservation missing');
ok(css.includes('.hud .res:nth-of-type(2){left:3px!important;width:48px!important}'),'money icon anchor missing');
ok(css.includes('.hud .res:nth-of-type(3){left:53px!important;width:48px!important}'),'industry icon anchor missing');
ok(css.includes('.hud .res:nth-of-type(4){left:103px!important;width:61px!important}'),'food icon anchor missing');
ok(css.includes('.hud .res:nth-of-type(2) span{left:18px!important}') && css.includes('.hud .res:nth-of-type(3) span{left:17px!important}') && css.includes('.hud .res:nth-of-type(4) span{left:22px!important}'),'resource text offsets missing');
ok(css.includes('.hud .res img{width:20px!important;height:20px!important;top:3px!important}'),'native HD resource marker scale missing');
ok(css.includes('#facility-summary .facility-summary-cell.slot1{left:2px!important;top:3px!important}') && css.includes('#facility-summary .facility-summary-cell.slot2{left:2px!important;top:26px!important}') && css.includes('#facility-summary .facility-summary-cell.slot3{left:48px!important;top:3px!important}') && css.includes('#facility-summary .facility-summary-cell.slot4{left:48px!important;top:26px!important}'),'terrain info icon anchors missing');
ok(css.includes('#facility-summary .facility-summary-cell img{position:absolute!important;left:0!important;top:0!important;width:20px!important;height:20px!important'),'terrain info marker scale missing');


ok(css.includes('#battle-back{display:none!important}'),'legacy persistent battle back must stay hidden');
ok(xml.includes('id="group_aiaction"') && xml.includes('name="board_aiaction.png"') && xml.includes('x="506" y="298" w="137" h="22"'),'native AI action evidence missing');
ok(css.includes('#native-ai-action{position:absolute;left:506px;top:298px;width:137px;height:22px'),'native AI action geometry missing');
const app=fs.readFileSync(path.join(ROOT,'app.js'),'utf8');
const html=fs.readFileSync(path.join(ROOT,'index.html'),'utf8');
ok(html.includes('id="native-ai-action"') && html.includes('id="native-ai-action-flag"'),'native AI action DOM missing');
ok(app.includes('function setNativeAIAction(') && app.includes('setNativeAIAction(owner,true)'),'native AI action controller missing');


const sw=fs.readFileSync(path.join(ROOT,'sw.js'),'utf8');
ok(sw.includes('posthandoff49-p35-native-presentation-p36-native-hud'),'P36 cache generation missing');
for(const asset of ['board_resources.png','board_buttons.png','board_terrain_info.png','board_aiaction.png']) ok(sw.includes(`./assets/sprites/image_ui_hd/${asset}`),`P36 offline HUD asset missing ${asset}`);

console.log('PASS test_p36_native_hud_hextend');
