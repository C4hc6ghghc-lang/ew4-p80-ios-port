'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const Native=require('./native_ui_audio_core.js');
const root=__dirname;
const layout=fs.readFileSync(path.join(root,'assets/data/original_layout-568h.xml'),'utf8');
for(const [form,sfx] of Object.entries({form_generalinfo:'sfx_pop.wav',form_option:'sfx_pop.wav',form_save:'sfx_pop.wav',form_upgrade:'sfx_pop.wav',form_princess:'sfx_pop.wav',form_complete:'sfx_pop.wav',form_getgeneraltips:'sfx_lvup2.wav'})){
  const re=new RegExp(`<Layout id="${form}"[^>]*sound="${sfx.replace('.','\\.')}"`);
  assert(re.test(layout),`${form} sound must match original layout`);
  assert.strictEqual(Native.formOpenSfx(form),sfx);
}
assert.deepStrictEqual({...Native.battleResultAudio('victory')},{stopBattleMusic:true,bgm:null,sfx:'sfx_celebrate.wav'});
assert.deepStrictEqual({...Native.battleResultAudio('defeat')},{stopBattleMusic:true,bgm:'defeat_music.mp3',sfx:null});
for(const f of ['sfx_celebrate.wav','defeat_music.mp3','sfx_pop.wav','sfx_lvup2.wav'])assert(fs.existsSync(path.join(root,'assets/audio',f)),`${f} missing`);
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
assert(app.includes("playNativeFormOpenSfx('form_save')"));
assert(app.includes("playNativeFormOpenSfx('form_option')"));
assert(app.includes("playNativeFormOpenSfx('form_generalinfo')"));
assert(app.includes("EW4NativeUIAudio?.battleResultAudio?.('defeat')"));
assert(app.includes("playNativeSfxFile('sfx_celebrate.wav')"));
console.log('native UI/result audio tests passed');
