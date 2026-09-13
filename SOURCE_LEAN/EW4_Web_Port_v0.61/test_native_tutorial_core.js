'use strict';
const assert=require('assert'),fs=require('fs'),crypto=require('crypto');
const T=require('./native_tutorial_core.js');
const data=JSON.parse(fs.readFileSync('assets/data/native_tutorial_scripts.json','utf8'));
assert.equal(T.areaCell(2783).q,18);assert.equal(T.areaCell(2783).r,35);assert.equal(T.areaCell(3028).q,26);assert.equal(T.areaCell(3028).r,38);
const s1=data.scripts['tutorials1.btl'],s2=data.scripts['tutorials2.btl'];assert.equal(s1.commandCount,138);assert.equal(s2.commandCount,135);
for(const [name,s] of Object.entries(data.scripts)){const raw=fs.readFileSync('assets/data/'+s.source);assert.equal(crypto.createHash('sha256').update(raw).digest('hex'),s.sha256,name+' source SHA mismatch')}
assert.deepEqual(T.commandStats(s1.commands),{'rand seed':1,'show text':17,'wait touch':14,'draw ui rect':28,'clear rect':9,'moveto area':18,'wait area':12,'draw rect':4,'sel area':2,'hide text':7,'wait ui':20,'wait action':3,'unsel area':2,'exit':1});
assert.deepEqual(T.commandStats(s2.commands),{'rand seed':1,'show text':16,'wait touch':17,'moveto area':16,'wait area':15,'draw ui rect':17,'clear rect':13,'unsel area':8,'draw rect':8,'hide text':5,'wait ui':12,'wait action':4,'sel area':2,'exit':1});
const log=[],r=new T.Runner({onSeed:n=>log.push(['seed',n]),onShowText:n=>log.push(['text',n]),onMoveToArea:c=>log.push(['move',c.id]),onDrawUIRect:c=>log.push(['ui',c.string,c.row]),onExit:()=>log.push(['exit'])});
r.start([{name:'rand seed',id:100},{name:'show text',id:1},{name:'wait touch'},{name:'moveto area',id:2783},{name:'wait area',id:2783},{name:'draw ui rect',string:'btn_city'},{name:'wait ui',string:'btn_city'},{name:'wait action'},{name:'exit'}]);
assert.equal(r.wait.type,'touch');r.notifyArea(2783);assert.equal(r.wait.type,'touch');r.notifyTouch();assert.equal(r.wait.type,'area');r.notifyArea(2783);assert.equal(r.wait.type,'ui');r.notifyUI('btn_factory');assert.equal(r.wait.type,'ui');r.notifyUI('btn_city');assert.equal(r.wait.type,'action');r.notifyAction();assert.equal(r.done,true);assert(log.some(x=>x[0]==='exit'));
console.log('native tutorial core PASS: 2 original scripts / 273 commands / exact source SHA + wait-state semantics');
