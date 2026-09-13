'use strict';
const assert=require('assert');
const H=require('./native_hex_core.js');
assert.equal(H.GEOMETRY_ID,'native-odd-r-64x54-v1');
assert.deepStrictEqual(H.cellCenter(0,0),{x:0,y:-18});
assert.deepStrictEqual(H.cellCenter(0,1),{x:32,y:36});
assert.deepStrictEqual(H.cellCenter(3,2),{x:192,y:90});
assert.deepStrictEqual(H.cellRect(3,2),{x:160,y:54,w:64,h:72});
for(let r=0;r<12;r++)for(let q=0;q<12;q++)assert.deepStrictEqual(H.worldToCell(H.cellCenter(q,r).x,H.cellCenter(q,r).y),{q,r});
assert.deepStrictEqual(H.battlePixelOrigin({origin_x:13,origin_y:30}),{x:800,y:1566});
assert.deepStrictEqual(H.battlePixelOrigin({origin_x:21,origin_y:29}),{x:1344,y:1512});
const c=H.battleRectCenter({origin_x:13,origin_y:30,width:21,height:21});assert.deepStrictEqual(c,{x:1472,y:2133});
assert.equal(H.battleCameraCenter,undefined,'selection-map centerx/centery path must be removed');
for(let r=0;r<6;r++)for(let q=0;q<6;q++){
 const a={q,r},ns=H.neighbors(q,r);assert.equal(ns.length,6);for(const [nq,nr] of ns)assert.equal(H.distance(a,{q:nq,r:nr}),1);
}
const vs=H.vertices(100,100,1);assert.deepStrictEqual(vs,[[100,64],[132,82],[132,118],[100,136],[68,118],[68,82]]);
console.log('native hex geometry PASS',JSON.stringify({center00:H.cellCenter(0,0),center01:H.cellCenter(0,1),campaign101Fallback:c}));
