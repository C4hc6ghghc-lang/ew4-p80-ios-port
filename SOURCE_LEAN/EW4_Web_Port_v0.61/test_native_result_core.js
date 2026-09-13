'use strict';
const fs=require('fs'),assert=require('assert'),R=require('./native_result_core.js');
const db=JSON.parse(fs.readFileSync('assets/data/battles_runtime.json','utf8')).battles;
const b=db.find(x=>x.file==='campaign1_01.btl');assert(b);
assert.deepStrictEqual(R.stageTurnLimits(b),{valid:true,win:22,best:8});
// Exact x86_64 C++ rating formula recovered from libeuropean-war-4.so @ 0x7e6f0.
assert.equal(R.victoryScore(8,b),5);assert.equal(R.victoryGrade(8,b),1);
assert.equal(R.victoryScore(9,b),4);assert.equal(R.victoryGrade(9,b),2);
assert.equal(R.victoryScore(12,b),3);assert.equal(R.victoryGrade(12,b),3);
assert.equal(R.victoryScore(16,b),2);assert.equal(R.victoryGrade(16,b),4);
assert.equal(R.victoryScore(22,b),1);assert.equal(R.victoryGrade(22,b),5);
assert.deepStrictEqual(R.MEDAL_TABLE,[0,0,5,15,25,50]);
assert.equal(R.medalGain(5,0),50);assert.equal(R.medalGain(5,4),25);assert.equal(R.medalGain(4,3),10);assert.equal(R.medalGain(3,5),0);assert.equal(R.medalGain(1,0),0);
assert.equal(R.descriptionKey(5,50),'desc_victory 1');assert.equal(R.descriptionKey(5,0),'desc_victory 1 no award');assert.equal(R.descriptionKey(1,0),'desc_victory 5');
for(const x of db.filter(x=>/^campaign\d+_\d+\.btl$/.test(x.file))){const lim=R.stageTurnLimits(x);assert(lim.valid,x.file);for(let t=1;t<=lim.win;t++){const s=R.victoryScore(t,lim);assert(s>=1&&s<=5,`${x.file} t${t}`)}}
console.log('native result core PASS: exact 5-grade turn formula + cumulative medal delta table 0/5/15/25/50');
