const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert');
const html=fs.readFileSync('index.html','utf8'),app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
assert(html.includes('native_maptext_core.js'));
assert(html.indexOf('compact_bile_runtime.js')<html.indexOf('native_maptext_core.js'));
assert(app.includes("loadNativeMapText(map);"));
assert(app.includes('drawNativeMapTextWorld(S.map,c)'));
assert(app.includes('EW4NativeMapText.drawPrepared(ctx,MAPTEXT_BILE,MAPTEXT_ATLAS,p)'));
for(const f of ['maptext.bin','maptext.xml','maptext.png','maptextpos_europe.xml','maptextpos_america.xml'])assert(sw.includes(`./assets/maptext_native/${f}`),`SW maptext cache ${f}`);
assert(sw.includes("'./native_maptext_core.js'"));
const base=path.join(__dirname,'assets','maptext_native');
for(const line of fs.readFileSync(path.join(base,'SHA256SUMS.txt'),'utf8').trim().split(/\n/)){
 const [sha,file]=line.trim().split(/\s+/);const got=crypto.createHash('sha256').update(fs.readFileSync(path.join(base,file))).digest('hex');assert.strictEqual(got,sha,file)
}
console.log('native maptext runtime PASS · original BILE/atlas/placements cached + battle world-layer draw wired');
