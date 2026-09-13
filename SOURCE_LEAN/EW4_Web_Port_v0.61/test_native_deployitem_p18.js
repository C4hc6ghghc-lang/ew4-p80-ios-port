'use strict';
const assert=require('assert'),fs=require('fs');
const css=fs.readFileSync('./r14_native_forms.css','utf8'),html=fs.readFileSync('./index.html','utf8'),app=fs.readFileSync('./app.js','utf8');
// layout-568h.xml form_deployitem geometry: 353x261, general 78x119, level 110x52,
// equip 110x74, desc 142x120, ItemBank 344x99, 7 columns, Equip 55x21.
for(const token of ['width:353px!important','height:261px!important','width:78px;height:119px','width:110px;height:52px','width:110px;height:74px','width:142px;height:120px','width:344px;height:99px','grid-template-columns:repeat(7,45px)','width:55px;height:21px'])assert.ok(css.includes(token),`missing native deployitem geometry: ${token}`);
assert.ok(html.includes('class="eq-general-group"'));assert.ok(html.includes('class="eq-level-group"'));assert.ok(html.includes('class="eq-equip-group"'));assert.ok(html.includes('class="eq-desc-group"'));assert.ok(html.includes('class="eq-items-group"'));
assert.ok(app.includes('EW4ItemInventory.sanitizeInventory(saveState.itemInventory,ITEMS)'));
assert.ok(app.includes('EW4ItemInventory.changeSlot({inventory:saveState.itemInventory'));
assert.ok(app.includes("if(it?.consumable){flash('战场消耗品不能装备')"));
assert.ok(app.includes("deployItemSelectedBankIndex=null;renderDeployItem()"),'equip must commit then remain in native DeployItem scene');
console.log('P18 native deployitem: PASS');
