'use strict';
const fs=require('fs'),assert=require('assert');
const C=require('./native_camera_core.js');
const app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');

// libeuropean-war-4.so CEntityCamera programmatic move audit:
// setup 0x7f8d0/0x7fa90, update 0x7fc90, native tick multiplier 60.
assert.deepStrictEqual([...C.GAME_SPEED_COEFFICIENTS],[.012,.015,.020,.020,.020]);
assert.equal(C.gameSpeedCoefficient(1),.012);
assert.equal(C.gameSpeedCoefficient(2),.015);
assert.equal(C.gameSpeedCoefficient(5),.020);
assert.equal(C.NATIVE_TICK_RATE,60);
assert.equal(C.POSITION_SNAP,1);
assert.equal(C.ZOOM_SNAP,.01);
assert.equal(C.DRAG_HAS_FLING,false);

let started=C.startProgrammaticMove({x:100,y:100,zoom:.4},{x:200,y:40},{gameSpeed:2,targetZoom:1});
assert.equal(started.motion.active,true);
assert(Math.abs(started.motion.vx-1.5)<1e-12);
assert(Math.abs(started.motion.vy+0.9)<1e-12);
assert(Math.abs(started.motion.vz-.009)<1e-12);
let step=C.stepProgrammaticMove(started.camera,started.motion,1/60);
assert(Math.abs(step.camera.x-101.5)<1e-9);
assert(Math.abs(step.camera.y-99.1)<1e-9);
assert(Math.abs(step.camera.zoom-.409)<1e-9);
for(let i=0;i<90&&step.active;i++)step=C.stepProgrammaticMove(step.camera,step.motion,1/60);
assert.deepStrictEqual(step.camera,{x:200,y:40,zoom:1});
assert.equal(step.active,false);

// Native setup snaps tiny deltas rather than starting a motor.
started=C.startProgrammaticMove({x:10,y:20,zoom:.7},{x:10.75,y:19.2},{gameSpeed:2,targetZoom:.705});
assert.deepStrictEqual(started.camera,{x:10.75,y:19.2,zoom:.705});
assert.equal(started.motion.active,false);

// Opening native focus: first locally-owned commander cell wins before ActionAssist scoring.
const units=[
 {owner:1,q:1,r:1,commander_id:201},
 {owner:0,q:2,r:2,commander_id:0},
 {owner:0,q:3,r:3,commander_id:94},
 {owner:0,q:4,r:4,commander_id:10},
];
let focus=C.openingFocusUnit(units,0);
assert.equal(focus.unit.q,3);assert.equal(focus.unit.r,3);assert.equal(focus.reason,'commander');assert.equal(focus.exact,true);
focus=C.openingFocusUnit([{owner:0,q:7,r:8,commander_id:0},{owner:0,q:9,r:9}],0);
assert.equal(focus.unit.q,7);assert.equal(focus.reason,'actionassist-unresolved-fallback');assert.equal(focus.exact,false);

assert(app.includes('function startNativeProgrammaticCamera'));
assert(app.includes('EW4NativeCamera.startProgrammaticMove'));
assert(app.includes('EW4NativeCamera.stepProgrammaticMove'));
assert(app.includes('openingFocus=EW4NativeCamera.openingFocusUnit(units,+playerOwner)'));
assert(app.includes("openingFocusReason:restoredNativeCamera?'restored-native-camera'"));
assert(!app.includes('EW4NativeHex.battleCameraCenter'));
assert(sw.includes('posthandoff'));
console.log('native programmatic camera PASS: GameSpeed motor + no-fling separation + commander-first fresh-battle focus');
