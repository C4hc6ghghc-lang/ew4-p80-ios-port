#!/usr/bin/env python3
from __future__ import annotations
import argparse, io, json, math, struct, zipfile
from dataclasses import dataclass
from pathlib import Path
import xml.etree.ElementTree as ET
import numpy as np
import cv2
from PIL import Image, ImageDraw
from concurrent.futures import ThreadPoolExecutor

@dataclass
class Item:
    idx:int; name:str; refx:float; refy:float; typ:int; frames:int; layers:int; frame_recs:int; index_recs:int

class Bile:
    def __init__(self, blob:bytes, texture_xml:str, texture_png:bytes):
        self.blob=blob
        if blob[:4]!=b'BILE': raise ValueError('not BILE')
        self.version=struct.unpack_from('<I',blob,4)[0]
        self.header_size, self.chunk_count=struct.unpack_from('<HH',blob,12)
        self.fps=struct.unpack_from('<f',blob,16)[0]
        self.chunks={}
        off=self.header_size
        for _ in range(self.chunk_count):
            tag=blob[off:off+4].decode('ascii')
            size=struct.unpack_from('<I',blob,off+4)[0]
            self.chunks[tag]=(off,size)
            off += size
        self._parse_strings()
        self._parse_items()
        self._parse_records()
        self._parse_texture(texture_xml, texture_png)
        self._build_starts()

    def _parse_strings(self):
        off,size=self.chunks['BRTS']
        self.strdata=self.blob[off+12:off+size]
    def s(self,offset:int)->str:
        end=self.strdata.find(b'\0',offset)
        return self.strdata[offset:end].decode('utf-8','replace')
    def _parse_items(self):
        off,size=self.chunks['BMTI']; count=struct.unpack_from('<I',self.blob,off+8)[0]
        st=off+16; self.items=[]
        for i in range(count):
            r=self.blob[st+i*56:st+(i+1)*56]; v=struct.unpack('<14I',r)
            self.items.append(Item(i,self.s(v[1]),struct.unpack_from('<f',r,8)[0],struct.unpack_from('<f',r,12)[0],v[6],v[7],v[8],v[9],v[10]))
        self.name_to_item={x.name:x.idx for x in self.items}
    def _chunk_records(self,tag,recsize):
        off,size=self.chunks[tag]; count=struct.unpack_from('<I',self.blob,off+8)[0]; st=off+16
        return [self.blob[st+i*recsize:st+(i+1)*recsize] for i in range(count)]
    def _parse_records(self):
        self.bele=self._chunk_records('BELE',44)
        self.bxdi=self._chunk_records('BXDI',8)
        self.bmrf=self._chunk_records('BMRF',8)
        self.byal=self._chunk_records('BYAL',8)
    def _parse_texture(self,text,png):
        root=ET.fromstring('<Root>'+text.lstrip('\ufeff')+'</Root>')
        self.images={}
        for el in root.findall('.//Image'):
            n=el.get('name'); n=n[:-4] if n.endswith('.png') else n
            self.images[n]={k:(float(el.get(k)) if k in ('refx','refy') else int(el.get(k))) for k in ('x','y','w','h','refx','refy')}
        self.atlas=np.array(Image.open(io.BytesIO(png)).convert('RGBA'))
    def _build_starts(self):
        self.layer_start=[]; self.frame_start=[]; self.index_start=[]
        a=b=c=0
        for it in self.items:
            self.layer_start.append(a); self.frame_start.append(b); self.index_start.append(c)
            a+=it.layers; b+=it.frame_recs; c+=it.index_recs
        assert a==len(self.byal) and b==len(self.bmrf) and c==len(self.bxdi)
    def layer_keyframes(self,item_idx:int):
        it=self.items[item_idx]; ls=self.layer_start[item_idx]; fs=self.frame_start[item_idx]; xs=self.index_start[item_idx]
        out=[]; fc=fs; xc=xs
        for li in range(it.layers):
            n=struct.unpack_from('<I',self.byal[ls+li],0)[0]
            layer=[]
            for k in range(n):
                layer.append((struct.unpack('<4H',self.bmrf[fc+k]),struct.unpack('<2I',self.bxdi[xc+k])))
            out.append(layer); fc+=n; xc+=n
        return out
    def bele_values(self,idx:int):
        return np.array(struct.unpack_from('<7f',self.bele[idx],0),dtype=float)
    def key_at(self,item_idx,layer_idx,frame):
        kfs=self.layer_keyframes(item_idx)[layer_idx]
        ci=0
        for i,(bmr,bxd) in enumerate(kfs):
            if bmr[0]<=frame: ci=i
            else: break
        bmr,bxd=kfs[ci]; vals=self.bele_values(bxd[0])
        # BMRF field1==1 behaves as native transform tween. Interpolate only
        # while the referenced child remains the same; discrete child switches hold.
        if ci+1<len(kfs) and bmr[1]==1:
            nbmr,nbxd=kfs[ci+1]
            if nbmr[0]>bmr[0] and nbxd[1]==bxd[1]:
                t=(frame-bmr[0])/(nbmr[0]-bmr[0])
                vals=vals*(1-t)+self.bele_values(nbxd[0])*t
        a,b,c,d,tx,ty,alpha=vals
        M=np.array([[a,c,tx],[b,d,ty],[0,0,1]],dtype=float)
        return bmr,bxd,M,float(alpha)
    def flatten(self,item_idx:int,frame:int,parent=None,alpha=1.0,out=None,_active=None):
        if parent is None: parent=np.eye(3)
        if out is None: out=[]
        if _active is None: _active=set()
        # Some original army_artillery timelines contain an explicit self-reference
        # layer (e.g. 130..138 "stand straight" clips used by siege-artillery
        # Finish). Native playback cannot recursively expand that branch forever;
        # it functions as timeline/linkage metadata rather than additional drawable
        # geometry. Cut only references that would re-enter an item already on the
        # current expansion path. Normal repeated/shared children remain untouched.
        if item_idx in _active:
            return out
        it=self.items[item_idx]
        if it.typ==1:
            info=self.images.get(it.name)
            if info: out.append((it.name,parent.copy(),alpha,info))
            return out
        _active.add(item_idx)
        try:
            frame=max(0,min(int(frame),it.frames-1))
            for li in range(it.layers):
                bmr,bxd,M,a=self.key_at(item_idx,li,frame)
                ref=bxd[1]
                if ref==0xffffffff: continue
                child=self.items[ref]
                cf=0 if child.typ==1 else max(0,min(frame-bmr[0],child.frames-1))
                self.flatten(ref,cf,parent@M,alpha*a,out,_active)
        finally:
            _active.remove(item_idx)
        return out
    @staticmethod
    def bounds(prims):
        b=[]
        for _,M,_,inf in prims:
            pts=np.array([[0,0,1],[inf['w'],0,1],[0,inf['h'],1],[inf['w'],inf['h'],1]],float).T
            q=M@pts; b.append((q[0].min(),q[1].min(),q[0].max(),q[1].max()))
        return (min(x[0] for x in b),min(x[1] for x in b),max(x[2] for x in b),max(x[3] for x in b))
    @staticmethod
    def alpha_over(dst,src):
        s=src.astype(np.float32)/255; d=dst.astype(np.float32)/255
        sa=s[...,3:4]; da=d[...,3:4]; oa=sa+da*(1-sa)
        rgb=np.where(oa>1e-8,(s[...,:3]*sa+d[...,:3]*da*(1-sa))/np.maximum(oa,1e-8),0)
        return np.clip(np.concatenate([rgb,oa],-1)*255+0.5,0,255).astype(np.uint8)
    def render_fixed(self,item_idx:int,frame:int,world_box,pad=5):
        prims=self.flatten(item_idx,frame)
        minx,miny,maxx,maxy=world_box
        W=int(math.ceil(maxx-minx+2*pad)); H=int(math.ceil(maxy-miny+2*pad))
        dst=np.zeros((H,W,4),np.uint8)
        T=np.array([[1,0,-minx+pad],[0,1,-miny+pad],[0,0,1]],float)
        for name,M,alpha,inf in prims: # native layer order
            crop=self.atlas[inf['y']:inf['y']+inf['h'],inf['x']:inf['x']+inf['w']].copy()
            if alpha<.999: crop[...,3]=(crop[...,3].astype(float)*alpha).clip(0,255).astype(np.uint8)
            A=(T@M)[:2].astype(np.float32)
            # OpenCV's inverse-mapped affine rasterizer produces a full-frame smear
            # when a tween passes through a nearly singular matrix (native content
            # uses this briefly while flipping a limb). A forward renderer would
            # collapse the primitive to an almost zero-area line instead. Skip only
            # those mathematically collapsed instants; neighbouring frames preserve
            # the actual motion and avoid inventing a giant coloured rectangle.
            if abs(float(np.linalg.det(M[:2,:2]))) < 1e-4:
                continue
            warped=cv2.warpAffine(crop,A,(W,H),flags=cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT,borderValue=(0,0,0,0))
            dst=self.alpha_over(dst,warped)
        return Image.fromarray(dst)

