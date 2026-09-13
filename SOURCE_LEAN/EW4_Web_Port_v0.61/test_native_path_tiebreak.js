const fs=require('fs'),assert=require('assert');
const hex=require('./native_hex_core.js');
const app=fs.readFileSync('app.js','utf8');
assert.deepStrictEqual(hex.neighbors(10,4),[
  [11,4],[10,5],[9,5],[9,4],[9,3],[10,3]
], 'even-row native direction order must be E,SE,SW,W,NW,NE');
assert.deepStrictEqual(hex.neighbors(10,5),[
  [11,5],[11,6],[10,6],[9,5],[10,4],[11,4]
], 'odd-row native direction order must be E,SE,SW,W,NW,NE');
assert(/routeSerial=0/.test(app),'movement path must have an explicit insertion serial');
assert(/a\[2\]-b\[2\]\|\|a\[3\]-b\[3\]/.test(app),'equal movement cost must preserve native expansion insertion order');
assert(/costs\.get\(nk\)<=nc/.test(app),'equal-cost alternate predecessor must not replace the first native-direction predecessor');
console.log('PASS native movement route direction/tie-break contract');
