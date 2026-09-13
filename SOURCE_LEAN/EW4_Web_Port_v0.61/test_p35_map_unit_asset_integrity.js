'use strict';
const fs=require('fs'),path=require('path'),assert=require('assert');
const root=__dirname;
const sprites=JSON.parse(fs.readFileSync(path.join(root,'assets/sprite_manifest.json'),'utf8'));
const ready=JSON.parse(fs.readFileSync(path.join(root,'assets/data/unit_ready_manifest.json'),'utf8'));
const terrain=JSON.parse(fs.readFileSync(path.join(root,'assets/data/terrain_manifest.json'),'utf8'));
const battles=JSON.parse(fs.readFileSync(path.join(root,'assets/data/battles_runtime.json'),'utf8'));
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');

function finite(v){return Number.isFinite(+v)}
function exists(rel){return fs.existsSync(path.join(root,rel))}
function checkManifestFiles(obj,label){
  for(const [key,v] of Object.entries(obj)){
    if(v&&v.file)assert(exists(v.file),`${label} missing file ${key}: ${v.file}`);
  }
}
checkManifestFiles(sprites,'sprite');checkManifestFiles(ready,'ready');checkManifestFiles(terrain,'terrain');

// Critical world/tactical anchors that previously caused obvious drift must all be native-ref driven.
const critical=[
  ...Object.keys(sprites).filter(k=>/^transportship[12]\.png$/.test(k)),
  ...Object.keys(sprites).filter(k=>/^hpbar_/.test(k)),
  ...Object.keys(sprites).filter(k=>/^mark_unit_\d+\.png$/.test(k)),
  ...Object.entries(sprites).filter(([,v])=>String(v.file||'').includes('/buildings_hd/')).map(([k])=>k),
];
for(const key of critical){const v=sprites[key];assert(v,`missing ${key}`);for(const f of ['w','h','refx','refy'])assert(finite(v[f]),`${key} invalid ${f}`)}
for(const [key,v] of Object.entries(ready)){for(const f of ['x','y','w','h','minx','miny'])if(f in v)assert(finite(v[f]),`${key} invalid ${f}`)}
assert(app.includes('function drawSpriteManifest(key,q,r,scale=.5)'));
assert(app.includes('p.x-m.refx*s,p.y-m.refy*s,m.w*s,m.h*s'));
assert(app.includes('function drawTerrain(q,r)'));
assert(app.includes('p.x-m.refx*s,p.y-m.refy*s,m.w*s,m.h*s'));
assert(app.includes('function unitScreenPoint(u)'));
assert(app.includes('EW4NativeHex.cellCenter(q,r)'));

// Every battle unit still resolves through the full recovered 877-unit READY set.
function readyKey(u,b){
  const fixed=['Privateer','Frigate','Battleship','Ironclad','Small Fortress','Fortress','Large Fortress','Coastal Fort'];
  if(fixed.includes(u.army_name))return u.army_name;
  const g=Math.max(1,(u.grade||0)+1),cc=b.countries[u.owner]?.code||'fra',ck=`${u.army_name} ${cc} ${g}`;
  return ready[ck]?ck:`${u.army_name} ${g}`;
}
let total=0;for(const b of battles.battles)for(const u of b.units){total++;assert(ready[readyKey(u,b)],`${b.file} unit ${u.index} missing READY visual`)}
assert.strictEqual(total,7407);
console.log(`P35 map/unit asset integrity PASS: ${critical.length} critical native-ref sprites + ${Object.keys(ready).length} READY visuals + ${total} battle units`);
