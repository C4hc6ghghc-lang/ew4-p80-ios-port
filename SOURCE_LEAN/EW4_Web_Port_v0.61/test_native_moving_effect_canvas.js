'use strict';
const assert=require('assert');
const path=require('path');
const {Canvas,loadImage}=require('skia-canvas');
const R=require('./native_simple_effect_runtime.js');
const D=require('./assets/data/native_simple_effects.json');
async function raster(id){
  const atlas=await loadImage(path.join(__dirname,D.atlas)),canvas=new Canvas(320,240),ctx=canvas.getContext('2d');
  const e=D.effects[id],inst=R.createInstance(e,{x:0,y:0},{rng:()=>.5,rect:{x0:0,y0:0,x1:0,y1:0}});
  for(let i=0;i<12;i++){inst.rect={x0:i*1.5,y0:0,x1:(i+1)*1.5,y1:0};R.advance(inst,1/60)}
  R.stopInstance(inst);const drew=R.drawInstance(ctx,atlas,inst,1,{x:130,y:140});assert.strictEqual(drew,true);
  const px=ctx.getImageData(0,0,320,240).data;let n=0,sr=0,sg=0,sb=0;for(let i=0;i<px.length;i+=4)if(px[i+3]){n++;sr+=px[i];sg+=px[i+1];sb+=px[i+2]}
  assert(n>200,`${id}: expected visible trail`);return{n,r:sr/n,g:sg/n,b:sb/n}
}
(async()=>{
  const dust=await raster('effect_moving1'),water=await raster('effect_moving4');
  assert(dust.r>dust.b,`dust should receive native brown RGB modulation: ${JSON.stringify(dust)}`);
  assert(Math.abs(water.r-water.g)<1&&Math.abs(water.g-water.b)<1,`water tint should stay neutral: ${JSON.stringify(water)}`);
  console.log(`native moving effect canvas PASS: dust ${dust.n}px + water ${water.n}px rasterized`);
})().catch(e=>{console.error(e);process.exit(1)});
