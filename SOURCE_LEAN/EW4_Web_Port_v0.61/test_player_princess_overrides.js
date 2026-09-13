'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const raw=require('./assets/data/commanders.json');
const p=require('./assets/data/player_princess_overrides.json');
const ids=[201,202,203,204,205,206,207,208];
assert.deepStrictEqual(p.unlock.ids,ids);
for(const id of ids)assert(raw[String(id)],`missing original princess ${id}`);
function skills(c){return [c.skill1,c.skill2,c.skill3,c.skill4].map(Number).filter(x=>x>=0)}
function eff(id){const c=raw[String(id)],o=p.princesses[String(id)];if(!o)return {...c,skills:skills(c)};return {...c,...o.stats,skills:[...new Set([...skills(c),...o.addSkills.map(Number)])]}}
let c=eff(208);assert.strictEqual(c.infantry,5);assert.strictEqual(c.cavalry,5);assert.strictEqual(c.movement,7);assert.strictEqual(c.training,5);assert.deepStrictEqual(c.skills.sort((a,b)=>a-b),[3,4,9,10,11,12,13,14,15,31,32,33,34].sort((a,b)=>a-b));
c=eff(205);assert.strictEqual(c.infantry,5);assert.strictEqual(c.movement,7);assert.strictEqual(c.training,5);assert.deepStrictEqual(c.skills.sort((a,b)=>a-b),[1,3,12,13,14,15,31,32,33].sort((a,b)=>a-b));
c=eff(204);assert.strictEqual(c.artillery,5);assert.strictEqual(c.movement,7);assert.strictEqual(c.training,5);assert.deepStrictEqual(c.skills.sort((a,b)=>a-b),[1,4,5,6,7,8,31,32,35].sort((a,b)=>a-b));
// The other five are unlock-only and must not get custom stats/skills.
for(const id of [201,202,203,206,207])assert.strictEqual(p.princesses[String(id)],undefined);
const app=fs.readFileSync(path.join(__dirname,'app.js'),'utf8');
assert(app.includes('const PRINCESS_IDS=Object.freeze([201,202,203,204,205,206,207,208])'));
assert(app.includes('ensurePrincessUnlocks'));
assert(app.includes("PLAYER_PRINCESS_OVERRIDES?.princesses"));
assert(!app.includes('超过原版胜利回合上限'));
assert(!app.includes('enhmark\">强化'));

const html=fs.readFileSync(path.join(__dirname,'index.html'),'utf8');
assert(!html.includes('基础HP +40'));
assert(!html.includes('>强化<'));
assert(!app.includes('基础HP +40'));
assert(app.includes('playerAttackMinBonus:4'));
assert(app.includes('playerAttackMaxBonus:4'));
assert(app.includes('playerBaseHpBonus:120'));

const sw=fs.readFileSync(path.join(__dirname,'sw.js'),'utf8');assert(sw.includes('./assets/data/player_princess_overrides.json'));
console.log('player princess overrides PASS: all 8 unlocked; Lan/Victoria/Isabela only; no forced campaign turn-limit defeat');
