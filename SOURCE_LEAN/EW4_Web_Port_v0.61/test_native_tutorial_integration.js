'use strict';
const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),sw=fs.readFileSync('sw.js','utf8');
const scripts=JSON.parse(fs.readFileSync('assets/data/native_tutorial_scripts.json','utf8'));
const all=Object.values(scripts.scripts).flatMap(x=>x.commands);
assert.equal(all.length,273,'must preserve all original tutorial commands');
assert(html.indexOf('native_tutorial_core.js')<html.indexOf('app.js'),'tutorial runner must load before app');
for(const token of ['NATIVE_TUTORIAL_SCRIPTS','startNativeTutorialForBattle','tutorialNotifyArea','tutorialNotifyUI','tutorialNotifyAction','positionNativeTutorialHighlight'])assert(app.includes(token),`missing tutorial integration ${token}`);
for(const token of ['selectedCell','performBattleUndo','openNativeDefensePanel','buildFortressAt','promptEmbarkUnit'])assert(app.includes(token),`tutorial-exposed battle controller missing ${token}`);
for(const token of ['tutorial-runtime-overlay','tutorial-runtime-text','tutorial-runtime-highlight','battle-undo','defense-panel'])assert(html.includes(token),`tutorial runtime UI missing ${token}`);
const waitUIs=[...new Set(all.filter(c=>c.name==='wait ui').map(c=>c.string))];
for(const name of waitUIs){if(/^btn_buy_[123]$/.test(name)){const literalAliases=['btn_buy_1','btn_buy_2','btn_buy_3','btn_buy_4'];assert(app.includes('bindTutorialUI(b,`btn_buy_${i+1}`)')||literalAliases.every(x=>app.includes(`'${x}'`)),`wait-ui alias not represented: ${name}`);continue}assert(app.includes(`'${name}'`)||app.includes(`\`${name}\``)||app.includes(name),`wait-ui alias not represented: ${name}`)}
assert(app.includes("o.construction_type==='industry'?['button_factory'"),'original factory recruit action must not reuse city icon/controller');
assert(app.includes("if(selected===i)selectedGrade=Math.min(+cap.grade||0,selectedGrade+1)"),'repeated recruit-card taps must raise formation up to original building cap');
assert(app.includes("bindTutorialUI(b,'lbox_unit',i)"),'recruit list rows must be tutorial-addressable');
assert(app.includes("bindTutorialUI(b,'lbox_defense',i)"),'defense rows must be tutorial-addressable');
assert(app.includes("bindTutorialUI(ok,'winbtn_ok')"),'native confirm must resolve tutorial wait-ui');

assert(/if\(mode==='tutorial'\)setTimeout\([\s\S]{0,220}startNativeTutorialForBattle\(\)/.test(app),'tutorial battle must auto-start the original script runner');
for(const bridge of [
  /function resolvePlayerMove[\s\S]{0,1200}tutorialNotifyAction\(moveMs\+30\)/,
  /function resolvePlayerAttack[\s\S]{0,1800}tutorialNotifyAction\(Math\.max\(80,actionMs\+30\)\)/,
  /function performBattleUndo[\s\S]{0,1200}tutorialNotifyAction\(moveMs\+30\)/,
  /function manualTrainUnit[\s\S]{0,1400}tutorialNotifyAction\(\)/
])assert(bridge.test(app),'wait-action bridge missing from a tutorial-critical real battle action');
assert(app.includes("requestAnimationFrame(()=>{if(nativeTutorialHighlight===ref)positionNativeTutorialHighlight()})"),'dynamic tutorial UI must re-position highlight after the clicked controller opens its panel');


assert(app.includes("if(c.w!=null)r.w=Math.max(8,r.w+(+c.w||0))")&&app.includes("if(c.h!=null)r.h=Math.max(8,r.h+(+c.h||0))"),'draw-ui-rect must preserve original XML w/h rect adjustments');
const battles=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8')).battles;
const strings=JSON.parse(fs.readFileSync('assets/data/strings_cn.json','utf8'));
for(const [file,script] of Object.entries(scripts.scripts)){
  const battle=battles.find(x=>x.file===file);assert(battle,`tutorial battle missing: ${file}`);const h=battle.header;
  for(const c of script.commands){
    if(c.name==='show text')assert(strings[`desc_tutorials_word_${c.id}`],`${file}: missing tutorial text ${c.id}`);
    if(c.id!=null&&['moveto area','wait area','draw rect','sel area','unsel area'].includes(c.name)){const q=c.id%79,r=Math.floor(c.id/79);assert(q>=h.origin_x&&q<h.origin_x+h.width&&r>=h.origin_y&&r<h.origin_y+h.height,`${file}: area ${c.id} outside original battle rect`)}
  }
  const runner=new (require('./native_tutorial_core.js').Runner)();runner.start(script.commands);let guard=0;while(!runner.done&&guard++<500){const w=runner.wait;assert(w,`${file}: script stalled without a wait at pc ${runner.pc}`);if(w.type==='touch')runner.notifyTouch();else if(w.type==='area')runner.notifyArea(w.id);else if(w.type==='ui')runner.notifyUI(w.string,w.row);else if(w.type==='action')runner.notifyAction();else assert.fail(`${file}: unknown wait ${w.type}`)}assert(runner.done,`${file}: scripted wait sequence did not reach exit`);
}

assert(/posthandoff(?:1[6-9]|[2-9][0-9])-/.test(sw),'service worker cache must be P16 or newer');
for(const file of ['./native_tutorial_core.js','./assets/data/native_tutorial_scripts.json','./assets/data/tutorials_script1.xml','./assets/data/tutorials_script2.xml','./assets/sprites/image_ui_hd/tutorials_point.png'])assert(sw.includes(file),`offline cache missing ${file}`);
console.log(`native tutorial integration PASS: ${all.length}/273 commands wired · ${waitUIs.length} wait-ui aliases · undo/fortress/defense/ship/recruit formation controllers present`);
