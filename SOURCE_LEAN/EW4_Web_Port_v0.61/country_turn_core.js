'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4CountryTurn=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const SENTINEL=0xffffffff;
  function cleanResource(v,fallback=0){
    v=Number(v);
    if(!Number.isFinite(v)||v<0||v===SENTINEL||v>10000000)return Math.max(0,Number(fallback)||0);
    return Math.floor(v);
  }
  function headerResources(battle){
    const raw=battle?.header?.raw||[];
    return{money:cleanResource(raw[18],800),industry:cleanResource(raw[19],300),food:cleanResource(raw[20],500)};
  }
  function countryResources(country,fallback={money:0,industry:0,food:0}){
    const raw=country?.raw_u32_36_180||[];
    // High-confidence BTL country economy triplet. Keep this decoder isolated until native names are confirmed.
    return{
      money:cleanResource(raw[30],fallback.money),
      industry:cleanResource(raw[31],fallback.industry),
      food:cleanResource(raw[32],fallback.food)
    };
  }
  function buildLedgers(battle,{mode='campaign',playerOwner=0,restored=null}={}){
    if(restored&&typeof restored==='object'){
      const out={};
      for(const [k,v] of Object.entries(restored))out[String(+k)]={money:cleanResource(v?.money),industry:cleanResource(v?.industry),food:cleanResource(v?.food)};
      return out;
    }
    const h=headerResources(battle),out={};
    for(const c of battle?.countries||[])out[String(c.index)]=countryResources(c,{money:0,industry:0,food:h.food});
    // Campaign/tutorial headers carry the stage-specific player treasury used by the current port.
    // Conquest instead uses each selected country's own BTL country record.
    if(mode!=='conquest')out[String(+playerOwner)]={...h};
    return out;
  }
  function hint(battle,owner){
    if(owner==null||+owner===255)return 4;
    const g=battle?.relation_groups?.[String(+owner)];
    if(g!==undefined&&g!==null)return +g;
    const c=battle?.countries?.[+owner];
    return c?.relation_hint==null?null:+c.relation_hint;
  }
  function relation(battle,a,b,{mode='campaign',playerOwner=0}={}){
    a=+a;b=+b;playerOwner=+playerOwner;
    if(a===b)return'ally';
    if(a===255||b===255)return'neutral';
    if(mode!=='conquest'){
      // Campaign relation_hint is NOT a conquest alliance group. Preserve the recovered 0.61
      // player-centric hostility model while preventing separate enemy countries from fighting each other.
      if(a===playerOwner||b===playerOwner)return'hostile';
      return'ally';
    }
    const ha=hint(battle,a),hb=hint(battle,b);
    if(ha===4||hb===4)return'neutral';
    if((ha===1||ha===2)&&(hb===1||hb===2))return ha===hb?'ally':'hostile';
    // Some decoded final conquest country records still have an unresolved relation byte. Preserve old runtime behavior conservatively.
    return'hostile';
  }
  function livingOwners(units){return new Set((units||[]).filter(u=>!u.dead).map(u=>+u.owner).filter(x=>x!==255));}
  function aiTurnOrder(battle,units,playerOwner,mode='campaign'){
    const live=livingOwners(units),out=[];
    for(const c of battle?.countries||[]){
      const owner=+c.index;if(owner===+playerOwner||!live.has(owner))continue;
      if(mode==='conquest'&&hint(battle,owner)===4)continue;
      out.push(owner);
    }
    // Preserve any decoded owner not represented in countries[] rather than dropping its units.
    for(const owner of live)if(owner!==+playerOwner&&!out.includes(owner)&&(mode!=='conquest'||hint(battle,owner)!==4))out.push(owner);
    return out;
  }
  return{cleanResource,headerResources,countryResources,buildLedgers,hint,relation,livingOwners,aiTurnOrder};
});
