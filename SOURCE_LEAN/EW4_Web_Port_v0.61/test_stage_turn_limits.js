'use strict';
const fs=require('fs'),assert=require('assert');
const db=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8')).battles;
const c=db.filter(b=>/^campaign\d+_\d+/.test(b.file));
assert(c.length>=80);
for(const b of c){const r=b.header.raw,win=+r[12],best=+r[13];assert(win>0,`${b.file} win`);assert(best>0,`${b.file} best`);assert(win>=best,`${b.file} ${win}/${best}`)}
const spot={
 'campaign1_01.btl':[22,8],
 'campaign1_12.btl':[40,21],
 'campaign2_08.btl':[36,16],
 'campaign4_08.btl':[28,11],
 'campaign5_07.btl':[33,12]
};
for(const [f,v] of Object.entries(spot)){const b=db.find(x=>x.file===f),r=b.header.raw;assert.deepStrictEqual([r[12],r[13]],v)}
console.log(`stage turn limits PASS: ${c.length}/${c.length} campaign BTLs, raw12>=raw13`);
