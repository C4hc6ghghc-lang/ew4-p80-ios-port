'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const root=__dirname;
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const css=fs.readFileSync(path.join(root,'r14_native_forms.css'),'utf8');
const sw=fs.readFileSync(path.join(root,'sw.js'),'utf8');
const layout=fs.readFileSync(path.join(root,'assets/data/original_layout-568h.xml'),'utf8');

assert(/<Layout id="form_unitinfo"[^>]*w="330" h="187"/.test(layout));
for(const x of [
  'id="group_unit" type="groupbox" x="2" y="30" w="78" h="78"',
  'id="image_unit" type="image" name="recruit_grenadier.png" x="3" y="7"',
  'id="image_back_1" type="image" name="buildmaker.png" x="3" y="42" w="75" h="56"',
  'id="image_icon_1" type="image" name="" x="4" y="42" w="75" h="56"',
  'id="group_info" type="groupbox" x="249" y="30" w="78" h="78"',
  'id="group_ability" type="groupbox" x="80" y="33" w="165" h="72"',
  'id="grid_ability" type="grid" cols="4" rowh="24"',
  'id="group_desc" type="groupbox" x="4" y="110" w="323" h="74"',
  'id="text_desc" type="text" font="font_text_1" x="2" y="20" w="320" h="52"'
]) assert(layout.includes(x),x);

const unitInfo=app.slice(app.indexOf('const NATIVE_UNITINFO_ART='),app.indexOf('function showBattleCommanderInfo'));
const armyNames=['Militia','Line Infantry','Light Infantry','Grenadier','Guards','Machine Gun','Light Cavalry','Heavy Cavalry','Guards Cavalry','Armored Car','Light Artillery','Heavy Artillery','Siege Artillery','Rocket','Privateer','Frigate','Battleship','Ironclad','Small Fortress','Fortress','Large Fortress','Coastal Fort'];
for(const n of armyNames) assert(unitInfo.includes(`'${n}':[`),n);
for(const token of ['recruit_militia.png','recruit_line.png','recruit_light.png','recruit_grenadier.png','recruit_guard.png','recruit_machinegun.png','recruit_lightcavalry.png','recruit_heavycavalry.png','recruit_musketcavalry.png','recruit_armoredcar.png','recruit_lightartillery.png','recruit_heavyartillery.png','recruit_fortressartillery.png','recruit_rocket.png','recruit_cruiser.png','recruit_frigate.png','recruit_battleship.png','recruit_ironclads.png','build_smallfortress.png','build_mediumfortress.png','build_largefortress.png','build_coastalartillery.png']) assert(unitInfo.includes(token),token);
for(const icon of ['infomarker_attack.png','infomarker_soldiernumber.png','infomarker_hp.png','infomarker_food.png','infomarker_range.png','infomarker_move.png','button_upgrade_line.png']) assert(unitInfo.includes(icon),icon);
assert(unitInfo.includes("Math.max(1,Math.min(3,(+u.grade||0)+1))"));
assert(unitInfo.includes("src=\"assets/sprites/image_recruit_hd/buildmaker.png\""));
assert(unitInfo.includes("el.querySelector('.unitinfo-desc-title').textContent=armyName(u.army_name)"));
assert(unitInfo.includes("el.querySelector('.unitinfo-desc-text').textContent=STRINGS?.[`desc_${u.army_name}`]||''"));
assert(!unitInfo.includes('unitinfo-equip-list'));
assert(!unitInfo.includes('equippedItemIds(u)'));
assert(!unitInfo.includes('trainingDefenseBonus(u)'));
assert(!unitInfo.includes('moraleState(u)'));
assert(!unitInfo.includes('trainingLevel'));

assert(css.includes('#unit-card.native-unitinfo{left:119px!important;top:67px!important;width:330px!important;height:187px!important'));
assert(css.includes('.unitinfo-recruit{position:absolute;left:3px;top:7px;width:72px;height:53.5px'));
assert(css.includes('.unitinfo-form-layer{position:absolute;left:calc(3px + var(--layer)*4px);top:42px;width:75px;height:56px'));
assert(css.includes('.unitinfo-ability-grid{position:absolute;left:80px;top:33px;width:165px;height:72px'));
assert(css.includes('.unitinfo-desc{position:absolute;left:4px;top:110px;width:323px;height:74px'));
assert(css.includes('.unitinfo-desc-text{position:absolute;left:2px;top:20px;width:320px;height:52px'));
assert(!css.includes('.unitinfo-equip-list{'));

assert(/posthandoff(?:24-unitinfo|25-session|2[6-9]-|[3-9][0-9]-)/.test(sw));
for(const asset of ['recruit_militia.png','recruitmarker_militia.png','buildmaker.png','build_frame.png','infomarker_attack.png','infomarker_soldiernumber.png','infomarker_hp.png','infomarker_food.png','infomarker_range.png','infomarker_move.png']) assert(sw.includes(asset),asset);
console.log('P24 native form_unitinfo controller contract: PASS');
