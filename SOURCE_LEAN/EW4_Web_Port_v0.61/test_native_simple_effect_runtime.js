'use strict';
const assert=require('assert');
const R=require('./native_simple_effect_runtime.js');
const D=require('./assets/data/native_simple_effects.json');
const b=D.effects.effect_build,r=D.effects.effect_recover;
assert(Math.abs(R.effectDuration(b)-1.5)<1e-9);assert(Math.abs(R.effectDuration(r)-1.4)<1e-9);
const pos=R.sampleAreaPosition({x0:10,x1:20,y0:30,y1:50},{width:8,height:4},()=>.5);assert.deepStrictEqual(pos,{x:15,y:40});
// Native area uses one shared interpolation RNG for x/y, then separate jitter RNGs.
const seq=[.25,.75,.1];let si=0;const exact=R.sampleAreaPosition({x0:10,x1:30,y0:40,y1:80},{width:8,height:10},()=>seq[si++]);
assert.deepStrictEqual(exact,{x:17,y:46});
assert(Math.abs(R.sampleTrack(b.lifetrack,.05,'a')-.5)<1e-9);assert.strictEqual(R.sampleTrack(b.lifetrack,.15,'a'),1);
// Native timetrack quantity is an emission rate, not a burst count. Simulate
// a normal 60-Hz update: build emits one particle over the 0.1s emitter life.
const inst=R.createInstance(b,{x:123,y:77},{rng:()=>.5});
for(let i=0;i<6;i++)R.advance(inst,1/60);
assert.strictEqual(inst.active,false);assert.strictEqual(inst.particles.length,1);assert.strictEqual(inst.particles[0].x,123);assert.strictEqual(inst.particles[0].y,77);
assert(R.isAlive(inst));
for(let i=0;i<90;i++)R.advance(inst,1/60);
assert.strictEqual(R.isAlive(inst),false);

// Recover uses the native uniform RGB 200/255 multiplier; the simple renderer
// must not silently drop it.
let filterSeen=null,draws=0;const fake={globalAlpha:1,filter:'none',globalCompositeOperation:'source-over',save(){this._ga=this.globalAlpha;this._f=this.filter;this._gco=this.globalCompositeOperation},restore(){this.globalAlpha=this._ga;this.filter=this._f;this.globalCompositeOperation=this._gco},translate(){},rotate(){},drawImage(){filterSeen=this.filter;draws++}};
const rp={x:0,y:0,age:.13,life:1.3};R.drawParticle(fake,{},r,rp,R.particleState(r,rp),1,{x:0,y:0});
assert.strictEqual(draws,1);assert(filterSeen&&filterSeen.startsWith('brightness(78.4313'));

// Native parser/runtime: mode=cont does not self-stop at emitter_life.
const cont={...b,emitter_life:.05,settings:{...b.settings,mode:'cont'},timetrack:[{time:0,quantity:30}]};
const ci=R.createInstance(cont,{x:0,y:0},{rng:()=>.5});for(let i=0;i<12;i++)R.advance(ci,1/60);
assert.strictEqual(R.isContinuous(cont),true);assert.strictEqual(ci.active,true);R.stopInstance(ci);assert.strictEqual(ci.active,false);
assert.strictEqual(R.isContinuous(b),false);

// Generic moving area effect: native init samples angle/speed/gravity/scale/color,
// then c93c0 updates position before gravity for the frame. With rng=.5 the
// -90..90 degree dust angle is 0 degrees and speed is 22.5 px/s.
const m=D.effects.effect_moving1;assert(m&&m.settings.mode==='cont');
const mi=R.createInstance(m,{x:0,y:0},{rng:()=>.5});R.advance(mi,1/60);assert.strictEqual(mi.particles.length,5);
R.advance(mi,1/60);assert.strictEqual(mi.particles.length,10);
const mp=mi.particles[0];assert(Math.abs(mp.x-.375)<1e-9);assert(Math.abs(mp.y)<1e-9);assert(Math.abs(mp.vy+.5)<1e-9);
const ms=R.particleState(m,mp);assert(ms.scale>.5&&ms.scale<2.4);assert(ms.alpha>0&&ms.alpha<1);
const water=D.effects.effect_moving4;assert.strictEqual(water.blend,'add');assert.strictEqual(R.isContinuous(water),true);


// Moving emitter segment changes must not drag already emitted particles with
// the unit. New particles spawn on the new segment; old particles stay in world
// space and only advance by their own velocity.
const trail=R.createInstance(m,{x:0,y:0},{rng:()=>.5,rect:{x0:0,y0:0,x1:10,y1:0}});R.advance(trail,1/60);
const oldX=trail.particles[0].x;trail.rect={x0:10,y0:0,x1:20,y1:0};R.advance(trail,1/60);
assert(trail.particles[0].x>oldX&&trail.particles[0].x<7,'old dust particle should remain near its old world position');
assert(trail.particles.slice(5).every(p=>p.x>=14&&p.x<=16),'new dust particles should spawn on the new emitter segment');

console.log('native simple effect runtime PASS: native rate accumulator + area spawn + native moving particle integration');
