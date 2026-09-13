(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  root.EW4ItemInventory=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';

  const BANK_SIZE=28,EMPTY_ID=-1,SLOT0_STACK_MAX=999,NORMAL_STACK_MAX=99;

  function itemId(value){
    if(value===null||value===undefined||value==='')return null;
    const n=Number(value);return Number.isInteger(n)&&n>=0?n:null;
  }
  function normalizeSlots(raw,fallback=[]){
    const src=Array.isArray(raw)?raw:(Array.isArray(fallback)?fallback:[]);
    return [itemId(src[0]),itemId(src[1])];
  }
  function emptySlot(){return{item:EMPTY_ID,count:0}}
  function emptyBank(){return{schema:1,slots:Array.from({length:BANK_SIZE},emptySlot)}}
  function itemMeta(items,id){return items?.[String(id)]||items?.[id]||null}
  function isConsumable(items,id){const it=itemMeta(items,id);return !!(it&&(it.consumable===true||it.consumable===1||it.consumable==='1'))}
  function validSlot(x){const id=Number(x?.item??x?.itemId??x?.id),n=Math.floor(Number(x?.count));return Number.isInteger(id)&&id>=0&&Number.isFinite(n)&&n>0?{item:id,count:n}:emptySlot()}

  function putMigrated(bank,id,amount,items){
    let left=Math.max(0,Math.floor(Number(amount)||0));if(!left)return 0;
    const consumable=isConsumable(items,id);
    if(consumable){
      for(let i=0;i<BANK_SIZE&&left>0;i++){
        const s=bank.slots[i];if(s.item!==id)continue;const cap=i===0?SLOT0_STACK_MAX:NORMAL_STACK_MAX,take=Math.min(left,Math.max(0,cap-s.count));s.count+=take;left-=take;
      }
      for(let i=0;i<BANK_SIZE&&left>0;i++){
        const s=bank.slots[i];if(s.item!==EMPTY_ID||s.count!==0)continue;const cap=i===0?SLOT0_STACK_MAX:NORMAL_STACK_MAX,take=Math.min(left,cap);s.item=id;s.count=take;left-=take;
      }
    }else{
      while(left>0){const i=bank.slots.findIndex(s=>s.item===EMPTY_ID&&s.count===0);if(i<0)break;bank.slots[i]={item:id,count:1};left--}
    }
    return left;
  }

  function sanitizeInventory(raw,items){
    const out=emptyBank();
    if(!raw||typeof raw!=='object')return out;
    if(Array.isArray(raw.slots)){
      const src=raw.slots.slice(0,BANK_SIZE).map(validSlot);while(src.length<BANK_SIZE)src.push(emptySlot());
      // Repack only when metadata is available, so old/invalid Web stacks become native-shaped.
      if(items){for(const s of src)if(s.item>=0&&s.count>0)putMigrated(out,s.item,s.count,items);return out}
      out.slots=src;return out;
    }
    // Legacy r14 dictionary inventory: migrate deterministically without dropping known counts.
    const entries=Object.entries(raw).map(([k,v])=>[itemId(k),Math.floor(Number(v))]).filter(([id,n])=>id!==null&&Number.isFinite(n)&&n>0).sort((a,b)=>a[0]-b[0]);
    for(const [id,n] of entries)putMigrated(out,id,n,items);
    return out;
  }

  function count(inventory,id){
    const key=itemId(id);if(key===null)return 0;const bank=sanitizeInventory(inventory);return bank.slots.reduce((n,s)=>n+(s.item===key?s.count:0),0)
  }
  function firstEmpty(bank){return bank.slots.findIndex(s=>s.item===EMPTY_ID&&s.count===0)}
  function canAdd(inventory,id,amount=1,items){
    const key=itemId(id),n=Math.floor(Number(amount));if(key===null||!Number.isFinite(n)||n<=0)return false;
    const bank=sanitizeInventory(inventory,items);let room=0;
    if(isConsumable(items,key)){
      for(let i=0;i<BANK_SIZE;i++){const s=bank.slots[i],cap=i===0?SLOT0_STACK_MAX:NORMAL_STACK_MAX;if(s.item===key)room+=Math.max(0,cap-s.count);else if(s.item===EMPTY_ID&&s.count===0)room+=cap;if(room>=n)return true}
      return false;
    }
    return bank.slots.filter(s=>s.item===EMPTY_ID&&s.count===0).length>=n;
  }
  function tryAdd(inventory,id,amount=1,items){
    const key=itemId(id),n=Math.floor(Number(amount)),bank=sanitizeInventory(inventory,items);if(key===null||!Number.isFinite(n)||n<=0)return{ok:false,reason:'invalid',inventory:bank};
    if(!canAdd(bank,key,n,items))return{ok:false,reason:'full',inventory:bank};
    const left=putMigrated(bank,key,n,items);return left?{ok:false,reason:'full',inventory:bank}:{ok:true,inventory:bank}
  }
  function add(inventory,id,amount=1,items){return tryAdd(inventory,id,amount,items).inventory}
  function remove(inventory,id,amount=1,items){
    const key=itemId(id),n=Math.floor(Number(amount)),bank=sanitizeInventory(inventory,items);if(key===null||!Number.isFinite(n)||n<=0)return{ok:false,reason:'invalid',inventory:bank};
    if(count(bank,key)<n)return{ok:false,reason:'insufficient',inventory:bank};let left=n;
    // Native-style stable scan: consume from lower slot indexes first.
    for(let i=0;i<BANK_SIZE&&left>0;i++){const s=bank.slots[i];if(s.item!==key)continue;const take=Math.min(left,s.count);s.count-=take;left-=take;if(s.count<=0)bank.slots[i]=emptySlot()}
    return{ok:true,inventory:bank}
  }
  function changeSlot({inventory,slots,slot,itemId:newItem,items}){
    const idx=Number(slot);if(idx!==0&&idx!==1)return{ok:false,reason:'slot',inventory:sanitizeInventory(inventory,items),slots:normalizeSlots(slots)};
    const curSlots=normalizeSlots(slots),current=curSlots[idx],requested=newItem===null||newItem===undefined?null:itemId(newItem);
    if(newItem!==null&&newItem!==undefined&&requested===null)return{ok:false,reason:'item',inventory:sanitizeInventory(inventory,items),slots:curSlots};
    if(current===requested)return{ok:true,inventory:sanitizeInventory(inventory,items),slots:curSlots,changed:false};
    let next=sanitizeInventory(inventory,items);
    if(requested!==null){const taken=remove(next,requested,1,items);if(!taken.ok)return{ok:false,reason:'insufficient',inventory:next,slots:curSlots};next=taken.inventory}
    if(current!==null){const returned=tryAdd(next,current,1,items);if(!returned.ok)return{ok:false,reason:'full',inventory:sanitizeInventory(inventory,items),slots:curSlots};next=returned.inventory}
    const nextSlots=curSlots.slice();nextSlots[idx]=requested;return{ok:true,inventory:next,slots:nextSlots,changed:true}
  }
  function inventoryIds(inventory){return[...new Set(sanitizeInventory(inventory).slots.filter(s=>s.item>=0&&s.count>0).map(s=>s.item))].sort((a,b)=>a-b)}
  function usedSlots(inventory){return sanitizeInventory(inventory).slots.filter(s=>s.item>=0&&s.count>0).length}

  return{BANK_SIZE,EMPTY_ID,SLOT0_STACK_MAX,NORMAL_STACK_MAX,itemId,emptyBank,sanitizeInventory,normalizeSlots,count,canAdd,tryAdd,add,remove,changeSlot,inventoryIds,usedSlots,isConsumable};
});
