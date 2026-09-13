'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4NativeActionAudio=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const ACTION_SFX=Object.freeze({
    recruit:'sfx_draft.wav',
    occupy:'sfx_occupy.wav',
    buildInstallation:'sfx_build.wav',
    upgradeConstruction:'sfx_build1.wav',
    training:'sfx_buff.wav',
    supply:'sfx_supply.wav'
  });
  function actionSfx(action){return ACTION_SFX[String(action||'')]||null}
  function movementSfx(unit,army){
    if(!unit)return null;
    const name=String(unit.army_name||army?.name||'');
    const type=String(army?.type||unit.type||'').toLowerCase();
    // Native movement controller: naval branch first; Armored Car is a cavalry special case;
    // remaining cavalry uses cavalrymove, other movable land units use leg.
    if(unit.embarked||type==='warship')return 'sfx_naval.wav';
    if(name==='Armored Car')return 'sfx_armourmove.wav';
    if(type==='cavalry')return 'sfx_cavalrymove.wav';
    if(type==='infantry'||type==='artillery')return 'sfx_leg.wav';
    return null;
  }
  return Object.freeze({ACTION_SFX,actionSfx,movementSfx});
});
