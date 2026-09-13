'use strict';
const assert=require('assert'),fs=require('fs');
const p=JSON.parse(fs.readFileSync('assets/data/native_simple_effects.json','utf8'));
const required=['effect_gunfire.xml','effect_mgunfire.xml','effect_lightgun.xml','effect_lightgun1.xml','effect_lightgun2.xml','effect_lightgun3.xml','effect_gunnery.xml','effect_gunnery1.xml','effect_rocket1.xml','effect_bombingfire.xml','effect_waterfire.xml','effect_strike1.xml','effect_strike2.xml','effect_strike3.xml','effect_strike4.xml','effect_strike5.xml','effect_strike6.xml','effect_strike7.xml','effect_knifestrike1.xml','effect_knifestrike2.xml','effect_knifestrike3.xml','effect_knifestrike4.xml'];
for(const k of required)assert.ok(Array.isArray(p.groups[k])&&p.groups[k].length>0,`missing original effect group ${k}`);
for(const k of ['effect_airstrike.xml','effect_airgun.xml','effect_airfire.xml','effect_parachuter.xml'])assert.equal(p.groups[k],undefined,`${k} must remain unresolved because source XML is absent in APK`);
for(const k of ['effect_build','effect_recover','effect_moving1','effect_moving2','effect_moving3','effect_moving4'])assert.ok(p.effects[k],`base runtime effect lost: ${k}`);
assert.equal(Object.keys(p.effects).length,65);assert.equal(Object.keys(p.groups).length,23);
console.log('native effects visual coverage PASS',JSON.stringify({effects:Object.keys(p.effects).length,groups:Object.keys(p.groups).length,combatSourceGroups:required.length}));
