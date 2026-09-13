'use strict';
const assert=require('assert'),fs=require('fs'),crypto=require('crypto'),path=require('path');
const root=__dirname,xmlPath=path.join(root,'assets/data/def_warzonetech.xml'),manifestPath=path.join(root,'assets/data/native_warzone_tech.json');
const xml=fs.readFileSync(xmlPath),text=xml.toString('utf8'),M=JSON.parse(fs.readFileSync(manifestPath,'utf8'));
assert.equal(crypto.createHash('sha256').update(xml).digest('hex'),M.source_sha256,'warzone tech XML sha mismatch');
const zones=[];for(const wm of text.matchAll(/<warzone id="(\d+)">([\s\S]*?)<\/warzone>/g)){const levels=Array(26).fill(null);for(const tm of wm[2].matchAll(/<tech id="(\d+)" level="(-?\d+)"\/>/g))levels[+tm[1]]=+tm[2];zones.push({id:+wm[1],levels})}
assert.equal(zones.length,6);for(const z of zones){assert.equal(z.levels.length,26);assert(!z.levels.includes(null));const actual=M.zones.find(x=>+x.id===z.id);assert(actual);assert.deepEqual(actual.levels,z.levels,`zone ${z.id} mismatch`)}
assert.equal(M.tech_count,26);assert.equal(zones.reduce((n,z)=>n+z.levels.length,0),156);
console.log('P21 native warzone tech manifest reproducibility: PASS');
