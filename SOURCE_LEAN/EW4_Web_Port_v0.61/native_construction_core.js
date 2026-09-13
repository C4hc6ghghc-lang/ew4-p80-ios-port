(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeConstruction=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const ICONS=Object.freeze({
    money:'marker_money.png',industry:'marker_industry.png',food:'marker_food.png',
    all:'marker_dfs_all.png',infantry:'marker_dfs_infantry.png',cavalry:'marker_dfs_cavalry.png',artillery:'marker_dfs_artillery.png'
  });
  const ORDER=Object.freeze(['money','industry','food','all','infantry','cavalry','artillery']);
  // Native x86_64 tables at .rodata 0x1b5e90 (Money) and 0x1b5e70 (Industry),
  // indexed only by construction type. Current construction level is not read, so every
  // step of a given construction type has the same upgrade price.
  const UPGRADE_COST=Object.freeze({
    city:Object.freeze({money:65,industry:0}),
    industry:Object.freeze({money:60,industry:20}),
    stable:Object.freeze({money:80,industry:5}),
    port:Object.freeze({money:75,industry:10}),
    farmland:Object.freeze({money:40,industry:0})
  });
  function n(v){v=Number(v);return Number.isFinite(v)?v:0}
  function upgradeCost(type,{architecture=false}={}){
    const base=UPGRADE_COST[String(type||'')];if(!base)return null;
    // Native helpers 0x54250 / 0x542e0 test skill 30 (Architecture) and calculate
    // trunc(base * 3 / 5) for both Money and Industry.
    const scale=architecture?3/5:1;
    return {money:Math.trunc(base.money*scale),industry:Math.trunc(base.industry*scale),discount:!!architecture};
  }
  // Native group_incom uses four display cells whose icon is selected dynamically from
  // money / industry / food / ALL / infantry / cavalry / artillery defense markers.
  function summaryEntries(values={}){
    const normalized={
      money:n(values.money??values.tax),industry:n(values.industry),food:n(values.food),all:n(values.all??values.avoid),
      infantry:n(values.infantry??values.penalty_infantry),cavalry:n(values.cavalry??values.penalty_cavalry),artillery:n(values.artillery??values.penalty_artillery)
    };
    return ORDER.filter(k=>normalized[k]!==0).slice(0,4).map(k=>({kind:k,value:normalized[k],icon:ICONS[k]}));
  }
  // Native defense selector takes construction avoidance directly when a construction is
  // present. Only cells without a construction fall back to max(terrain, field-work).
  function mapAvoidance({hasConstruction=false,constructionAvoid=0,terrainAvoid=0,installationAvoid=0}={}){
    if(hasConstruction)return Math.max(0,n(constructionAvoid));
    return Math.max(0,n(terrainAvoid),n(installationAvoid));
  }
  return Object.freeze({ICONS,ORDER,UPGRADE_COST,upgradeCost,summaryEntries,mapAvoidance});
});
