const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const inv=JSON.parse(fs.readFileSync('assets/data/native_audio_inventory.json','utf8')),sw=fs.readFileSync('sw.js','utf8'),app=fs.readFileSync('app.js','utf8');
const wav=inv.audio_files.filter(x=>x.file.endsWith('.wav')),mp3=inv.audio_files.filter(x=>x.file.endsWith('.mp3'));
assert.equal(wav.length,38,'original APK WAV count');assert.equal(mp3.length,5,'original APK MP3 count');
for(const x of inv.audio_files){const p=`assets/audio/${x.file}`;assert(fs.existsSync(p),p);const sha=crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');assert.equal(sha,x.sha256,x.file);if(x.file.endsWith('.wav'))assert(sw.includes(`./assets/audio/${x.file}`),`precache ${x.file}`)}
assert(app.includes("fire:new Audio('assets/audio/sfx_fire.wav')"),'fire must use original APK filename');
assert(!fs.existsSync('assets/audio/sfx_fire_native.wav'),'legacy duplicate fire alias should be removed');
console.log(`native audio inventory PASS: ${wav.length} WAV + ${mp3.length} MP3 byte-identical to APK`);
