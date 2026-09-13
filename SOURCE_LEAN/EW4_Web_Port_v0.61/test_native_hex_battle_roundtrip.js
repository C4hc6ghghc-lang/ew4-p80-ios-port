'use strict';
const assert=require('assert');
const H=require('./native_hex_core.js'),D=require('./assets/data/battles_runtime.json').battles;
let units=0,objects=0;
for(const b of D){
 for(const u of b.units||[]){units++;const p=H.cellCenter(u.q,u.r);assert.deepStrictEqual(H.worldToCell(p.x,p.y),{q:u.q,r:u.r},`${b.file} unit ${u.index}`)}
 for(const o of b.objects||[]){if(o.q==null||o.r==null)continue;objects++;const p=H.cellCenter(o.q,o.r);assert.deepStrictEqual(H.worldToCell(p.x,p.y),{q:o.q,r:o.r},`${b.file} object ${o.pos}`)}
}
assert(units>7000&&objects>7900);
console.log(`native hex BTL roundtrip PASS: ${D.length} battles / ${units} units / ${objects} objects`);
