'use strict';
const assert=require('assert');
const I=require('./item_inventory_core.js');
const items={
 '11':{id:11,consumable:'1'},
 '13':{id:13,consumable:'1'},
 '1':{id:1},'2':{id:2},'7':{id:7},'9':{id:9}
};

let bank=I.sanitizeInventory({'11':120,'1':2},items);
assert.strictEqual(bank.slots.length,28);
assert.strictEqual(I.count(bank,11),120);
assert.strictEqual(I.count(bank,1),2);
assert.strictEqual(I.usedSlots(bank),4); // deterministic legacy migration: two equipment slots + consumable 99/21 stacks
assert.deepStrictEqual(I.normalizeSlots([7,null]),[7,null]);

let r=I.tryAdd(I.emptyBank(),11,999,items);assert(r.ok);assert.strictEqual(r.inventory.slots[0].count,999);
assert.strictEqual(I.canAdd(r.inventory,11,1,items),true); // can spill into a nonzero 99-stack slot
r=I.tryAdd(r.inventory,11,99,items);assert(r.ok);assert.strictEqual(r.inventory.slots[1].count,99);

let eq=I.emptyBank();
r=I.tryAdd(eq,1,2,items);assert(r.ok);eq=r.inventory;assert.strictEqual(I.count(eq,1),2);assert.strictEqual(I.usedSlots(eq),2);assert.strictEqual(eq.slots[0].count,1);assert.strictEqual(eq.slots[1].count,1);

let full=I.emptyBank();for(let n=0;n<28;n++)full.slots[n]={item:1000+n,count:1};assert.strictEqual(I.canAdd(full,1,1,items),false);r=I.tryAdd(full,1,1,items);assert.strictEqual(r.ok,false);assert.strictEqual(r.reason,'full');

let inv=I.add(I.emptyBank(),9,1,items);r=I.changeSlot({inventory:inv,slots:[2,5],slot:1,itemId:9,items});assert(r.ok);assert.deepStrictEqual(r.slots,[2,9]);assert.strictEqual(I.count(r.inventory,5),1);assert.strictEqual(I.count(r.inventory,9),0);
r=I.changeSlot({inventory:r.inventory,slots:[2,9],slot:0,itemId:null,items});assert(r.ok);assert.deepStrictEqual(r.slots,[null,9]);assert.strictEqual(I.count(r.inventory,2),1);
r=I.changeSlot({inventory:I.emptyBank(),slots:[2,null],slot:1,itemId:7,items});assert.strictEqual(r.ok,false);assert.strictEqual(r.reason,'insufficient');

console.log('item inventory core PASS',JSON.stringify({slots:I.BANK_SIZE,slot0Max:I.SLOT0_STACK_MAX,normalMax:I.NORMAL_STACK_MAX}));
