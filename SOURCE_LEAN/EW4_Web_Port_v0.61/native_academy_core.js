(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.EW4NativeAcademy=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';

  // Original SceneGetGeneral / academy generator (native 0x5E4C0):
  // tier 0 => 6 candidates, star 1..3
  // tier 1 => 4 candidates, star 4..6
  // tier 2 => 2 candidates, star 7..9
  const TIER_CONFIG=Object.freeze({
    '6':Object.freeze({key:'6',nativeIndex:0,count:6,minStar:1,maxStar:3}),
    '4':Object.freeze({key:'4',nativeIndex:1,count:4,minStar:4,maxStar:6}),
    '2':Object.freeze({key:'2',nativeIndex:2,count:2,minStar:7,maxStar:9})
  });
  const TIER_ORDER=Object.freeze(['6','4','2']);
  // Original SceneGetGeneral slot record is {commanderId, medalPrice, badgePrice}.
  // Native 0x5E4C0 copies commander.price into medalPrice and derives the
  // badge alternative from a star table at .rodata 0x1B60C0. The table for
  // the APK's actual 1..8-star roster is: 0,0,0,3,3,4,6,8.
  const BADGE_PRICE_BY_STAR=Object.freeze([0,0,0,0,3,3,4,6,8]);

  function config(key){return TIER_CONFIG[String(key)]||TIER_CONFIG['6']}

  function medalPrice(commander){
    const n=Number(commander?.price);
    return Number.isFinite(n)&&n>0?Math.trunc(n):0;
  }
  function badgePrice(commander){
    const star=Math.trunc(Number(commander?.star)||0);
    return star>=0&&star<BADGE_PRICE_BY_STAR.length?BADGE_PRICE_BY_STAR[star]:0;
  }
  function prices(commander){return Object.freeze({medal:medalPrice(commander),badge:badgePrice(commander)})}
  function canUseCurrency(commander,currency){
    return currency==='medal'?medalPrice(commander)>0:currency==='badge'?badgePrice(commander)>0:false;
  }
  function emptyPools(){return{'6':[],'4':[],'2':[]}}
  function commanderValues(commanders){return Array.isArray(commanders)?commanders:Object.values(commanders||{})}
  function cleanId(v){const n=Number(v);return Number.isInteger(n)&&n>0?n:null}
  function normalizePools(raw){
    const out=emptyPools();
    for(const key of TIER_ORDER){
      const cfg=config(key),arr=Array.isArray(raw?.[key])?raw[key]:[];
      // Preserve null/-1 holes: native purchase 0x5E890 clears only the bought
      // record's commander id and the fixed 6/4/2 list positions remain.
      out[key]=arr.slice(0,cfg.count).map(cleanId);
    }
    return out;
  }
  function allCandidateIds(pools){
    const out=new Set();
    const p=normalizePools(pools);
    for(const key of TIER_ORDER)for(const id of p[key])out.add(id);
    return out;
  }
  function structurallyValid(pools,commanders){
    const p=normalizePools(pools),byId=new Map(commanderValues(commanders).map(c=>[+c.id,c])),seen=new Set();
    for(const key of TIER_ORDER){
      const cfg=config(key);
      if(p[key].length!==cfg.count)return false;
      for(const id of p[key]){
        if(id==null)continue;
        if(seen.has(id))return false;
        const c=byId.get(id);
        if(!c||!Number(c.drawlots))return false;
        const star=Number(c.star)||0;
        if(star<cfg.minStar||star>cfg.maxStar)return false;
        seen.add(id);
      }
    }
    return true;
  }
  function eligible(commanders,cfg,ownedIds,excludedIds){
    const owned=ownedIds instanceof Set?ownedIds:new Set((ownedIds||[]).map(Number));
    const excluded=excludedIds instanceof Set?excludedIds:new Set((excludedIds||[]).map(Number));
    return commanderValues(commanders).filter(c=>{
      const id=+c.id,star=+c.star||0;
      return id>0&&Number(c.drawlots)!==0&&!owned.has(id)&&!excluded.has(id)&&star>=cfg.minStar&&star<=cfg.maxStar;
    });
  }
  function randomIndex(length,rng){
    if(length<=0)return -1;
    let r=Number((rng||Math.random)());
    if(!Number.isFinite(r))r=0;
    // Native helper is rand()%count. A JS RNG normally returns [0,1); clamp
    // defensively so deterministic tests cannot select past the last item.
    r=Math.max(0,Math.min(0.9999999999999999,r));
    return Math.floor(r*length);
  }
  function refreshTier({commanders,owned=[],pools={},tier='6',rng=Math.random}={}){
    const key=String(tier),cfg=config(key),next=normalizePools(pools);
    // Native 0x5E4C0 builds into a separate six-record staging block and only
    // copies it over the selected tier at the end. Eligibility check 0x5E2B0
    // therefore still sees *all* old displayed candidates, including the tier
    // being refreshed, while also seeing each newly staged pick. Mirror that:
    // one refresh cannot immediately redraw a commander currently on screen.
    const excluded=allCandidateIds(next),picked=[];
    for(let slot=0;slot<cfg.count;slot++){
      const pool=eligible(commanders,cfg,owned,excluded);
      if(!pool.length)break;
      const c=pool[randomIndex(pool.length,rng)];
      const id=+c.id;picked.push(id);excluded.add(id);
    }
    next[key]=picked;
    return next;
  }
  function initializePools({commanders,owned=[],rng=Math.random}={}){
    let pools=emptyPools();
    // Native new-HQ path calls 0x5E4C0 in tier order 0,1,2. Because already
    // generated tiers are visible to the duplicate filter, all 12 candidates
    // are unique across the page's three persistent tier stores.
    for(const key of TIER_ORDER)pools=refreshTier({commanders,owned,pools,tier:key,rng});
    return pools;
  }
  function ensurePools({commanders,owned=[],pools,rng=Math.random}={}){
    return structurallyValid(pools,commanders)?normalizePools(pools):initializePools({commanders,owned,rng});
  }
  function clearCandidate(pools,tier,commanderId){
    const next=normalizePools(pools),key=String(tier),id=+commanderId;
    next[key]=(next[key]||[]).map(v=>v===id?null:v);
    return next;
  }

  return Object.freeze({TIER_CONFIG,TIER_ORDER,BADGE_PRICE_BY_STAR,config,medalPrice,badgePrice,prices,canUseCurrency,emptyPools,normalizePools,allCandidateIds,structurallyValid,eligible,refreshTier,initializePools,ensurePools,clearCandidate});
});
