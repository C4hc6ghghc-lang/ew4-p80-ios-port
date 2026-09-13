const fs=require('fs');
const db=JSON.parse(fs.readFileSync(__dirname+'/assets/data/battle_native_triggers.json','utf8'));
let total=0,withDialogue=0,turn1=0; const rounds=new Map();
for(const [file,b] of Object.entries(db.battles)){
  const seen=new Set();
  for(const e of b.events||[]){
    if(+e.trigger_type!==2 || +e.param_a!==4) continue;
    total++;
    if(e.dialogue?.text) withDialogue++;
    if(+e.param_b===1) turn1++;
    rounds.set(+e.param_b,(rounds.get(+e.param_b)||0)+1);
    const key=`${e.sequence}:${e.event_id}`;
    if(seen.has(key)) throw new Error(`${file}: duplicate round-dialogue key ${key}`);
    seen.add(key);
  }
}
if(total!==240) throw new Error(`expected 240 native round-dialogue events, got ${total}`);
if(withDialogue!==240) throw new Error(`expected 240/240 dialogue links, got ${withDialogue}`);
if(turn1!==217) throw new Error(`expected 217 round-1 dialogues, got ${turn1}`);
for(const r of rounds.keys()) if(![1,2,3,4,5,6,7,10,14].includes(r)) throw new Error(`unexpected dialogue round ${r}`);
console.log('PASS native round dialogue schedule:',Object.fromEntries([...rounds].sort((a,b)=>a[0]-b[0])));
