const fs=require('fs');
const path=require('path');
const base=__dirname;
const native=JSON.parse(fs.readFileSync(path.join(base,'assets/data/battle_native_triggers.json'),'utf8'));
const runtime=JSON.parse(fs.readFileSync(path.join(base,'assets/data/battles_runtime.json'),'utf8'));
const battles=Array.isArray(runtime)?runtime:(runtime.battles||[]);
if(!native || !native.battles) throw new Error('native trigger DB missing battles');
let objectives=0,events=0,countries=0,matched=0,dialogues=0;
const byFile=new Map(battles.map(b=>[b.file,b]));
for(const [file,meta] of Object.entries(native.battles)){
  const b=byFile.get(file); if(!b) throw new Error(`missing runtime battle ${file}`);
  for(const o of meta.objectives||[]){
    objectives++;
    const hit=(b.objects||[]).some(x=>+x.pos===+o.position);
    if(!hit) throw new Error(`${file}: objective ${o.position} has no object`);
    matched++;
  }
  for(const e of meta.events||[]){events++; if(e.country) countries++; if(e.dialogue?.text) dialogues++; if(Array.isArray(e.raw) && e.raw.length===11 && e.raw[10]!==0xCCCCCC00) throw new Error(`${file}: bad event sentinel`)}
}
if(Object.keys(native.battles).length!==101) throw new Error('expected 101 native battle records');
if(objectives!==144 || matched!==144) throw new Error(`objective mismatch ${matched}/${objectives}`);
if(events!==360) throw new Error(`expected 360 events, got ${events}`);
if(countries!==86) throw new Error(`expected 86 country-coded events, got ${countries}`);
if(dialogues!==323) throw new Error(`expected 323 dialogue-linked events, got ${dialogues}`);
console.log(`PASS native triggers: battles=${Object.keys(native.battles).length} objectives=${objectives}/${matched} events=${events} countryCodes=${countries} dialogues=${dialogues}`);
