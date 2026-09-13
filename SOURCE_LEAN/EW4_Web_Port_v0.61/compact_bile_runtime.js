'use strict';
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.EW4CompactBile=api})(typeof self!=='undefined'?self:globalThis,function(){
  const td=new TextDecoder('utf-8');
  function u16(v,o){return v.getUint16(o,true)}
  function u32(v,o){return v.getUint32(o,true)}
  function f32(v,o){return v.getFloat32(o,true)}
  function readAscii(bytes,o,n){let s='';for(let i=0;i<n;i++)s+=String.fromCharCode(bytes[o+i]);return s}
  function attrs(text){const out={};const re=/([A-Za-z_][\w:-]*)="([^"]*)"/g;let m;while((m=re.exec(text)))out[m[1]]=m[2];return out}
  function parseTextureXml(text){
    const images={};const re=/<Image\b([^>]*)\/?\s*>/g;let m;
    while((m=re.exec(text))){const a=attrs(m[1]);let n=a.name||'';if(n.endsWith('.png'))n=n.slice(0,-4);if(!n)continue;images[n]={x:+a.x||0,y:+a.y||0,w:+a.w||0,h:+a.h||0,refx:+a.refx||0,refy:+a.refy||0}}
    return images
  }
  function parseDefMotion(text){
    const units={},unitOrder=[];const ure=/<Unit\b([^>]*)>([\s\S]*?)<\/Unit>/g;let um;
    while((um=ure.exec(text))){const a=attrs(um[1]),motions=[];const mre=/<Motion\b([^>]*)\/?\s*>/g;let mm;
      while((mm=mre.exec(um[2]))){const b=attrs(mm[1]);motions.push({type:b.type||'',name:b.name||'',index:+b.index||0,dir:b.dir||'all',speed:b.speed==null?1:+b.speed,effect:b.effect||null})}
      const rec={name:a.name||'',res:a.res||'',x:+a.x||0,y:+a.y||0,dir:a.dir||null,motions};units[rec.name]=rec;unitOrder.push(rec.name)
    }
    return{units,unitOrder,unitCount:unitOrder.length,motionCount:unitOrder.reduce((n,k)=>n+units[k].motions.length,0)}
  }
  function selectMotion(unit,type,index=0,direction='all'){
    const matches=(unit?.motions||[]).filter(m=>m.type===type&&+m.index===+index);if(!matches.length)throw new Error(`No motion ${type}[${index}] for ${unit?.name||'unit'}`);
    const exact=matches.find(m=>m.dir===direction);if(exact)return exact;if(direction==='all'&&matches.length===1)return matches[0];const all=matches.find(m=>m.dir==='all');if(all)return all;throw new Error(`No direction ${direction} for ${unit?.name||'unit'} ${type}[${index}]`)
  }
  function mul(p,m){return[
    p[0]*m[0]+p[2]*m[1], p[1]*m[0]+p[3]*m[1],
    p[0]*m[2]+p[2]*m[3], p[1]*m[2]+p[3]*m[3],
    p[0]*m[4]+p[2]*m[5]+p[4], p[1]*m[4]+p[3]*m[5]+p[5]
  ]}
  function txPoint(M,x,y){return[M[0]*x+M[2]*y+M[4],M[1]*x+M[3]*y+M[5]]}
  class Bile{
    constructor(buffer,textureXml=''){
      const ab=buffer instanceof ArrayBuffer?buffer:buffer.buffer.slice(buffer.byteOffset,buffer.byteOffset+buffer.byteLength);this.bytes=new Uint8Array(ab);this.view=new DataView(ab);
      if(readAscii(this.bytes,0,4)!=='BILE')throw new Error('not BILE');this.version=u32(this.view,4);this.headerSize=u16(this.view,12);this.chunkCount=u16(this.view,14);this.fps=f32(this.view,16);this.chunks={};let off=this.headerSize;
      for(let i=0;i<this.chunkCount;i++){const tag=readAscii(this.bytes,off,4),size=u32(this.view,off+4);this.chunks[tag]={off,size};off+=size}
      this._parseStrings();this._parseItems();this._parseRecords();this.images=parseTextureXml(textureXml);this._buildStarts();this._kfCache=new Map()
    }
    _parseStrings(){const c=this.chunks.BRTS;if(!c)throw new Error('BRTS missing');this.strStart=c.off+12;this.strEnd=c.off+c.size}
    stringAt(offset){let s=this.strStart+offset,e=s;while(e<this.strEnd&&this.bytes[e]!==0)e++;return td.decode(this.bytes.subarray(s,e))}
    _parseItems(){const c=this.chunks.BMTI;if(!c)throw new Error('BMTI missing');const count=u32(this.view,c.off+8),st=c.off+16;this.items=[];this.nameToItem={};for(let i=0;i<count;i++){const o=st+i*56,nameOff=u32(this.view,o+4),it={idx:i,name:this.stringAt(nameOff),refx:f32(this.view,o+8),refy:f32(this.view,o+12),typ:u32(this.view,o+24),frames:u32(this.view,o+28),layers:u32(this.view,o+32),frameRecs:u32(this.view,o+36),indexRecs:u32(this.view,o+40)};this.items.push(it);this.nameToItem[it.name]=i}}
    _recordChunk(tag,recSize){const c=this.chunks[tag];if(!c)throw new Error(`${tag} missing`);const count=u32(this.view,c.off+8),st=c.off+16,out=[];for(let i=0;i<count;i++)out.push(st+i*recSize);return out}
    _parseRecords(){this.bele=this._recordChunk('BELE',44);this.bxdi=this._recordChunk('BXDI',8);this.bmrf=this._recordChunk('BMRF',8);this.byal=this._recordChunk('BYAL',8)}
    _buildStarts(){this.layerStart=[];this.frameStart=[];this.indexStart=[];let a=0,b=0,c=0;for(const it of this.items){this.layerStart.push(a);this.frameStart.push(b);this.indexStart.push(c);a+=it.layers;b+=it.frameRecs;c+=it.indexRecs}if(a!==this.byal.length||b!==this.bmrf.length||c!==this.bxdi.length)throw new Error('BILE record starts mismatch')}
    layerKeyframes(itemIdx){if(this._kfCache.has(itemIdx))return this._kfCache.get(itemIdx);const it=this.items[itemIdx],ls=this.layerStart[itemIdx],fs=this.frameStart[itemIdx],xs=this.indexStart[itemIdx],out=[];let fc=fs,xc=xs;for(let li=0;li<it.layers;li++){const n=u32(this.view,this.byal[ls+li]),layer=[];for(let k=0;k<n;k++){const bo=this.bmrf[fc+k],xo=this.bxdi[xc+k];layer.push({bmr:[u16(this.view,bo),u16(this.view,bo+2),u16(this.view,bo+4),u16(this.view,bo+6)],bxd:[u32(this.view,xo),u32(this.view,xo+4)]})}out.push(layer);fc+=n;xc+=n}this._kfCache.set(itemIdx,out);return out}
    beleValues(idx){const o=this.bele[idx];return[f32(this.view,o),f32(this.view,o+4),f32(this.view,o+8),f32(this.view,o+12),f32(this.view,o+16),f32(this.view,o+20),f32(this.view,o+24)]}
    keyAt(itemIdx,layerIdx,frame){const kfs=this.layerKeyframes(itemIdx)[layerIdx];let ci=0;for(let i=0;i<kfs.length;i++){if(kfs[i].bmr[0]<=frame)ci=i;else break}const cur=kfs[ci],bmr=cur.bmr,bxd=cur.bxd;let vals=this.beleValues(bxd[0]);if(ci+1<kfs.length&&bmr[1]===1){const nxt=kfs[ci+1];if(nxt.bmr[0]>bmr[0]&&nxt.bxd[1]===bxd[1]){const t=(frame-bmr[0])/(nxt.bmr[0]-bmr[0]),nv=this.beleValues(nxt.bxd[0]);vals=vals.map((v,i)=>v*(1-t)+nv[i]*t)}}const[a,b,c,d,tx,ty,alpha]=vals;return{bmr,bxd,M:[a,b,c,d,tx,ty],alpha}}
    flatten(itemIdx,frame,parent=[1,0,0,1,0,0],alpha=1,out=[],active=new Set()){
      if(active.has(itemIdx))return out;const it=this.items[itemIdx];if(!it)return out;if(it.typ===1){const info=this.images[it.name];if(info)out.push({name:it.name,M:parent.slice(),alpha,info});return out}
      active.add(itemIdx);try{frame=Math.max(0,Math.min(Math.trunc(frame),Math.max(0,it.frames-1)));for(let li=0;li<it.layers;li++){const rec=this.keyAt(itemIdx,li,frame),ref=rec.bxd[1];if(ref===0xffffffff)continue;const child=this.items[ref];if(!child)continue;const cf=child.typ===1?0:Math.max(0,Math.min(frame-rec.bmr[0],Math.max(0,child.frames-1)));this.flatten(ref,cf,mul(parent,rec.M),alpha*rec.alpha,out,active)}}finally{active.delete(itemIdx)}return out
    }
    bounds(prims){if(!prims.length)return[0,0,0,0];let minx=Infinity,miny=Infinity,maxx=-Infinity,maxy=-Infinity;for(const p of prims){const w=p.info.w,h=p.info.h;for(const[x,y]of [[0,0],[w,0],[0,h],[w,h]]){const q=txPoint(p.M,x,y);if(q[0]<minx)minx=q[0];if(q[0]>maxx)maxx=q[0];if(q[1]<miny)miny=q[1];if(q[1]>maxy)maxy=q[1]}}return[minx,miny,maxx,maxy]}
    motionUnion(itemIdx){const it=this.items[itemIdx];if(!it)throw new Error('item missing');let out=[Infinity,Infinity,-Infinity,-Infinity];for(let f=0;f<it.frames;f++){const b=this.bounds(this.flatten(itemIdx,f));out=[Math.min(out[0],b[0]),Math.min(out[1],b[1]),Math.max(out[2],b[2]),Math.max(out[3],b[3])]}return out}
    motionInfo(name){const idx=this.nameToItem[name];if(idx==null)throw new Error(`motion item not found: ${name}`);const it=this.items[idx];return{itemIndex:idx,frameCount:it.frames,fps:this.fps,worldUnion:this.motionUnion(idx)}}
    drawFrameXY(ctx,itemIdx,frame,atlasImage,originX=0,originY=0,scaleX=1,scaleY=1,globalAlpha=1){const prims=this.flatten(itemIdx,frame);ctx.save();ctx.translate(originX,originY);ctx.scale(scaleX,scaleY);for(const p of prims){const M=p.M,det=M[0]*M[3]-M[1]*M[2];if(Math.abs(det)<1e-4)continue;ctx.save();ctx.globalAlpha*=globalAlpha*p.alpha;ctx.transform(M[0],M[1],M[2],M[3],M[4],M[5]);const i=p.info;ctx.drawImage(atlasImage,i.x,i.y,i.w,i.h,0,0,i.w,i.h);ctx.restore()}ctx.restore();return prims.length}
    drawFrame(ctx,itemIdx,frame,atlasImage,originX=0,originY=0,scale=1,globalAlpha=1){return this.drawFrameXY(ctx,itemIdx,frame,atlasImage,originX,originY,scale,scale,globalAlpha)}
  }
  class BrowserPack{
    constructor(base='assets/bile_runtime'){this.base=base.replace(/\/$/,'');this.resources=new Map();this.defMotion=null;this.manifest=null}
    async loadManifest(){if(this.manifest)return this.manifest;this.manifest=await fetch(`${this.base}/manifest.json`).then(r=>{if(!r.ok)throw new Error(`manifest ${r.status}`);return r.json()});return this.manifest}
    async loadDefMotion(){if(this.defMotion)return this.defMotion;const t=await fetch(`${this.base}/def_motion.xml`).then(r=>{if(!r.ok)throw new Error(`def_motion ${r.status}`);return r.text()});this.defMotion=parseDefMotion(t);return this.defMotion}
    async loadResource(name){if(this.resources.has(name))return this.resources.get(name);const promise=Promise.all([fetch(`${this.base}/${name}.bin`).then(r=>r.arrayBuffer()),fetch(`${this.base}/${name}.xml`).then(r=>r.text())]).then(([bin,xml])=>({bile:new Bile(bin,xml),atlasUrl:`${this.base}/${name}.png`}));this.resources.set(name,promise);return promise}
    async resolve(unitName,type,index=0,direction='all'){const dm=await this.loadDefMotion(),unit=dm.units[unitName];if(!unit)throw new Error(`unit not found: ${unitName}`);const motion=selectMotion(unit,type,index,direction),res=await this.loadResource(unit.res);const itemIndex=res.bile.nameToItem[motion.name];return{unit,motion,itemIndex,...res}}
  }
  return{Bile,BrowserPack,parseTextureXml,parseDefMotion,selectMotion,mul,txPoint}
});
