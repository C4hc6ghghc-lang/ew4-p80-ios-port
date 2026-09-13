'use strict';
const fs=require('fs'),assert=require('assert');
const C=require('./native_camera_core.js');
const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),sw=fs.readFileSync('sw.js','utf8');

// Hard constants from libeuropean-war-4.so x86_64:
// CEntityCamera setter 0x7f3e0; battle touch 0x9fe40..0xa0758.
assert.equal(C.MIN_ZOOM,0.2);
assert.equal(C.MAX_ZOOM,1.0);
assert.equal(C.DETAIL_ZOOM,0.5);
assert.equal(C.TAP_AXIS_SLOP,15);
assert.equal(C.PINCH_MIN_DISTANCE,40);
assert.equal(C.DRAG_HAS_FLING,false);
assert.equal(C.DEFAULT_GAME_SPEED,2);
assert.equal(C.clampZoom(0.01),0.2);
assert.equal(C.clampZoom(1.6),1.0);
assert.equal(C.clampZoom(.72),.72);
assert.equal(C.detailInteractionEnabled(.5),true);
assert.equal(C.detailInteractionEnabled(.499),false);

// Native click slop is axis-based, not the previous Web 3px Euclidean threshold.
assert.equal(C.isNativeTap({x:10,y:10},{x:24.9,y:24.9}),true);
assert.equal(C.isNativeTap({x:10,y:10},{x:25,y:10}),false);
assert.equal(C.isNativeTap({x:10,y:10},{x:10,y:25}),false);

// One-finger pan is incremental: previous-current divided by current zoom.
assert.deepStrictEqual(C.panStep({x:500,y:400,zoom:.5},{x:100,y:100},{x:90,y:112}),{x:520,y:376,zoom:.5});

// Screen/world inverse uses the native 568x320 logical center (284,160).
const cam={x:1000,y:800,zoom:.5};
assert.deepStrictEqual(C.screenToWorld(cam,284,160),{x:1000,y:800});
assert.deepStrictEqual(C.screenToWorld(cam,334,180),{x:1100,y:840});

// Pinch only above 40 on both old and new distances.
assert.equal(C.pinchStep(cam,{x:0,y:0},{x:50,y:0},{x:40,y:0}).applied,false);
const stationary={x:200,y:160},before={x:300,y:160},after={x:350,y:160};
const anchor=C.screenToWorld(cam,stationary.x,stationary.y);
const step=C.pinchStep(cam,before,after,stationary);
assert.equal(step.applied,true);
assert.equal(step.camera.zoom,.75); // .5 * 150/100
const anchoredAfter=C.screenToWorld(step.camera,stationary.x,stationary.y);
assert(Math.abs(anchor.x-anchoredAfter.x)<1e-9&&Math.abs(anchor.y-anchoredAfter.y)<1e-9,'stationary-finger anchor drift');

assert(app.includes('EW4NativeCamera.panStep'));
assert(app.includes('EW4NativeCamera.pinchStep'));
assert(app.includes('EW4NativeCamera.isNativeTap'));
assert(app.includes('!EW4NativeCamera.detailInteractionEnabled(battleState.camera.zoom)'));
assert(app.includes('clearSelectionForNativeLowZoom'));
assert(!app.includes('CAMERA_MIN_ZOOM=.58'));
assert(!app.includes('CAMERA_MAX_ZOOM=1.65'));
assert(html.includes('<script src="native_camera_core.js"></script>'));
assert(sw.includes("'./native_camera_core.js'"));
assert(sw.includes('posthandoff'));
assert(sw.includes("'./native_hex_core.js'"));
assert(sw.includes("'./native_lowzoom_core.js'"));
console.log('native camera interaction PASS: zoom .2..1, detail .5, tap 15px/axis, pinch >40 stationary-anchor, incremental pan, no drag fling');

assert(app.includes('applyCameraPose(pose,EW4NativeCamera.PAN_EDGE_MARGIN)'), 'one-finger pan must use native 16-world-unit edge margin');
