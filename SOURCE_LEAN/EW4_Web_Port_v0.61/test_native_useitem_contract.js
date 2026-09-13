'use strict';
const fs=require('fs'),assert=require('assert');
const html=fs.readFileSync('index.html','utf8'),css=fs.readFileSync('r14_native_forms.css','utf8'),app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
assert(html.includes('id="useitem-panel"'));assert(html.includes('id="useitem-list"'));assert(html.includes('id="useitem-desc"'));assert(html.includes('id="useitem-confirm"'));assert(html.includes('native_useitem_core.js'));
assert(css.includes('#useitem-panel{left:144px;top:72px;width:280px;height:175px'));assert(css.includes('#useitem-list{position:absolute;left:9px;top:35px;width:269px;height:45px'));assert(css.includes("item_selected_ex.png"));
assert(app.includes("addBattleAction('button_items','物品'"));assert(app.includes('EW4NativeUseItem.USE_ITEM_IDS'));assert(app.includes("EW4ItemInventory.remove(saveState.itemInventory,id,1,ITEMS)"));assert(app.includes("playNativeActionSfx('supply')"));assert(app.includes('saveState.itemInventory=taken.inventory;u.moved=true;u.attacked=true'));assert(app.includes("addBattleAction('button_items','物品',()=>openBattleUseItem(u),!!u.attacked"));assert(app.includes("spawnNativeSimpleEffect('effect_recover',u.q,u.r)"));
assert(sw.includes("'./native_useitem_core.js'"));
console.log('native use-item form/runtime contract tests passed');
