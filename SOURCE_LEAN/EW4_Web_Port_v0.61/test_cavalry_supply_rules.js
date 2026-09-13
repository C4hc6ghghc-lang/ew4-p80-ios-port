const fs=require('fs');
const path=require('path');
const root=__dirname;
const cons=JSON.parse(fs.readFileSync(path.join(root,'assets/data/constructions.json'),'utf8'));
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
function assert(x,m){if(!x)throw new Error(m)}
// Native construction supply values must be present and monotonic per facility family.
for(const [name,c] of Object.entries(cons)){
  const vals=(c.levels||[]).map(x=>+x.supply||0);
  assert(vals.length>0,`${name}: no levels`);
  for(let i=1;i<vals.length;i++) assert(vals[i]>=vals[i-1],`${name}: supply not monotonic ${vals}`);
}
assert(cons.city.levels.at(-1).supply===12,'city max supply must be 12 from APK');
assert(cons.industry.levels.at(-1).supply===8,'industry max supply must be 8 from APK');
assert(cons.stable.levels.at(-1).supply===6,'stable max supply must be 6 from APK');
assert(cons.port.levels.at(-1).supply===6,'port max supply must be 6 from APK');
assert(app.includes('function grantCavalryExtraAction'), 'cavalry extra-action hook missing');
assert(app.includes("armyStat(u).type==='cavalry'"), 'cavalry type check missing');
assert(app.includes('attacker.moved=false;attacker.attacked=false'), 'cavalry action reset missing');
assert(app.includes('function facilitySupplyFor'), 'facility supply hook missing');
assert(app.includes('function applyFacilitySupplyAll'), 'global facility supply settlement missing');
assert(app.includes('for(const u of battleState.units)'), 'global facility supply must iterate all live units');
assert(!app.includes('noble+flag+facility+tent'), 'player settlement still double-counts facility supply');
assert(app.includes('constructionLevel(o)?.supply'), 'facility supply not driven by APK construction data');
assert(app.includes('if(rr?.extra)i--'), 'AI cavalry repeat hook missing');
assert(app.includes("u.army_name==='Light Infantry'"), 'light infantry terrain-ignore rule missing');
assert(!app.includes("st.type==='infantry'||EW4Combat.hasSkill(c,1)"), 'all-infantry terrain-ignore bug still present');
assert(app.includes("armyStat(u).type==='infantry'&&terrainCell"), 'fieldwork UI must be infantry-only');
assert(app.includes("armyStat(u).type!=='infantry'"), 'fieldwork execution must reject non-infantry');
console.log('cavalry + facility supply rules PASS');
