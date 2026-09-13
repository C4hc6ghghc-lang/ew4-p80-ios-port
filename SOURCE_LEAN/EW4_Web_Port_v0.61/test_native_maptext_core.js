const fs=require('fs'),path=require('path'),assert=require('assert');
const C=require('./compact_bile_runtime.js'),M=require('./native_maptext_core.js');
const base=path.join(__dirname,'assets','maptext_native');
const bile=new C.Bile(fs.readFileSync(path.join(base,'maptext.bin')),fs.readFileSync(path.join(base,'maptext.xml'),'utf8'));
assert.strictEqual(bile.items.length,338);assert.strictEqual(Object.keys(bile.images).length,178);
for(const [map,file,count] of [['europe','maptextpos_europe.xml',102],['america','maptextpos_america.xml',41]]){
  const rows=M.parsePlacements(fs.readFileSync(path.join(base,file),'utf8'));assert.strictEqual(rows.length,count,map);
  for(const p of rows){assert.notStrictEqual(bile.nameToItem[p.libName],undefined,`${map}/${p.libName}`);const t=M.placementTransform(bile,p);assert(Number.isFinite(t.scaleX)&&t.scaleX>0);assert(Number.isFinite(t.scaleY)&&t.scaleY>0)}
}
const canada=M.parsePlacements(fs.readFileSync(path.join(base,'maptextpos_america.xml'),'utf8')).find(x=>x.libName==='canada');const ct=M.placementTransform(bile,canada);assert(ct.scaleX>ct.scaleY,'Canada label uses original non-uniform stretch');
console.log('native maptext core PASS · 338 BILE items / 178 atlas elements / Europe 102 placements / America 41 placements');
