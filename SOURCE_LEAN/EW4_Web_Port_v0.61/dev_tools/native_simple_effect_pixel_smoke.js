'use strict';
const fs=require('fs'),path=require('path');
const {Canvas,Image}=require('skia-canvas');
const root=path.resolve(__dirname,'..');
const R=require(path.join(root,'native_simple_effect_runtime.js'));
const D=require(path.join(root,'assets/data/native_simple_effects.json'));
async function render(id,out){
 const canvas=new Canvas(256,256),ctx=canvas.getContext('2d'),atlas=new Image();
 atlas.src=fs.readFileSync(path.join(root,D.atlas));await atlas.decode();
 const e=D.effects[id],inst=R.createInstance(e,{x:0,y:0},{rng:()=>.5});
 for(let i=0;i<5;i++)R.advance(inst,1/60);
 const drew=R.drawInstance(ctx,atlas,inst,1,{x:128,y:128});
 const pixels=ctx.getImageData(0,0,256,256).data;let nonzero=0,alphaMax=0;
 for(let i=3;i<pixels.length;i+=4){if(pixels[i])nonzero++;alphaMax=Math.max(alphaMax,pixels[i])}
 fs.writeFileSync(out,await canvas.png);
 if(!drew||nonzero<10)throw new Error(`${id}: no meaningful pixels`);
 return{id,particles:inst.particles.length,nonzero,alphaMax,out};
}
(async()=>{
 const a=await render('effect_build','/mnt/data/effect_build_smoke.png');
 const b=await render('effect_recover','/mnt/data/effect_recover_smoke.png');
 console.log(JSON.stringify([a,b],null,2));
})().catch(e=>{console.error(e);process.exit(1)});
