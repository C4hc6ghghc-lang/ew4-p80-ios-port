#!/usr/bin/env python3
import json,sys,zipfile,xml.etree.ElementTree as ET
from pathlib import Path

NAMES=['effect_mgunfire','effect_lightgun','effect_gunnery','effect_gunnery1','effect_rocket1']

def f(v,d=0.0):
    try:return float(v)
    except:return d

def parse_emitter(em,atlas):
    params={p.attrib.get('name'):p for p in em.findall('param')}
    settings=params['settings'].attrib.copy(); image=params['image'].attrib
    out={'emitter_name':em.attrib.get('name',''),'emitter_life':f(em.attrib.get('life')),
         'settings':settings,'image':image.get('file'),'particle_width':f(image.get('width')),'particle_height':f(image.get('height')),'blend':image.get('blend','alpha'),
         'atlas_rect':atlas[image.get('file')]}
    for key,prefix in [('life','particle_life'),('angle','angle'),('speed','speed'),('gravity','gravity'),('scale','scale'),('rotspeed','rotspeed')]:
        p=params.get(key);out[prefix+'_min']=f(p.attrib.get('min')) if p is not None else 0;out[prefix+'_max']=f(p.attrib.get('max')) if p is not None else out[prefix+'_min']
    rp=params.get('rotangle');out['rotangle_type']=rp.attrib.get('type','') if rp is not None else '';out['rotangle_min']=f(rp.attrib.get('min')) if rp is not None else 0;out['rotangle_max']=f(rp.attrib.get('max')) if rp is not None else 0
    cmin={};cmax={}
    for ch in 'rgba':
        p=params.get(ch);cmin[ch]=int(round(f(p.attrib.get('min'),255))) if p is not None else 255;cmax[ch]=int(round(f(p.attrib.get('max'),cmin[ch]))) if p is not None else cmin[ch]
    out['color_min']=cmin;out['color_max']=cmax
    if cmin==cmax:out['color']=cmin.copy()
    tt=params.get('timetrack');out['timetrack']=[{'time':f(x.attrib.get('time')),'quantity':f(x.attrib.get('quantity'))} for x in tt.findall('track')] if tt is not None else []
    lt=params.get('lifetrack');out['lifetrack']=[]
    if lt is not None:
        for x in lt.findall('track'):
            row={'life':f(x.attrib.get('life'))}
            for k in ['speed','gravity','scale','rotspeed','r','g','b','a']:row[k]=f(x.attrib.get(k),1 if k!='rotspeed' else 0)
            out['lifetrack'].append(row)
    return out

def main():
    if len(sys.argv)<3:raise SystemExit('usage: extract_native_combat_effects.py ORIGINAL.apk OUTPUT.json')
    apk,outp=Path(sys.argv[1]),Path(sys.argv[2])
    with zipfile.ZipFile(apk) as z:
        eff=z.read('assets/eff.xml');root=ET.fromstring(b'<EW4Atlas>'+eff+b'</EW4Atlas>');atlas={}
        for im in root.iter('Image'):
            a=im.attrib;atlas[a['name']]={k:int(a[k]) for k in ['x','y','w','h','refx','refy']}
        effects={}; flat={}; groups={}
        for name in NAMES:
            eroot=ET.fromstring(z.read('assets/'+name+'.xml'))
            emitters=[parse_emitter(em,atlas) for em in eroot.findall('emitter')]
            effects[name]={'source_xml':name+'.xml','effect_name':eroot.attrib.get('name',''),'emitters':emitters}
            seen={}; ids=[]
            for i,em in enumerate(emitters,1):
                base=em.get('emitter_name') or ('emitter%d'%i); seen[base]=seen.get(base,0)+1
                suffix=base if seen[base]==1 and sum(1 for x in emitters if (x.get('emitter_name') or '')==base)==1 else f'{base}{seen[base]}'
                eid=f'{name}__{suffix}'; flat[eid]={'source_xml':name+'.xml',**em}; ids.append(eid)
            groups[name+'.xml']=ids
    outp.write_text(json.dumps({'atlas':'assets/effects/eff.png','effects':effects,'flat_effects':flat,'groups':groups},ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':main()
