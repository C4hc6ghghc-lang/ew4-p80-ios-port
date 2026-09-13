'use strict';
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.EW4NativeMapText=api})(typeof self!=='undefined'?self:globalThis,function(){
  function attrs(text){const out={};const re=/([A-Za-z_][\w:-]*)="([^"]*)"/g;let m;while((m=re.exec(text)))out[m[1]]=m[2];return out}
  function parsePlacements(xml){
    const root=(xml.match(/<Elements\b([^>]*)>/)||[])[1]||'',decl=+(attrs(root).numelements||0),out=[];const re=/<Element\b([^>]*)\/?\s*>/g;let m;
    while((m=re.exec(xml))){const a=attrs(m[1]);out.push({index:+a.index,libName:a.libName||'',alpha:(+a.colorAlphaPercent||0)/100,tx:+a.tx,ty:+a.ty,left:+a.left,top:+a.top,width:+a.width,height:+a.height})}
    if(decl&&decl!==out.length)throw new Error(`maptext element count ${out.length} != ${decl}`);return out
  }
  function placementTransform(bile,placement){
    const itemIndex=bile?.nameToItem?.[placement.libName];if(itemIndex==null)throw new Error(`maptext item missing: ${placement.libName}`);
    const raw=bile.bounds(bile.flatten(itemIndex,0)),rw=raw[2]-raw[0],rh=raw[3]-raw[1];if(!(rw>0&&rh>0))throw new Error(`maptext empty bounds: ${placement.libName}`);
    const scaleX=placement.width/rw,scaleY=placement.height/rh,originX=placement.left-raw[0]*scaleX,originY=placement.top-raw[1]*scaleY;
    return{itemIndex,rawBounds:raw,scaleX,scaleY,originX,originY,alpha:placement.alpha}
  }
  function preparePlacement(bile,placement){return{...placement,...placementTransform(bile,placement)}}
  function preparePlacements(bile,placements){return placements.map(p=>preparePlacement(bile,p))}
  function intersects(p,b){return p.left+p.width>=b.left&&p.left<=b.right&&p.top+p.height>=b.top&&p.top<=b.bottom}
  function drawPrepared(ctx,bile,atlas,p){return bile.drawFrameXY(ctx,p.itemIndex,0,atlas,p.originX,p.originY,p.scaleX,p.scaleY,p.alpha)}
  function drawPlacement(ctx,bile,atlas,placement){return drawPrepared(ctx,bile,atlas,preparePlacement(bile,placement))}
  return{parsePlacements,placementTransform,preparePlacement,preparePlacements,intersects,drawPrepared,drawPlacement}
});
