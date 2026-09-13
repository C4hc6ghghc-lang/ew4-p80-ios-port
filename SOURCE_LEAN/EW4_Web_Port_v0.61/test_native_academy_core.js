'use strict';
const fs=require('fs'),assert=require('assert');
const A=require('./native_academy_core');
const commanders=JSON.parse(fs.readFileSync('assets/data/commanders.json','utf8'));

function seqRng(values){let i=0;return()=>values[i++%values.length]}
const owned=[201,202,203,204,205,206,207,208];
const pools=A.initializePools({commanders,owned,rng:seqRng([0,.17,.41,.63,.82,.29,.51,.73,.11,.36,.58,.91])});
assert.strictEqual(pools['6'].length,6);
assert.strictEqual(pools['4'].length,4);
assert.strictEqual(pools['2'].length,2);
const ids=[...pools['6'],...pools['4'],...pools['2']];
assert.strictEqual(new Set(ids).size,12,'academy candidates must be globally unique');
for(const key of A.TIER_ORDER){
  const cfg=A.config(key);
  for(const id of pools[key]){
    const c=commanders[String(id)];
    assert(c,`missing commander ${id}`);
    assert(Number(c.drawlots)!==0,`drawlots=0 leaked: ${id}`);
    assert(!owned.includes(+id),`owned commander leaked: ${id}`);
    assert(+c.star>=cfg.minStar&&+c.star<=cfg.maxStar,`${id} star ${c.star} outside ${cfg.minStar}-${cfg.maxStar}`);
  }
}

const old6=[...pools['6']],old4=[...pools['4']],old2=[...pools['2']];
const refreshed=A.refreshTier({commanders,owned,pools,tier:'6',rng:()=>0});
assert.deepStrictEqual(refreshed['4'],old4,'refreshing 6-tier must preserve 4-tier');
assert.deepStrictEqual(refreshed['2'],old2,'refreshing 6-tier must preserve 2-tier');
assert.strictEqual(refreshed['6'].length,6);
assert.strictEqual(refreshed['6'].filter(id=>old6.includes(id)).length,0,'native staging excludes the tier currently on screen');
assert.strictEqual(new Set([...refreshed['6'],...old4,...old2]).size,12);

// Small synthetic population proves drawlots + owned + sequential de-duplication,
// independently from the APK's convenient ID/star ordering.
const mini={};
for(let id=1;id<=12;id++)mini[id]={id,star:id<=8?1:2,drawlots:1};
mini[1].drawlots=0;
const one=A.refreshTier({commanders:mini,owned:[2],pools:{'6':[],'4':[],'2':[]},tier:'6',rng:()=>0});
assert.strictEqual(one['6'].length,6);
assert(!one['6'].includes(1));
assert(!one['6'].includes(2));
assert.strictEqual(new Set(one['6']).size,6);

assert(A.structurallyValid(pools,commanders));
// Native purchase 0x5E890 writes -1 into only the purchased slot. Persist the
// hole until the user explicitly refreshes that tier; do not auto-refill.
const boughtId=pools['4'][1],withHole=A.clearCandidate(pools,'4',boughtId);
assert.strictEqual(withHole['4'].length,4);
assert.strictEqual(withHole['4'][1],null);
assert.deepStrictEqual(withHole['6'],pools['6']);
assert.deepStrictEqual(withHole['2'],pools['2']);
assert(A.structurallyValid(withHole,commanders),'a native post-purchase empty slot is a valid persisted academy state');
const refilled=A.refreshTier({commanders,owned:[...owned,boughtId],pools:withHole,tier:'4',rng:()=>0});
assert.strictEqual(refilled['4'].length,4);
assert(refilled['4'].every(Boolean));
assert(!refilled['4'].includes(boughtId));
const invalid={...pools,'6':[pools['6'][0],pools['6'][0],...pools['6'].slice(2)]};
assert(!A.structurallyValid(invalid,commanders));

// Native purchase-price contract (x86_64 0x5E4C0/0x5E720/0x5E780/0x5E890):
// slot+4 is commander `price` (medals), slot+8 is the star-derived badge table.
assert.deepStrictEqual(A.prices(commanders['1']),{medal:0,badge:8});      // Napoleon, 8-star: badge-only
assert.deepStrictEqual(A.prices(commanders['15']),{medal:0,badge:6});    // Moreau, 7-star: badge-only
assert.deepStrictEqual(A.prices(commanders['31']),{medal:935,badge:4});  // Wittgenstein, 6-star: either currency
assert.deepStrictEqual(A.prices(commanders['70']),{medal:740,badge:3});  // Cornplanter, 5-star: either currency
assert.deepStrictEqual(A.prices(commanders['105']),{medal:475,badge:0}); // Cronstedt, 3-star: medal-only
assert.deepStrictEqual(A.prices(commanders['200']),{medal:405,badge:0}); // Kienmayer, 1-star: medal-only
assert(A.canUseCurrency(commanders['31'],'medal'));
assert(A.canUseCurrency(commanders['31'],'badge'));
assert(!A.canUseCurrency(commanders['1'],'medal'));
assert(!A.canUseCurrency(commanders['105'],'badge'));

console.log('native academy core PASS');
