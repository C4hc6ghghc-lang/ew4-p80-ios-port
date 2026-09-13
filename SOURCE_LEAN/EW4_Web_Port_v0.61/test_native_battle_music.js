'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const app=fs.readFileSync('app.js','utf8'),sw=fs.readFileSync('sw.js','utf8');
const expected={
 'battle1.mp3':'236a006d0d8d58d6ee55df958cfc246b10d5eb697f2f92b8c05cdde6dfcc87e0',
 'battle2.mp3':'94c8b0ecc6153d93483232be9d13d19ad2267df45bcf1e10be94d5cd9789b6f0',
 'battle3.mp3':'0e296554c5b419e21aad97a2d7a7b3c759fdb348d26e3a888b7effb84fe45e7a',
 'battle4.mp3':'7f0f6dfb62dc4cc72faee33ea93cc98e5358cea68a66f1057c17d61825b0c3d4'
};
for(const [name,sha] of Object.entries(expected)){
 const p=`assets/audio/${name}`;assert(fs.existsSync(p),p);
 const got=crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');assert.equal(got,sha,`${name} SHA-256`);
 assert(sw.includes(`./assets/audio/${name}`),`${name} precache`);
}
assert(app.includes("const ORIGINAL_BATTLE_MUSIC=Object.freeze(['battle1.mp3','battle2.mp3','battle3.mp3','battle4.mp3'])"));
assert(app.includes('Math.floor(Math.random()*ORIGINAL_BATTLE_MUSIC.length)'),'native rand()%4 equivalent missing');
assert(app.includes('musicTrack:chooseOriginalBattleMusic()'),'battle scene must choose one original track');
assert(app.includes('setBattleMusicTrack(battleState.musicTrack)'),'chosen track not armed');
assert(app.includes('bgVol:50,seVol:50'),'original BGVol default 50 missing');
assert(app.includes('au.volume=bgVolume()'),'battle music must follow BGVol');
console.log('native battle music PASS: 4 APK tracks restored, randomized per battle scene, BGVol-driven with original 50% default');
