'use strict';
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.EW4NativeCampaign=api})(typeof globalThis!=='undefined'?globalThis:this,function(){
  function canonicalFile(battle){return String(battle?.meta?.paired_from||battle?.file||'')}
  function originalHide(battle){return +battle?.meta?.hide===1?1:0}
  function stageNumber(file){const m=String(file||'').match(/^campaign([1-6])_(\d+)/);return m?{zone:+m[1],stage:+m[2]}:null}
  function buildOpenStates(rows,progressFn){
    const list=Array.isArray(rows)?rows:[],states=new Array(list.length).fill(0);if(list.length)states[0]=1;
    const done=i=>Math.max(0,+progressFn?.(canonicalFile(list[i]))||0)>0;
    for(let i=0;i<list.length;i++){
      if(!done(i))continue;let j=i+1;
      while(j<list.length&&originalHide(list[j])){states[j]=Math.max(states[j],1);j++}
      if(j<list.length)states[j]=Math.max(states[j],1);
    }
    return states;
  }
  function effectiveHide(battle,secretUnlocked){return originalHide(battle)&&!secretUnlocked?.(canonicalFile(battle))?1:0}
  function stageSelectable(rows,index,progressFn,secretUnlocked){
    const list=Array.isArray(rows)?rows:[];if(index<0||index>=list.length)return false;
    const states=buildOpenStates(list,progressFn);return states[index]>effectiveHide(list[index],secretUnlocked);
  }
  function selectableCountryCodes(battle){return String(battle?.meta?.countries||'').split(',').map(s=>s.trim()).filter(Boolean)}
  function resolveVariant(baseBattle,countryCode,battles){
    if(!baseBattle)return null;const codes=selectableCountryCodes(baseBattle),code=String(countryCode||'').trim();
    if(codes.length<2||!code)return{battle:baseBattle,playerCode:baseBattle?.countries?.[baseBattle.player_owner_default??0]?.code||code,variant:false};
    if(code===codes[0])return{battle:baseBattle,playerCode:code,variant:false};
    if(code===codes[1]&&baseBattle?.meta?.file2){const alt=(battles||[]).find(b=>b?.file===baseBattle.meta.file2);if(alt)return{battle:alt,playerCode:code,variant:true}}
    return null;
  }

  /* P17 native target source of truth.
     The APK battle loader restores map-state record byte 10 -> runtime map cell +0x18,
     and unit-state record byte 19 -> runtime unit +0x54.  The generated manifest is
     parsed directly from the original BTL corpus; do not infer objectives from the
     legacy Web parser's shifted raw[] arrays. */
  function battleSpec(manifest,battle){return manifest?.battles?.[String(battle?.file||battle||'')]||null}
  function countrySide(spec,owner){
    const n=+owner;if(!Number.isFinite(n)||n<0||n===255)return 0;
    const row=(spec?.countries||[]).find(c=>+c.owner===n);return row?Math.trunc(+row.side||0):0;
  }
  function campaignRelation(spec,a,b){
    a=+a;b=+b;if(a===b)return'ally';if(!Number.isFinite(a)||!Number.isFinite(b)||a===255||b===255)return'neutral';
    const sa=countrySide(spec,a),sb=countrySide(spec,b);if(!sa||!sb)return'neutral';if(sa===sb)return'ally';
    if(sa===4||sb===4)return'neutral';
    if((sa===1&&sb===2)||(sa===2&&sb===1))return'hostile';
    if((sa===3&&(sb===1||sb===2))||(sb===3&&(sa===1||sa===2)))return'hostile';
    return'neutral';
  }
  function ownerClass(spec,owner,playerOwner){
    if(+owner===+playerOwner)return'friendly';const r=campaignRelation(spec,playerOwner,owner);return r==='ally'?'friendly':r==='hostile'?'hostile':'neutral';
  }
  function unitByNativeIndex(state,index){return(state?.units||[]).find(u=>+u.index===+index)||null}
  function mapEntityAt(state,q,r){return(state?.objects||[]).find(o=>+o.q===+q&&+o.r===+r)||null}
  function targetEntities(state,manifest,type,ownerAt){
    const spec=battleSpec(manifest,state?.battle),t=Math.trunc(+type||0),out=[];if(!spec||!t)return out;
    const getOwner=typeof ownerAt==='function'?ownerAt:()=>255;
    for(const rec of spec.unit_targets||[]){if(+rec.type!==t)continue;const u=unitByNativeIndex(state,rec.unit_index);if(!u||u.dead)continue;const owner=+u.owner;out.push({kind:'unit',entity:u,type:t,owner,side:countrySide(spec,owner),status:ownerClass(spec,owner,state?.playerOwner),q:+u.q,r:+u.r,unitIndex:+rec.unit_index,pos:+rec.pos})}
    for(const rec of spec.map_targets||[]){if(+rec.type!==t)continue;const owner=+getOwner(+rec.q,+rec.r);out.push({kind:'map',entity:mapEntityAt(state,+rec.q,+rec.r),type:t,owner,side:countrySide(spec,owner),status:ownerClass(spec,owner,state?.playerOwner),q:+rec.q,r:+rec.r,recordIndex:+rec.record_index,pos:+rec.pos})}
    return out;
  }
  function targetCounts(state,manifest,type,ownerAt){
    const out={friendly:0,hostile:0,neutral:0,total:0};for(const x of targetEntities(state,manifest,type,ownerAt)){out[x.status]=(out[x.status]||0)+1;out.total++}return out;
  }
  function initialTargetSnapshot(initialState,manifest,ownerAt){return{type1:targetCounts(initialState,manifest,1,ownerAt),type2:targetCounts(initialState,manifest,2,ownerAt)}}
  function mainObjectiveOutcome(state,manifest,initial,ownerAt,playerAlive=true,hostileAlive=true){
    const before=initial?.type1||{friendly:0,hostile:0,neutral:0,total:0},now=targetCounts(state,manifest,1,ownerAt);
    if(before.friendly>0&&now.friendly===0)return{kind:'defeat',reason:'objective',initial:before,current:now};
    if(before.hostile>0&&now.hostile===0)return{kind:'victory',reason:'objective',initial:before,current:now};
    if(before.friendly===0&&!playerAlive)return{kind:'defeat',reason:'annihilated',initial:before,current:now};
    if(before.hostile===0&&!hostileAlive)return{kind:'victory',reason:'annihilated',initial:before,current:now};
    return null;
  }
  function yellowSecretCleared(state,manifest,ownerAt){
    const spec=battleSpec(manifest,state?.battle);if(!spec)return false;
    const total=(spec.map_targets||[]).filter(x=>+x.type===2).length+(spec.unit_targets||[]).filter(x=>+x.type===2).length;if(!total)return false;
    return targetCounts(state,manifest,2,ownerAt).hostile===0;
  }
  function followingHidden(rows,currentFile){
    const list=Array.isArray(rows)?rows:[],canon=String(currentFile||''),idx=list.findIndex(b=>canonicalFile(b)===canon||b?.file===canon);if(idx<0)return[];
    const out=[];for(let i=idx+1;i<list.length&&originalHide(list[i]);i++)out.push(list[i]);return out;
  }
  function hiddenUnlockFiles(rows,currentBattle,playerCode,yellowCleared){
    if(!yellowCleared||originalHide(currentBattle))return[];const current=canonicalFile(currentBattle),followers=followingHidden(rows,current);if(!followers.length)return[];
    const branch=selectableCountryCodes(currentBattle);if(branch.length){const code=String(playerCode||'');const matched=followers.filter(b=>selectableCountryCodes(b).includes(code));return matched.length?matched.map(canonicalFile):[]}
    return[canonicalFile(followers[0])];
  }
  function hasTargets(manifest,battle,type){const spec=battleSpec(manifest,battle),t=+type;return !!spec&&[...(spec.map_targets||[]),...(spec.unit_targets||[])].some(x=>+x.type===t)}
  return{canonicalFile,originalHide,stageNumber,buildOpenStates,effectiveHide,stageSelectable,selectableCountryCodes,resolveVariant,battleSpec,countrySide,campaignRelation,ownerClass,targetEntities,targetCounts,initialTargetSnapshot,mainObjectiveOutcome,yellowSecretCleared,followingHidden,hiddenUnlockFiles,hasTargets};
});