def load_def_motion(apk:zipfile.ZipFile):
    text=apk.read('assets/def_motion.xml').decode('utf-8-sig')
    root=ET.fromstring(text)
    out={}
    for u in root.findall('Unit'):
        motions=[]
        for m in u.findall('Motion'):
            motions.append({
                'type': m.get('type'),
                'name': m.get('name'),
                'index': int(m.get('index') or 0),
                'dir': m.get('dir') or 'all',
                'speed': float(m.get('speed') or 1.0),
                'effect': m.get('effect'),
            })
        out[u.get('name')]={
            'res':u.get('res'),
            'x':int(u.get('x') or 0),
            'y':int(u.get('y') or 0),
            'dir':u.get('dir'),
            'motions':motions,
        }
    return out

def select_motion(unit_rec, motion_type, motion_index=0, direction='all'):
    matches=[m for m in unit_rec['motions'] if m['type']==motion_type and m['index']==motion_index]
    if not matches:
        raise KeyError(f'No motion {motion_type}[{motion_index}] for unit')
    # Land units usually use all. Ships/forts carry left/right and the caller can select it.
    exact=[m for m in matches if m['dir']==direction]
    if exact:
        return exact[0]
    if direction=='all' and len(matches)==1:
        return matches[0]
    all_dir=[m for m in matches if m['dir']=='all']
    if all_dir:
        return all_dir[0]
    raise KeyError(f'No direction {direction} for motion {motion_type}[{motion_index}]')

