const fs=require('fs'),path=require('path');
const base=__dirname;
const native=JSON.parse(fs.readFileSync(path.join(base,'assets/data/battle_native_triggers.json'),'utf8'));
let count=0,battles=0,round11=0,dialogues=0;
for(const [file,m] of Object.entries(native.battles||{})){
  const e=(m.events||[]).filter(x=>+x.trigger_type===2&&+x.param_a===5&&+x.param_c>0);
  if(e.length)battles++;
  for(const x of e){count++; if(+x.param_b===11)round11++; if(x.dialogue?.text)dialogues++;}
}
if(count!==31)throw new Error(`expected 31 native fire events, got ${count}`);
if(battles<10)throw new Error(`too few fire-event battles ${battles}`);
if(round11!==6)throw new Error(`expected 6 round-11 scorched-earth events, got ${round11}`);
console.log(`PASS native fire events: events=${count} battles=${battles} round11=${round11} dialogues=${dialogues}`);
