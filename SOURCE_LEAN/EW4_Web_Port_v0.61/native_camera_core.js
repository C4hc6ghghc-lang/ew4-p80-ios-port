'use strict';
(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  if(root)root.EW4NativeCamera=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  // libeuropean-war-4.so CEntityCamera / battle gesture constants.
  // Static pose: 0x7f3e0/0x7f590; programmatic target: 0x7f8d0/0x7fa90;
  // update: 0x7fc90; battle touch: 0x9fe40..0xa0758.
  const MIN_ZOOM=0.2;
  const MAX_ZOOM=1.0;
  const DETAIL_ZOOM=0.5;
  const TAP_AXIS_SLOP=15;
  const PINCH_MIN_DISTANCE=40;
  const VIEW_CX=284;
  const VIEW_CY=160;
  const PAN_EDGE_MARGIN=16;
  const DRAG_HAS_FLING=false;
  const DEFAULT_GAME_SPEED=2;
  const GAME_SPEED_COEFFICIENTS=Object.freeze([0.012,0.015,0.020,0.020,0.020]);
  const NATIVE_TICK_RATE=60;
  const POSITION_SNAP=1.0;
  const ZOOM_SNAP=0.01;
  const FOCUS_INSET_X=64;
  const FOCUS_INSET_Y=72;

  const clamp=(v,lo,hi)=>Math.max(lo,Math.min(hi,v));
  function clampZoom(z){return clamp(Number.isFinite(+z)?+z:1,MIN_ZOOM,MAX_ZOOM)}
  function detailInteractionEnabled(z){return +z>=DETAIL_ZOOM}
  function isNativeTap(start,end){
    if(!start||!end)return false;
    // Native release path compares each axis independently against 15.0f.
    return Math.abs(+end.x-(+start.x))<TAP_AXIS_SLOP&&Math.abs(+end.y-(+start.y))<TAP_AXIS_SLOP;
  }
  function screenToWorld(camera,x,y,cx=VIEW_CX,cy=VIEW_CY){
    const z=+camera.zoom||1;
    return{x:(+x-cx)/z+(+camera.x||0),y:(+y-cy)/z+(+camera.y||0)};
  }
  function zoomAt(camera,nextZoom,sx=VIEW_CX,sy=VIEW_CY,worldAnchor=null,cx=VIEW_CX,cy=VIEW_CY){
    const anchor=worldAnchor||screenToWorld(camera,sx,sy,cx,cy),z=clampZoom(nextZoom);
    return{x:anchor.x-(sx-cx)/z,y:anchor.y-(sy-cy)/z,zoom:z};
  }
  function panStep(camera,previous,current){
    if(!camera||!previous||!current)return null;
    const z=+camera.zoom||1;
    // Native one-finger move: camera += (previousTouch-currentTouch)/zoom.
    // Release does NOT start a fling; native smooth motion is a separate scripted/action path.
    return{x:(+camera.x||0)+(+previous.x-(+current.x))/z,y:(+camera.y||0)+(+previous.y-(+current.y))/z,zoom:z};
  }
  function pinchStep(camera,movedBefore,movedAfter,stationary,cx=VIEW_CX,cy=VIEW_CY){
    if(!camera||!movedBefore||!movedAfter||!stationary)return{applied:false,camera:{...camera}};
    const oldDist=Math.hypot(+movedBefore.x-(+stationary.x),+movedBefore.y-(+stationary.y));
    const newDist=Math.hypot(+movedAfter.x-(+stationary.x),+movedAfter.y-(+stationary.y));
    // Native applies pinch only when BOTH separations exceed 40 logical pixels.
    if(!(oldDist>PINCH_MIN_DISTANCE&&newDist>PINCH_MIN_DISTANCE))return{applied:false,oldDist,newDist,camera:{...camera}};
    // Native anchors the stationary finger's world point for each incremental pointer event.
    const anchor=screenToWorld(camera,stationary.x,stationary.y,cx,cy);
    const z=clampZoom((+camera.zoom||1)*(newDist/oldDist));
    return{applied:true,oldDist,newDist,anchor,camera:{x:anchor.x-(+stationary.x-cx)/z,y:anchor.y-(+stationary.y-cy)/z,zoom:z}};
  }
  // Native CEntityCamera area-visibility test around 0x7ff80 for normal battle modes.
  // The entire area rectangle must fit inside the viewport after 64/72 world-unit safe insets.
  function focusRectVisible(camera,rect){
    if(!camera||!rect)return false;
    const z=clampZoom(camera.zoom),cx=+camera.x||0,cy=+camera.y||0,hw=VIEW_CX/z,hh=VIEW_CY/z;
    const left=cx-hw+FOCUS_INSET_X,right=cx+hw-FOCUS_INSET_X,top=cy-hh+FOCUS_INSET_Y,bottom=cy+hh-FOCUS_INSET_Y;
    const x=+rect.x||0,y=+rect.y||0,w=Math.max(0,+rect.w||0),h=Math.max(0,+rect.h||0);
    return x>=left&&x+w<=right&&y>=top&&y+h<=bottom;
  }
  function gameSpeedCoefficient(speed=DEFAULT_GAME_SPEED){
    const i=Math.max(1,Math.min(5,Math.trunc(+speed||DEFAULT_GAME_SPEED)));
    return GAME_SPEED_COEFFICIENTS[i-1];
  }
  function axisMotor(current,target,coefficient,snap){
    current=+current||0;target=Number.isFinite(+target)?+target:current;
    const d=target-current;
    if(Math.abs(d)<=snap)return{current:target,target,velocity:0};
    return{current,target,velocity:d*coefficient};
  }
  // Native programmatic camera setup. This is NOT the manual drag path.
  function startProgrammaticMove(camera,target,{gameSpeed=DEFAULT_GAME_SPEED,targetZoom=null}={}){
    const src={x:+camera?.x||0,y:+camera?.y||0,zoom:clampZoom(camera?.zoom)},coef=gameSpeedCoefficient(gameSpeed);
    const xm=axisMotor(src.x,target?.x,coef,POSITION_SNAP),ym=axisMotor(src.y,target?.y,coef,POSITION_SNAP);
    const zTarget=targetZoom==null?src.zoom:clampZoom(targetZoom),zm=axisMotor(src.zoom,zTarget,coef,ZOOM_SNAP);
    const out={x:xm.current,y:ym.current,zoom:zm.current};
    const motion={target:{x:xm.target,y:ym.target,zoom:zm.target},vx:xm.velocity,vy:ym.velocity,vz:zm.velocity,active:!!(xm.velocity||ym.velocity||zm.velocity),gameSpeed:Math.max(1,Math.min(5,Math.trunc(+gameSpeed||DEFAULT_GAME_SPEED)))};
    return{camera:out,motion};
  }
  function stepAxis(current,target,velocity,factor){
    if(!velocity)return{current:target===current?current:current,velocity:0};
    const remain=target-current,step=velocity*factor;
    if(Math.abs(step)>=Math.abs(remain))return{current:target,velocity:0};
    return{current:current+step,velocity};
  }
  function stepProgrammaticMove(camera,motion,dtSeconds){
    if(!motion?.active)return{camera:{x:+camera?.x||0,y:+camera?.y||0,zoom:clampZoom(camera?.zoom)},motion:{...(motion||{}),active:false},active:false};
    const factor=Math.max(0,+dtSeconds||0)*NATIVE_TICK_RATE,t=motion.target||{};
    const x=stepAxis(+camera.x||0,+t.x||0,+motion.vx||0,factor),y=stepAxis(+camera.y||0,+t.y||0,+motion.vy||0,factor),z=stepAxis(clampZoom(camera.zoom),clampZoom(t.zoom),+motion.vz||0,factor);
    const active=!!(x.velocity||y.velocity||z.velocity),next={...motion,vx:x.velocity,vy:y.velocity,vz:z.velocity,active};
    return{camera:{x:x.current,y:y.current,zoom:clampZoom(z.current)},motion:next,active};
  }
  function hasCommander(u){return !!u&&!u.dead&&Number.isFinite(+u.commander_id)&&+u.commander_id>0}
  // New-battle native focus path 0x7d410 -> 0x805f0 -> 0x57240 -> 0x85380:
  // first player-operable cell with a commander wins immediately. If none exists,
  // native ActionAssist scoring chooses a cell; that scoring remains unresolved.
  function openingFocusUnit(units,owner){
    const own=(Array.isArray(units)?units:[]).filter(u=>u&&!u.dead&&+u.owner===+owner);
    const commander=own.find(hasCommander);
    if(commander)return{unit:commander,reason:'commander',exact:true};
    if(own.length)return{unit:own[0],reason:'actionassist-unresolved-fallback',exact:false};
    return null;
  }
  return{MIN_ZOOM,MAX_ZOOM,DETAIL_ZOOM,TAP_AXIS_SLOP,PINCH_MIN_DISTANCE,VIEW_CX,VIEW_CY,PAN_EDGE_MARGIN,DRAG_HAS_FLING,DEFAULT_GAME_SPEED,GAME_SPEED_COEFFICIENTS,NATIVE_TICK_RATE,POSITION_SNAP,ZOOM_SNAP,FOCUS_INSET_X,FOCUS_INSET_Y,clampZoom,detailInteractionEnabled,isNativeTap,screenToWorld,zoomAt,panStep,pinchStep,focusRectVisible,gameSpeedCoefficient,startProgrammaticMove,stepProgrammaticMove,openingFocusUnit};
});
