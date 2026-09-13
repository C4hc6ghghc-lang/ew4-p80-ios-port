'use strict';
const assert=require('assert');
const U=require('./native_upgrade_core.js');
const S=require('./native_campaign_session_core.js');

// Pre-P21 migration: Stars did not exist, so historical best scores become the wallet exactly once.
const legacy={campaignProgress:{'campaign1_01.btl':1,'campaign1_02.btl':2,'campaign1_03.btl':1},campaignBestRating:{'campaign1_01.btl':3}};
let n=S.normalizeSave({...legacy,campaignStars:0,warzoneTech:null},legacy);
assert.equal(n.campaignStars,9); // 3 + legacy progress2=>5 + progress1=>1
assert.equal(n.warzoneTech,null);
// Once Stars exist in persisted data, even zero is authoritative and must not remigrate.
n=S.normalizeSave({...legacy,campaignStars:0}, {...legacy,campaignStars:0});assert.equal(n.campaignStars,0);

let st=S.normalizeSave({campaignStars:998,campaignProgress:{},campaignBestRating:{},campaignCompletedZones:{},campaignCompletionEarned:{}},{campaignStars:998});
let r=S.recordResult(st,'campaign1_01.btl',5);assert.equal(r.delta,5);assert.equal(r.state.campaignStars,U.MAX_STARS);assert.equal(S.bestRating(r.state,'campaign1_01.btl'),5);
let replay=S.recordResult(r.state,'campaign1_01.btl',2);assert.equal(replay.delta,0);assert.equal(replay.state.campaignStars,U.MAX_STARS);assert.equal(S.bestRating(replay.state,'campaign1_01.btl'),5);

const reward={medal:50,badge:1,score:1};let z=S.recordZoneCompletion(replay.state,2,reward);assert(z.applied);assert.deepEqual(z.state.campaignCompletionEarned,{medals:50,badges:1,score:1});
let z2=S.recordZoneCompletion(z.state,2,reward);assert(!z2.applied);assert.deepEqual(z2.state.campaignCompletionEarned,{medals:50,badges:1,score:1});

// Repeated JSON persistence must not drift campaign meta fields.
let stable=z2.state;const canonical=JSON.stringify(S.normalizeSave(stable,stable));for(let i=0;i<250;i++)stable=S.storageRoundTrip(stable,stable);assert.equal(JSON.stringify(stable),canonical);
console.log('P25 campaign session core + migration/idempotence: PASS');
