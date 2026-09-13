'use strict';
const fs=require('fs');
const path=require('path');
const root=__dirname;
const stores=JSON.parse(fs.readFileSync(path.join(root,'assets/data/battle_itemstores.json'),'utf8'));
const items=JSON.parse(fs.readFileSync(path.join(root,'assets/data/items.json'),'utf8'));
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const css=fs.readFileSync(path.join(root,'r14_native_forms.css'),'utf8');
const sw=fs.readFileSync(path.join(root,'sw.js'),'utf8');
let storeCount=0,filled=0;
for(const battle of Object.values(stores.battles||{}))for(const store of Object.values(battle||{})){
  storeCount++;
  if(!Array.isArray(store.slots)||store.slots.length!==14)throw new Error('ItemStore must have 14 slots');
  filled+=store.slots.filter(Boolean).length;
}
if(storeCount!==151)throw new Error(`expected 151 stores, got ${storeCount}`);
const consumables=Object.values(items).filter(x=>String(x.consumable)==='1');
if(consumables.length!==6)throw new Error(`expected 6 native consumables, got ${consumables.length}`);
for(const needle of ["special==='shop'",'openShopPanel(o)','openHeadquartersShop()','renderSceneShop(ctx)','EW4SceneShop.buy({','EW4SceneShop.sell({','EW4ItemInventory.BANK_SIZE'])if(!app.includes(needle))throw new Error(`SceneShop path missing: ${needle}`);
if(!app.includes("saveState.hqShop=EW4SceneShop.ensureHQStore"))throw new Error('HQ daily store persistence missing');
if(!html.includes('native_scene_shop_core.js'))throw new Error('SceneShop core script missing');
if((html.match(/id="commerce-panel"/g)||[]).length!==1)throw new Error('shared form_shop shell must be singular');
if(!css.includes('overflow-y:auto'))throw new Error('28-slot buyer bank must scroll');
if(!sw.includes('battle_itemstores.json')||!sw.includes('./native_scene_shop_core.js'))throw new Error('shop data/core missing from service worker');
console.log('shared SceneShop contract PASS',JSON.stringify({battleStores:storeCount,filledSlots:filled,sellerSlots:14,buyerSlots:28,hqConsumables:consumables.length}));
