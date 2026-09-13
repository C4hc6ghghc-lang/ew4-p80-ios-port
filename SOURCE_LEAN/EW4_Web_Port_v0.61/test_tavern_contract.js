'use strict';
const fs=require('fs'),path=require('path'),assert=require('assert');
const root=__dirname,data=JSON.parse(fs.readFileSync(path.join(root,'assets/data/battle_taverns.json'),'utf8'));
let taverns=0,battles=0;for(const [file,group] of Object.entries(data.battles||{})){battles++;for(const t of Object.values(group)){taverns++;assert(t.count>=1&&t.count<=5);assert(Array.isArray(t.slots)&&t.slots.length<=5);for(const s of t.slots){assert(Number.isInteger(+s.commander));for(const k of ['money','industry','medal','round'])assert(Number.isFinite(+s[k]))}}}
assert.strictEqual(battles,7);assert.strictEqual(taverns,38);
const sample=data.battles['campaign1_02b.btl']['3101'];assert(sample);assert.strictEqual(sample.count,5);assert.deepStrictEqual(sample.slots.map(x=>[x.commander,x.money,x.industry,x.medal,x.round]),[[3,1,1,0,1],[5,1,1,0,2],[7,1,1,0,3],[9,1,1,0,4],[4,1,1,0,5]]);
const app=fs.readFileSync(path.join(root,'app.js'),'utf8'),sw=fs.readFileSync(path.join(root,'sw.js'),'utf8'),save=fs.readFileSync(path.join(root,'battle_save_core.js'),'utf8');
for(const n of ['initialBattleTaverns','battleTavernForObject','openTavernPanel','recruitTavernCandidate',"special==='bar'",'button_bar'])assert(app.includes(n),n);
assert(app.includes('battleState.resources.money-=+slot.money'));assert(app.includes('battleState.resources.industry-=+slot.industry'));assert(app.includes('acquire(slot.commander)'));assert(app.includes('Math.min(4,tavern.count'));
assert(sw.includes('battle_taverns.json'));assert(/r14-(?:9|[1-9][0-9])/.test(sw));assert(/const SCHEMA=(?:5|6);/.test(save));assert(/new Set\(\[1,2,3,4,5(?:,6)?\]\)/.test(save));assert(save.includes('taverns:'));
console.log('tavern contract PASS',JSON.stringify({battles,taverns,sample:sample.slots.length}));
