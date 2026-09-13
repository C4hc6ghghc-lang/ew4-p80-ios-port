'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeEvent=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  function moraleForAction(action){
    action=+action;
    if(action===0)return 1;
    if(action===1)return -1;
    if(action===2)return -2;
    if(action===3)return -3;
    return null;
  }
  function isRoundMoraleEvent(e,round){
    return !!e&&+e.trigger_type===2&&moraleForAction(e.param_a)!==null&&+e.param_b===+round&&!!e.country;
  }
  function eventMoraleActive(unit,round){
    if(!unit)return false;
    const until=+unit.nativeMoraleUntilRound||0;
    return until>+round;
  }
  function eventMoraleBase(unit,round){
    return eventMoraleActive(unit,round)?Math.max(-3,Math.min(1,+unit.nativeMoraleBase||0)):0;
  }
  function combinedMorale(eventBase,flankPenalty,leadership){
    let m=(+eventBase||0)+(+flankPenalty||0);
    m=Math.max(-3,Math.min(1,m));
    if(leadership&&m<0)m=0;
    return m;
  }
  function applyCountryMorale(units,countryCode,action,round,codeForOwner){
    const base=moraleForAction(action);
    if(base===null)return 0;
    let n=0;
    for(const u of units||[]){
      if(!u||u.dead)continue;
      if(codeForOwner(u.owner)!==countryCode)continue;
      u.nativeMoraleBase=base;
      // Native timer is 3. Event on N is active through N, N+1, N+2.
      u.nativeMoraleUntilRound=(+round||1)+3;
      n++;
    }
    return n;
  }
  return{moraleForAction,isRoundMoraleEvent,eventMoraleActive,eventMoraleBase,combinedMorale,applyCountryMorale};
});
