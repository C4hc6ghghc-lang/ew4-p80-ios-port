'use strict';
const assert=require('assert');
const path=require('path');
const {Canvas,loadImage}=require('skia-canvas');
const R=require('./native_simple_effect_runtime.js');
const D=require('./assets/data/native_simple_effects.json');
(async()=>{
  const atlas=await loadImage(path.join(__dirname,D.atlas)),canvas=new Canvas(220,180),ctx=canvas.getContext('2d');
  const inst=R.createInstance(D.effects.effect_build,{x:0,y:0},{rng:()=>.5});
  for(let i=0;i<9;i++)R.advance(inst,1/60);
  assert.strictEqual(inst.particles.length,1);
  const drew=R.drawInstance(ctx,atlas,inst,1,{x:110,y:90});assert.strictEqual(drew,true);
  const data=ctx.getImageData(0,0,220,180).data;let alphaPixels=0,maxA=0;
  for(let i=3;i<data.length;i+=4){if(data[i])alphaPixels++;if(data[i]>maxA)maxA=data[i]}
  assert(alphaPixels>100,`expected visible raster pixels, got ${alphaPixels}`);assert(maxA>0);
  console.log(`native simple effect canvas PASS: build raster ${alphaPixels} nontransparent pixels, max alpha ${maxA}`);
})().catch(e=>{console.error(e);process.exit(1)});