def extract_motion_to_dir(bile:Bile, unit_name:str, unit_rec:dict, motion_rec:dict, out:Path, compact=False):
    out=Path(out); out.mkdir(parents=True,exist_ok=True)
    motion_name=motion_rec['name']
    item_idx=bile.name_to_item[motion_name]; it=bile.items[item_idx]
    boxes=[bile.bounds(bile.flatten(item_idx,f)) for f in range(it.frames)]
    union=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
    # Frame rendering is independent and OpenCV/Numpy release the GIL for the
    # expensive raster operations, so a small thread pool gives a large speedup
    # without duplicating the atlas/BILE parse in memory.
    worker_count=min(8,max(1,it.frames))
    with ThreadPoolExecutor(max_workers=worker_count) as ex:
        frames=list(ex.map(lambda f: bile.render_fixed(item_idx,f,union,pad=5), range(it.frames)))
    frame_paths=[]
    if not compact:
        for f,im in enumerate(frames):
            p=out/f'frame_{f:03d}.png'; im.save(p); frame_paths.append(p)
    dur=max(1,round(1000/bile.fps))
    # Human preview is generated only in proof/debug mode. Production compact batches
    # avoid expensive animated-WebP encoding and keep only the deterministic sheet.
    if not compact:
        frames[0].save(out/'preview.webp',save_all=True,append_images=frames[1:],duration=dur,loop=0,lossless=True,method=4)

    # Runtime sheet: transparent, fixed-cell grid, no labels. This gives the Web
    # controller deterministic frame stepping and a hard stop at the native frame count.
    cols=min(8,max(1,len(frames))); rows=math.ceil(len(frames)/cols)
    fw,fh=frames[0].size
    runtime_sheet=Image.new('RGBA',(cols*fw,rows*fh),(0,0,0,0))
    for i,im in enumerate(frames):
        runtime_sheet.alpha_composite(im,((i%cols)*fw,(i//cols)*fh))
    runtime_sheet.save(out/'runtime_sheet.png',format='PNG',compress_level=1)

    # Debug contact sheet with frame numbers only in proof/debug mode.
    sheet_path=out/'sheet.jpg'
    if not compact:
        thumb_h=fh+16
        sh=Image.new('RGBA',(cols*fw,rows*thumb_h),(255,255,255,255)); dr=ImageDraw.Draw(sh)
        for i,im in enumerate(frames):
            x=(i%cols)*fw; y=(i//cols)*thumb_h
            sh.alpha_composite(im,(x,y+16)); dr.text((x+2,y+2),str(i),fill=(0,0,0,255))
        sh.convert('RGB').save(sheet_path,quality=90)

    meta={
        'format':'BILE','version':bile.version,'fps':bile.fps,'unit':unit_name,'resource':unit_rec['res'],
        'motion_type':motion_rec['type'],'motion_index':motion_rec['index'],'direction':motion_rec['dir'],
        'motion_name':motion_name,'item_index':item_idx,'frame_count':it.frames,
        'motion_speed_attr':motion_rec.get('speed',1.0),'effect':motion_rec.get('effect'),
        'native_anchor':{'x':unit_rec['x'],'y':unit_rec['y']},'world_union':list(map(float,union)),
        'fixed_canvas':{'w':fw,'h':fh,'padding':5},
        'runtime_sheet':{'file':'runtime_sheet.png','cols':cols,'rows':rows,'frame_w':fw,'frame_h':fh},
        'per_frame_bounds':[list(map(float,b)) for b in boxes]
    }
    (out/'manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
    if compact:
        for q in frame_paths: q.unlink(missing_ok=True)
    return meta

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--apk',required=True)
    ap.add_argument('--unit',default='Militia 1')
    ap.add_argument('--motion',default='attack',choices=['ready','undoready','attack','reload','finish','build'])
    ap.add_argument('--index',type=int,default=0,help='Native motion index, e.g. attack index 1 for alternate attack')
    ap.add_argument('--direction',default='all',choices=['all','left','right'])
    ap.add_argument('--out',required=True)
    ap.add_argument('--compact',action='store_true',help='Keep manifest + runtime sheet + animated preview only.')
    args=ap.parse_args()
    with zipfile.ZipFile(args.apk) as z:
        dm=load_def_motion(z); u=dm[args.unit]; res=u['res']; motion_rec=select_motion(u,args.motion,args.index,args.direction)
        bile=Bile(z.read(f'assets/{res}.bin'),z.read(f'assets/{res}.xml').decode('utf-8-sig'),z.read(f'assets/{res}.png'))
    meta=extract_motion_to_dir(bile,args.unit,u,motion_rec,Path(args.out),compact=args.compact)
    print(json.dumps(meta,ensure_ascii=False))

if __name__=='__main__': main()
