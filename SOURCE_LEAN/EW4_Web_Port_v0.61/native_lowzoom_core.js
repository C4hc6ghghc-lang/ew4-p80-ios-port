(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeLowZoom=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const HP_START_RAD=2.9845130443573;       // native 171 degrees
  const HP_FULL_SWEEP_RAD=3.455751993850178; // native 198 degrees
  const HP_INNER_RADIUS=10*1.4199999570846558; // native c6c20 parameter path
  // hpbar_hp.png alpha occupies roughly radius 14..20 around its ref point.
  // A 6px butt-cap stroke centered between those radii reproduces that native strip.
  const HP_STROKE_RADIUS=(13.92838827718412+20.396078054371138)/2;
  const HP_STROKE_WIDTH=20.396078054371138-13.92838827718412;

  function clamp01(v){v=+v;return Number.isFinite(v)?Math.max(0,Math.min(1,v)):0}
  function relationSprite(rel){
    // Original strategic overview convention: own=green, ally=blue,
    // hostile=red, neutral=black. This also matches the four native resources
    // stored consecutively after mark_unit_0..21.
    if(rel==='player'||rel==='own')return'hpbar_green.png';
    if(rel==='ally'||rel==='friend')return'hpbar_blue.png';
    if(rel==='hostile'||rel==='enemy')return'hpbar_red.png';
    return'hpbar_black.png';
  }
  function hpColorRGB(ratio){
    // Exact integer piecewise color recovered from native 0x5f050.
    // Native packed color is ABGR: low HP red -> half HP yellow ->
    // full HP spring-green (#00ff80), not a guessed Web gradient.
    const r=clamp01(ratio);
    if(r<=.5){
      const q=Math.trunc(255*(1-2*r));
      return{r:255,g:255-q,b:0};
    }
    const q=Math.trunc(255*(2*r-1));
    const red=255-q;
    return{r:red,g:255,b:128-Math.trunc(red/2)};
  }
  function hpColorCss(ratio,alpha=1){const c=hpColorRGB(ratio);return`rgba(${c.r},${c.g},${c.b},${clamp01(alpha)})`}
  function hpArc(ratio){
    const r=clamp01(ratio);
    return{start:HP_START_RAD,sweep:HP_FULL_SWEEP_RAD*r,end:HP_START_RAD+HP_FULL_SWEEP_RAD*r,radius:HP_STROKE_RADIUS,width:HP_STROKE_WIDTH,color:hpColorRGB(r)};
  }
  return{HP_START_RAD,HP_FULL_SWEEP_RAD,HP_INNER_RADIUS,HP_STROKE_RADIUS,HP_STROKE_WIDTH,clamp01,relationSprite,hpColorRGB,hpColorCss,hpArc};
});
