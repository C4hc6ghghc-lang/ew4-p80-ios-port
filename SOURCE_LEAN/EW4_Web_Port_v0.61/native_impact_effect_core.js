'use strict';
/* EW4 native impact/strike timeline selector.
 * Reconstructed from libeuropean-war-4.so x86_64 0x81950 and its caller 0x59b80..0x59f26.
 * Native weapon enum follows def_army weapon order: gun=0, guns=1, mgun=2, cannon=3, rocket=4, cold=5.
 * Native target type enum: infantry=0,cavalry=1,artillery=2,warship=3,fort=4.
 */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.EW4NativeImpactEffect=api})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const TYPE_CODE=Object.freeze({infantry:0,cavalry:1,artillery:2,warship:3,fort:4});
  const WEAPON_CODE=Object.freeze({gun:0,guns:1,mgun:2,cannon:3,rocket:4,cold:5});
  const STRIKE=Object.freeze(['strike1','strike2','strike3','strike4']);
  const SEA_STRIKE=Object.freeze(['seastrike1','seastrike2','seastrike3','seastrike4']);
  const BODY=Object.freeze(['bodystrike1 right','bodystrike2 right','bodystrike1 left','bodystrike2 left']);
  const WOOD=Object.freeze(['woodstrike1 right','woodstrike2 right','woodstrike1 left','woodstrike2 left']);
  const STONE=Object.freeze(['stonestrike1 right','stonestrike2 right','stonestrike1 left','stonestrike2 left']);
  const COLD=Object.freeze(['coldstrike1','coldstrike2']);
  const COLD_STONE=Object.freeze(['coldstonestrike1','coldstonestrike2']);
  function damageTier(value){value=Math.trunc(+value||0);return value<=10?0:value<=25?1:value<41?2:3}
  function typeCode(type){return Object.prototype.hasOwnProperty.call(TYPE_CODE,type)?TYPE_CODE[type]:0}
  function weaponCode(weapon){return Object.prototype.hasOwnProperty.call(WEAPON_CODE,weapon)?WEAPON_CODE[weapon]:3}
  function directionalIndex(tier,dx){return (tier>>1)+(dx<0?2:0)}
  function resolveTimeline({attackerArmyId=-1,weapon='cannon',targetType='infantry',targetSea=false,damage=1,dx=1}={}){
    if(+attackerArmyId===13)return'rocketstrike';
    const w=weaponCode(weapon),t=typeCode(targetType),tier=damageTier(damage);
    if(w===0||w===2){const i=directionalIndex(tier,+dx||0);return(t===4?STONE:t===3?WOOD:BODY)[i]}
    if(w===5){const i=tier>>1;return(t===3||t===4?COLD_STONE:COLD)[i]}
    if(w===1){if(t===3||t===4)return STRIKE[tier];return BODY[directionalIndex(tier,+dx||0)]}
    return(targetSea?SEA_STRIKE:STRIKE)[tier]
  }
  return{TYPE_CODE,WEAPON_CODE,damageTier,resolveTimeline};
});
