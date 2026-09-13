'use strict';
const fs=require('fs'),assert=require('assert');
const C=require('./native_camera_core.js'),H=require('./native_hex_core.js');
const app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');

// CEntityCamera::area-visible normal-mode path @ 0x7ff80.
assert.equal(C.FOCUS_INSET_X,64);
assert.equal(C.FOCUS_INSET_Y,72);
const cam={x:1000,y:800,zoom:1};
assert.equal(C.focusRectVisible(cam,{x:968,y:764,w:64,h:72}),true,'centered native 64x72 area should be safe-visible');
assert.equal(C.focusRectVisible(cam,{x:968,y:817,w:64,h:72}),false,'area crossing native bottom safe bound must trigger focus');
assert.equal(C.focusRectVisible(cam,{x:779,y:764,w:64,h:72}),false,'area crossing native left safe bound must trigger focus');
assert.equal(C.focusRectVisible({x:1000,y:800,zoom:.5},{x:968,y:764,w:64,h:72}),true);
assert.deepStrictEqual(H.cellRect(0,0),{x:-32,y:-54,w:64,h:72});
assert.deepStrictEqual(H.cellRect(0,1),{x:0,y:0,w:64,h:72});

// Player presentation path: focus only when pair is not adequately visible, wait for camera completion,
// then run the pre-existing rule/animation mutation. AI remains on its old synchronous path in this patch.
assert(app.includes('function nativePairFocusNeeded(source,target)'));
assert(app.includes('EW4NativeCamera.focusRectVisible(c,EW4NativeHex.cellRect(source.q,source.r))'));
assert(app.includes('function queueNativePlayerPairFocus(source,target,continuation)'));
assert(app.includes('x:(a.x+b.x)*.5,y:(a.y+b.y)*.5'));
assert(app.includes('if(!step.active&&battleState.cameraAfterMotion)'));
assert(app.includes('cameraPresentationPending=false'));
assert(app.includes('function resolvePlayerAttack(a,b)'));
assert(app.includes('queueNativePlayerPairFocus(a,b,()=>resolvePlayerAttack(a,b))'));
assert(app.includes('function resolvePlayerMove(u,q,r)'));
assert(app.includes('queueNativePlayerPairFocus(u,target,()=>resolvePlayerMove(u,q,r))'));
assert(app.includes('battleState.cameraPresentationPending||battleState.cameraMotion||performance.now()'));
assert(sw.includes('posthandoff'));
console.log('native player action camera focus PASS: 64/72 safe-view test + midpoint motor + wait-before-player-action');
