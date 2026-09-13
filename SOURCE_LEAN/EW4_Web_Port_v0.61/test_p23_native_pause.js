
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const root=__dirname,app=fs.readFileSync(path.join(root,'app.js'),'utf8'),html=fs.readFileSync(path.join(root,'index.html'),'utf8'),sw=fs.readFileSync(path.join(root,'sw.js'),'utf8'),layout=fs.readFileSync(path.join(root,'assets/data/original_layout-568h.xml'),'utf8');
assert(/<Layout id="form_pause"[^>]*w="166" h="272"/.test(layout));
for(const x of ['id="text_turnword" type="text" font="font_text_3" text="text_round_word" x="50" y="35"','id="text_turnnums" type="text" font="font_char_2" text="1" x="85" y="36" w="35" h="15"','id="btn_save" type="tmp_button" frm1="btn_common_blue.png" x="42" y="65" w="83" h="35"','id="btn_option" type="tmp_button" frm1="btn_common_blue.png" x="42" y="115" w="83" h="35"','id="btn_restart" type="tmp_button" frm1="btn_common_blue.png" x="42" y="165" w="83" h="35"','id="btn_exit" type="tmp_button" frm1="btn_common_blue.png" x="42" y="215" w="83" h="35"','name="pattern_reoganizion.png" y="270" align="hmiddle" vscale="-1"']) assert(layout.includes(x),x);
for(const id of ['pause-panel','pause-round','pause-save','pause-option','pause-restart','pause-exit']) assert(html.includes(`id="${id}"`),id);
assert(html.includes('class="pause-turn-word">回合</span>'));
assert(html.includes('class="pause-flower"'));
assert(html.includes('.pause-turn-word{position:absolute;left:50px;top:35px'));
assert(html.includes('.pause-turn-num{position:absolute;left:85px;top:36px;width:35px;height:15px'));
assert(html.includes('.pause-flower{position:absolute;left:44.5px;top:249px;width:77px;height:23px'));
for(const pair of [['pause-save','top:65px'],['pause-option','top:115px'],['pause-restart','top:165px'],['pause-exit','top:215px']]) assert(new RegExp(`id="${pair[0]}"[^>]*style="${pair[1]}"`).test(html),pair[0]);
assert(app.includes("document.getElementById('pause-round').textContent=String(battleState.round)"));
assert(sw.includes('pattern_reoganizion.png'));
assert(sw.includes("const CACHE='ew4-port-v061-r14-39-"));
console.log('P23 native form_pause: PASS');
