'use strict';
const assert=require('assert');
const S=require('./battle_save_core.js');
const state={
 battle:{file:'campaign1_01.btl',title_cn:'土伦港之战'},map:'europe',mode:'campaign',playerOwner:0,round:7,
 resources:{money:123,industry:45,food:67},countryResources:{0:{money:123,industry:45,food:67},1:{money:88,industry:99,food:111}},cameraGeometry:'native-odd-r-64x54-v1',camera:{x:100,y:200,zoom:1.3},
 units:[{index:1,q:2,r:3,hp:88,max_hp:120,owner:0,dead:false,moved:true,attacked:false,moveAnim:{x:1},attackPoseUntil:999}],
 objects:[{pos:99,q:2,r:3,owner:0,construction_type:'city'}],ownership:[0,1,255],assignments:new Map([[1,7]]),
 installations:[{q:2,r:3,type:'trench',owner:0}],fireCells:new Set(['4,5']),nativeFiredEvents:new Set(['1:10']),nativeAppliedEvents:new Set(['2:20']),itemStores:{99:{slots:[{item:1,count:1,active:true}]}},taverns:{99:{count:1,slots:[{commander:3,money:1,industry:1,medal:0,round:1}]}},ended:null
};
const p=S.makePayload(state);assert(S.validate(p));assert.equal(p.cameraGeometry,'native-odd-r-64x54-v1');assert(!('moveAnim' in p.units[0]));assert(!('attackPoseUntil' in p.units[0]));
const n=S.normalize(JSON.parse(JSON.stringify(p)));assert.equal(n.round,7);assert.equal(n.camera.zoom,1);assert.equal(n.cameraGeometry,'native-odd-r-64x54-v1');assert.equal(n.assignments.get(1),7);assert(n.fireCells.has('4,5'));assert.equal(n.countryResources['1'].industry,99);assert(n.nativeFiredEvents.has('1:10'));assert(n.nativeAppliedEvents.has('2:20'));assert.equal(n.taverns['99'].slots[0].commander,3);assert.equal(n.itemStores['99'].slots[0].item,1);
const legacy={...p,schema:1};delete legacy.countryResources;const old=S.normalize(legacy);assert.equal(old.countryResources,null);
console.log('battle save core PASS',JSON.stringify({schema:p.schema,round:n.round,units:n.units.length,slots:'auto+1..6'}));
