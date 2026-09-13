'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4NativeHex=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  const GEOMETRY_ID='native-odd-r-64x54-v1';
  const COL_STEP=64,ROW_STEP=54,HALF_W=32,HALF_H=36,CENTER_Y_OFFSET=-18,CORNER_H=18;
  const trunc=v=>Math.trunc(v);
  const truncDiv=(a,b)=>Math.trunc(a/b);
  function cellCenter(q,r){q=trunc(q);r=trunc(r);return{x:q*COL_STEP+((r&1)?HALF_W:0),y:r*ROW_STEP+CENTER_Y_OFFSET}}
  function cellRect(q,r){const c=cellCenter(q,r);return{x:c.x-HALF_W,y:c.y-HALF_H,w:COL_STEP,h:HALF_H*2}}
  // Exact x86_64 CEntityMap world->cell partition recovered from libeuropean-war-4.so:0x84be0.
  function worldToCell(wx,wy){
    const ix=trunc(Number(wx)+HALF_W),iy=trunc(Number(wy)+ROW_STEP);
    let r=truncDiv(iy,ROW_STEP),q,baseX;
    if(r&1){q=truncDiv(ix-HALF_W,COL_STEP);baseX=q*COL_STEP+HALF_W}
    else{q=truncDiv(ix,COL_STEP);baseX=q*COL_STEP}
    const dy=iy-r*ROW_STEP;
    if(dy<CORNER_H){
      const hx=ix-baseX,threshold=COL_STEP*(CORNER_H-dy);
      if(hx<HALF_W){
        if(36*hx<threshold){if(!(r&1))q--;r--}
      }else{
        if(36*(COL_STEP-hx)<threshold){if(r&1)q++;r--}
      }
    }
    return{q,r};
  }
  function battlePixelOrigin(h){const ox=trunc(h?.origin_x||0),oy=trunc(h?.origin_y||0);return{x:ox*COL_STEP-((oy&1)?0:HALF_W),y:(oy-1)*ROW_STEP}}
  // Fallback only when no player focus cell exists. New-battle native camera does NOT use def_battlelist centerx/centery.
  function battleRectCenter(h){
    const p=battlePixelOrigin(h),w=Math.max(1,trunc(h?.width||1)),hh=Math.max(1,trunc(h?.height||1));
    return{x:p.x+w*HALF_W,y:p.y+hh*(ROW_STEP/2)};
  }
  /* Native CEntityMap direction enum / movement-search expansion order (0..5):
     East, South-East, South-West, West, North-West, North-East.
     This ordering is gameplay-significant because equal-cost route candidates retain
     the first predecessor encountered by the native movement search. */
  function neighbors(q,r){q=trunc(q);r=trunc(r);return(r&1)
    ?[[q+1,r],[q+1,r+1],[q,r+1],[q-1,r],[q,r-1],[q+1,r-1]]
    :[[q+1,r],[q,r+1],[q-1,r+1],[q-1,r],[q-1,r-1],[q,r-1]];
  }
  function oddrCube(q,r){q=trunc(q);r=trunc(r);const x=q-(r-(r&1))/2,z=r,y=-x-z;return[x,y,z]}
  function distance(a,b){const A=oddrCube(a.q,a.r),B=oddrCube(b.q,b.r);return Math.max(Math.abs(A[0]-B[0]),Math.abs(A[1]-B[1]),Math.abs(A[2]-B[2]))}
  function vertices(x,y,scale=1){const sx=HALF_W*scale,sy=HALF_H*scale,ey=CORNER_H*scale;return[[x,y-sy],[x+sx,y-ey],[x+sx,y+ey],[x,y+sy],[x-sx,y+ey],[x-sx,y-ey]]}
  return{GEOMETRY_ID,COL_STEP,ROW_STEP,HALF_W,HALF_H,CENTER_Y_OFFSET,CORNER_H,cellCenter,cellRect,worldToCell,battlePixelOrigin,battleRectCenter,neighbors,oddrCube,distance,vertices};
});
