'use strict';
(function(root,factory){
  const inventory=(typeof module==='object'&&module.exports)?require('./item_inventory_core.js'):root.EW4ItemInventory;
  const commerce=(typeof module==='object'&&module.exports)?require('./native_commerce_core.js'):root.EW4Commerce;
  const api=factory(inventory,commerce);
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4SceneShop=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(Inventory,Commerce){
  const SELL_BASE_PERCENT=60,COMMERCE_STEP_PERCENT=4,SELL_MAX_PERCENT=80,SELLER_SIZE=14;
  const HQ_CONSUMABLE_SLOTS=5,HQ_UNIQUE_SLOTS=Object.freeze([6,7]);

  function emptySellerSlot(){return null}
  function normalizeSeller(raw){
    const src=Array.isArray(raw)?raw:[];
    return Array.from({length:SELLER_SIZE},(_,i)=>{
      const s=src[i];if(!s)return null;
      const id=Number(s.item??s.itemId??s.id),count=Math.max(0,Math.trunc(Number(s.count??1)));
      return Number.isInteger(id)&&id>=0&&count>0?{item:id,count,active:s.active!==false}:null;
    });
  }
  function itemList(items){return Object.values(items||{}).filter(x=>x&&Number.isInteger(+x.id))}
  function isConsumable(item){return !!(item&&(item.consumable===true||item.consumable===1||item.consumable==='1'))}
  function directOwnedIds(inventory,equipment){
    const out=new Set(Inventory.inventoryIds(inventory));
    for(const slots of Object.values(equipment||{}))for(const id of Inventory.normalizeSlots(slots))if(id!=null)out.add(+id);
    return out;
  }
  function sellPercent(business,hq=false){return hq?SELL_BASE_PERCENT:Math.min(SELL_MAX_PERCENT,SELL_BASE_PERCENT+Commerce.businessStars(business)*COMMERCE_STEP_PERCENT)}
  function sellPrice(item,business=0,hq=false){const base=Math.max(0,Math.trunc(Number(item?.price)||0));return Math.max(1,Math.floor(base*sellPercent(business,hq)/100))}
  function buyPrice(item,business=0,hq=false){return hq?Math.max(0,Math.trunc(Number(item?.price)||0)):Commerce.shopBuyPrice(+item?.price||0,business)}
  function dateKey(date=new Date()){
    const d=date instanceof Date?date:new Date(date);if(Number.isNaN(d.getTime()))return'';
    const y=d.getFullYear(),m=String(d.getMonth()+1).padStart(2,'0'),day=String(d.getDate()).padStart(2,'0');return `${y}-${m}-${day}`;
  }
  function pick(arr,rand){if(!arr.length)return null;const r=Math.max(0,Math.min(.999999999,Number(rand?.())||0));return arr[Math.floor(r*arr.length)]}
  function makeHQDailyStock(items,ownedIds=new Set(),rand=Math.random){
    const slots=Array.from({length:SELLER_SIZE},emptySellerSlot),all=itemList(items);
    const consumables=all.filter(isConsumable),uniques=all.filter(x=>!isConsumable(x)&&!ownedIds.has(+x.id));
    for(let i=0;i<HQ_CONSUMABLE_SLOTS;i++){const it=pick(consumables,rand);if(it)slots[i]={item:+it.id,count:1,active:true}}
    const pool=uniques.slice();
    for(const idx of HQ_UNIQUE_SLOTS){const it=pick(pool,rand);if(!it)break;slots[idx]={item:+it.id,count:1,active:true};pool.splice(pool.indexOf(it),1)}
    return slots;
  }
  function ensureHQStore(state,{date=new Date(),items,inventory,equipment,rand=Math.random}={}){
    const key=dateKey(date),prev=state&&typeof state==='object'?state:{};
    if(prev.dateKey===key&&Array.isArray(prev.slots)&&prev.slots.length===SELLER_SIZE)return{dateKey:key,slots:normalizeSeller(prev.slots)};
    const owned=directOwnedIds(inventory,equipment);return{dateKey:key,slots:makeHQDailyStock(items,owned,rand)};
  }
  function sellerTake(store,index,amount=1){
    const slots=normalizeSeller(store?.slots||store),i=Math.trunc(+index),n=Math.max(1,Math.trunc(+amount||1));if(i<0||i>=SELLER_SIZE||!slots[i]||slots[i].count<n||slots[i].active===false)return{ok:false,slots};
    slots[i].count-=n;if(slots[i].count<=0)slots[i]=null;return{ok:true,slots};
  }
  function buy({store,index,inventory,items}={}){
    const slots=normalizeSeller(store?.slots||store),i=Math.trunc(+index),slot=slots[i];if(i<0||i>=SELLER_SIZE||!slot||slot.active===false||slot.count<=0)return{ok:false,reason:'empty',slots,inventory:Inventory.sanitizeInventory(inventory,items)};
    const added=Inventory.tryAdd(inventory,slot.item,1,items);if(!added.ok)return{ok:false,reason:added.reason,slots,inventory:added.inventory};
    const taken=sellerTake(slots,i,1);return{ok:true,item:slot.item,slots:taken.slots,inventory:added.inventory};
  }
  function sell({inventory,slotIndex,items}={}){
    const bank=Inventory.sanitizeInventory(inventory,items),i=Math.trunc(+slotIndex);if(i<0||i>=Inventory.BANK_SIZE)return{ok:false,reason:'slot',inventory:bank};
    const slot=bank.slots[i];if(!slot||slot.item<0||slot.count<=0)return{ok:false,reason:'empty',inventory:bank};
    const removed=Inventory.remove(bank,slot.item,1,items);return removed.ok?{ok:true,item:slot.item,inventory:removed.inventory}:{ok:false,reason:removed.reason,inventory:removed.inventory};
  }
  return Object.freeze({SELLER_SIZE,HQ_CONSUMABLE_SLOTS,HQ_UNIQUE_SLOTS,SELL_BASE_PERCENT,COMMERCE_STEP_PERCENT,SELL_MAX_PERCENT,normalizeSeller,directOwnedIds,sellPercent,sellPrice,buyPrice,dateKey,makeHQDailyStock,ensureHQStore,buy,sell});
});
