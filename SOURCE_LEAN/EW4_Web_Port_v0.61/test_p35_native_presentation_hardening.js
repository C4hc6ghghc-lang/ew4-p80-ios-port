'use strict';
const fs=require('fs'),assert=require('assert');
const app=fs.readFileSync('app.js','utf8'),html=fs.readFileSync('index.html','utf8'),manifest=JSON.parse(fs.readFileSync('manifest.webmanifest','utf8')),sw=fs.readFileSync('sw.js','utf8');

// Keep game logic in the recovered 568x320 coordinate system while rasterizing at modern-device density.
assert(app.includes('const BATTLE_LOGICAL_W=568,BATTLE_LOGICAL_H=320,MAX_BATTLE_BACKING_SCALE=4'));
assert(app.includes('Math.ceil(raw*2)/2'),'HiDPI backing must round upward to a stable half-step instead of undersampling the CSS-scaled stage');
assert(app.includes('ctx.setTransform(battleBackingScale,0,0,battleBackingScale,0,0)'));
assert(app.includes("ctx.imageSmoothingQuality='high'"));
assert(app.includes('canvas.width=410*previewScale;canvas.height=320*previewScale'),'conquest map preview must use the same HiDPI hardening');

// Pointer coordinates are explicitly inverted from the transformed on-screen rect; never trust WebKit offsetX under CSS scale.
assert(app.includes('function battlePointerPoint(e)'));
assert(app.includes('(e.clientX-r.left)*(BATTLE_LOGICAL_W/rw)'));
assert(app.includes('(e.clientY-r.top)*(BATTLE_LOGICAL_H/rh)'));
const pointerBlock=app.slice(app.indexOf("canvas.addEventListener('pointerdown'"),app.indexOf("document.getElementById('round-btn')"));
assert(!pointerBlock.includes('e.offsetX')&&!pointerBlock.includes('e.offsetY'));
assert(app.includes("globalThis.visualViewport?.addEventListener('resize',resize)"));

// Remove user-facing Web-port chrome/branding while preserving internal migration/save keys.
assert.strictEqual(manifest.name,'欧陆战争 IV');
assert.strictEqual(manifest.short_name,'欧陆战争4');
assert(html.includes('<title>欧陆战争 IV</title>'));
assert(!html.includes('<title>欧陆战争 IV Web Port v0.61</title>'));
assert(html.includes('<meta name="apple-mobile-web-app-capable" content="yes" />'));
assert(html.includes('-webkit-touch-callout:none'));
assert(html.includes('overscroll-behavior:none'));
assert(html.includes('#stage{position:absolute;left:50%;top:50%;width:568px;height:320px;transform-origin:center center;overflow:hidden;background:#151a18}'));
assert(sw.includes('posthandoff49-p35-native-presentation'));

console.log('P35 native-presentation hardening PASS: HiDPI battlefield + exact transformed touch mapping + Web-chrome removal');
