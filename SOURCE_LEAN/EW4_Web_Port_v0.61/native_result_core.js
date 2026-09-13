'use strict';
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.EW4NativeResult=api})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const MEDAL_TABLE=Object.freeze([0,0,5,15,25,50]);
  // libeuropean-war-4.so SceneComplete constructor: [medal,badge,score] by Warzone 0..5.
  const CAMPAIGN_COMPLETE_REWARDS=Object.freeze([
    Object.freeze([0,1,1]),Object.freeze([50,0,1]),Object.freeze([50,0,1]),
    Object.freeze([0,1,1]),Object.freeze([50,0,1]),Object.freeze([0,1,1])
  ]);
  const CAMPAIGN_COMPLETE_IMAGES=Object.freeze(['campaignend_fr.png','campaignend_coalitiont.png','campaignend_holyroma.png','campaignend_east.png','campaignend_us.png','campaignend_gb.png']);
  function stageTurnLimits(battle){
    const raw=battle?.header?.raw||[];const win=+raw[12],best=+raw[13];
    const valid=Number.isFinite(win)&&Number.isFinite(best)&&win>0&&best>0&&win>=best;
    return valid?{valid:true,win,best}:{valid:false,win:0,best:0};
  }
  // Native C++ @ libeuropean-war-4.so 0x7e6f0:
  // score 5 = best, 1 = worst; the visible description grade is 6-score.
  function victoryScore(round,battleOrLimits){
    const lim=battleOrLimits?.valid!==undefined?battleOrLimits:stageTurnLimits(battleOrLimits);
    const turn=Math.max(0,Math.trunc(+round||0));if(!lim.valid||turn<=0)return 0;
    if(turn<=lim.best)return 5;if(turn>=lim.win)return 1;
    const span=lim.win-lim.best;if(span<=0)return 5;
    return Math.max(2,Math.trunc(((lim.win-turn)*4)/span)+1);
  }
  function victoryGrade(round,battleOrLimits){const score=victoryScore(round,battleOrLimits);return score?6-score:0}
  function cumulativeMedalForScore(score){score=Math.max(0,Math.min(5,Math.trunc(+score||0)));return MEDAL_TABLE[score]||0}
  // Original campaign award is the positive delta between the new native score and the saved best score.
  function medalGain(score,previousBestScore=0){return Math.max(0,cumulativeMedalForScore(score)-cumulativeMedalForScore(previousBestScore))}
  function descriptionKey(score,awardMedal=0){
    score=Math.max(1,Math.min(5,Math.trunc(+score||1)));const grade=6-score;
    // Grade 5 has no "no award" localization because its normal text already says there is no reward.
    return grade===5||(+awardMedal||0)>0?`desc_victory ${grade}`:`desc_victory ${grade} no award`;
  }
  function result(round,battle,previousBestScore=0){
    const limits=stageTurnLimits(battle),score=victoryScore(round,limits),grade=score?6-score:0;
    return{limits,score,grade,awardMedal:medalGain(score,previousBestScore),cumulativeMedal:cumulativeMedalForScore(score),descriptionKey:score?descriptionKey(score,medalGain(score,previousBestScore)):''};
  }
  function participatingGeneralIds(units,playerOwner,slots=6){
    const out=[],seen=new Set();for(const u of Array.isArray(units)?units:[]){
      if(!u||+u.owner!==+playerOwner||u.commander_id==null)continue;const id=Math.trunc(+u.commander_id);if(!Number.isFinite(id)||id<=0||seen.has(id))continue;
      seen.add(id);out.push(id);if(out.length>=slots)break;
    }return out;
  }
  function isHiddenBattle(b){return +b?.meta?.hide===1}
  // SceneVictory btn_continue @ 0x4a980. Completion is keyed to the last non-hidden battle.
  // Otherwise ContinueBattle is 0 only for the final physical entry, 1 for any earlier entry.
  function campaignContinueDecision(rows,currentFile){
    const list=Array.isArray(rows)?rows:[],idx=list.findIndex(b=>b?.file===currentFile),lastVisible=(()=>{for(let i=list.length-1;i>=0;i--)if(!isHiddenBattle(list[i]))return i;return-1})();
    if(idx<0)return{valid:false,complete:false,continueBattle:0,index:-1,lastVisible};
    if(idx===lastVisible)return{valid:true,complete:true,continueBattle:0,index:idx,lastVisible};
    return{valid:true,complete:false,continueBattle:idx===list.length-1?0:1,index:idx,lastVisible};
  }
  function campaignCompletionReward(zone,alreadyCompleted=false){
    const i=Math.max(0,Math.min(5,Math.trunc(+zone||1)-1)),base=CAMPAIGN_COMPLETE_REWARDS[i]||[0,0,0];
    return{zone:i+1,medal:alreadyCompleted?0:base[0],badge:alreadyCompleted?0:base[1],score:alreadyCompleted?0:base[2],image:CAMPAIGN_COMPLETE_IMAGES[i],firstTime:!alreadyCompleted};
  }
  // Native random battle medal proc @ 0xaa7b0. `nativeType/nativeLevel` are the original
  // attached Resource metadata; callers must not guess a mapping when that metadata is absent.
  function collectMedalAdjustedRoll(roll,nativeType=255,nativeLevel=0){
    let r=Math.max(0,Math.min(99,Math.trunc(+roll||0))),lv=Math.max(0,Math.trunc(+nativeLevel||0)),t=Math.trunc(+nativeType);
    if(t===0||t===3)r+=2*lv;else if(t===1)r+=3*lv;return r;
  }
  function collectMedalProc(damage,roll,nativeType=255,nativeLevel=0){
    const d=Math.trunc(+damage||0),r=collectMedalAdjustedRoll(roll,nativeType,nativeLevel);
    if(d>=20&&d<=24)return r>95;if(d>=25&&d<=29)return r>91;if(d>=30&&d<=34)return r>87;if(d>=35)return r>82;return false;
  }
  return{MEDAL_TABLE,CAMPAIGN_COMPLETE_REWARDS,CAMPAIGN_COMPLETE_IMAGES,stageTurnLimits,victoryScore,victoryGrade,cumulativeMedalForScore,medalGain,descriptionKey,result,participatingGeneralIds,isHiddenBattle,campaignContinueDecision,campaignCompletionReward,collectMedalAdjustedRoll,collectMedalProc};
});
