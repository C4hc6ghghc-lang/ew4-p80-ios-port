'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4NativeMovementEffect=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  // Native x86_64 @ 0x511e0..0x512e3:
  // sea/embarked branch first -> effect_moving4; otherwise unit type enum
  // 0 infantry -> moving1, 1 cavalry -> moving2, remaining movable land type
  // (artillery in the original battle path) -> moving3.
  function effectForMovement(unit,army){
    if(!unit)return null;
    const type=String(army?.type||unit.type||'').toLowerCase();
    if(unit.embarked||type==='warship')return 'effect_moving4';
    if(type==='infantry')return 'effect_moving1';
    if(type==='cavalry')return 'effect_moving2';
    if(type==='artillery')return 'effect_moving3';
    return null;
  }
  return Object.freeze({effectForMovement});
});
