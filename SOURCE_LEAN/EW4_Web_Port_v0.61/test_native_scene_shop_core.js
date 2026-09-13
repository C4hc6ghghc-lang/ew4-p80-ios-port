'use strict';
const assert=require('assert'),S=require('./native_scene_shop_core.js'),I=require('./item_inventory_core.js');
const items={
  11:{id:11,price:5,consumable:'1'},12:{id:12,price:10,consumable:'1'},13:{id:13,price:15,consumable:'1'},14:{id:14,price:30,consumable:'1'},15:{id:15,price:45,consumable:'1'},53:{id:53,price:5,consumable:'1'},
  100:{id:100,price:100},101:{id:101,price:101},102:{id:102,price:102},103:{id:103,price:103}
};
assert.equal(S.SELLER_SIZE,14);assert.equal(I.BANK_SIZE,28);
assert.equal(S.buyPrice({price:100},0,false),100);assert.equal(S.buyPrice({price:100},5,false),80);assert.equal(S.buyPrice({price:100},5,true),100);
assert.equal(S.sellPercent(0,false),60);assert.equal(S.sellPercent(5,false),80);assert.equal(S.sellPercent(5,true),60);assert.equal(S.sellPrice({price:101},3,false),72);assert.equal(S.sellPrice({price:1},0,true),1);
let inv=I.add(I.emptyBank(),100,1,items),owned=S.directOwnedIds(inv,{'9':[101,null]});assert(owned.has(100)&&owned.has(101));
let seq=[0,.2,.4,.6,.8,.1,.9],p=0,stock=S.makeHQDailyStock(items,owned,()=>seq[p++%seq.length]);assert.equal(stock.length,14);for(let i=0;i<5;i++)assert(stock[i]&&items[stock[i].item].consumable);assert.equal(stock[5],null);assert(stock[6]&&stock[7]&&stock[6].item!==stock[7].item);assert(!owned.has(stock[6].item)&&!owned.has(stock[7].item));for(let i=8;i<14;i++)assert.equal(stock[i],null);
let state=S.ensureHQStore(null,{date:new Date(2026,8,9),items,inventory:inv,equipment:{},rand:()=>0});assert.equal(state.dateKey,'2026-09-09');const same=S.ensureHQStore(state,{date:new Date(2026,8,9),items,inventory:inv,equipment:{},rand:()=>.9});assert.deepEqual(same,state);const next=S.ensureHQStore(state,{date:new Date(2026,8,10),items,inventory:inv,equipment:{},rand:()=>.9});assert.equal(next.dateKey,'2026-09-10');
let seller={slots:Array.from({length:14},(_,i)=>i===0?{item:11,count:1,active:true}:null)};let bought=S.buy({store:seller,index:0,inventory:I.emptyBank(),items});assert(bought.ok&&I.count(bought.inventory,11)===1&&!bought.slots[0]);let sold=S.sell({inventory:bought.inventory,slotIndex:0,items});assert(sold.ok&&sold.item===11&&I.count(sold.inventory,11)===0);
console.log('native SceneShop core PASS: shared 14-slot seller, 28-slot bank, HQ daily stock, buy/sell pricing');
