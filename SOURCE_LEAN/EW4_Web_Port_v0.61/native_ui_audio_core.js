'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4NativeUIAudio=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const FORM_OPEN_SFX=Object.freeze({
    form_generalinfo:'sfx_pop.wav',
    form_option:'sfx_pop.wav',
    form_save:'sfx_pop.wav',
    form_upgrade:'sfx_pop.wav',
    form_princess:'sfx_pop.wav',
    form_complete:'sfx_pop.wav',
    form_getgeneraltips:'sfx_lvup2.wav'
  });
  function formOpenSfx(formId){return FORM_OPEN_SFX[String(formId||'')]||null}
  function battleResultAudio(kind){
    if(kind==='victory')return Object.freeze({stopBattleMusic:true,bgm:null,sfx:'sfx_celebrate.wav'});
    if(kind==='defeat')return Object.freeze({stopBattleMusic:true,bgm:'defeat_music.mp3',sfx:null});
    return Object.freeze({stopBattleMusic:false,bgm:null,sfx:null});
  }
  return Object.freeze({FORM_OPEN_SFX,formOpenSfx,battleResultAudio});
});
