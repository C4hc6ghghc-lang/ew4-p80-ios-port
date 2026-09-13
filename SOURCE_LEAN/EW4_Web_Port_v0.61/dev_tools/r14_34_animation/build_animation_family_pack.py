#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, zipfile
from pathlib import Path
from collections import OrderedDict
from extract_bile_unit_animation import Bile, load_def_motion, extract_motion_to_dir

def slug(s:str):
    return ''.join(c.lower() if c.isalnum() else '_' for c in s).strip('_')

def asset_id(res, rec):
    sig=f"{res}|{rec['type']}|{rec['index']}|{rec['dir']}|{rec['name']}"
    h=hashlib.sha1(sig.encode('utf-8')).hexdigest()[:10]
    return f"{slug(res)}__{rec['type']}_i{rec['index']}_{rec['dir']}__{h}"

def main():
    ap=argparse.ArgumentParser(description='Build a deduplicated native animation pack for one EW4 unit-name family.')
    ap.add_argument('--apk',required=True)
    ap.add_argument('--prefix',help='Exact def_motion name prefix, e.g. Militia')
    ap.add_argument('--unit',action='append',default=[],help='Exact unit name; repeatable. Overrides/extends --prefix selection.')
    ap.add_argument('--out',required=True)
    args=ap.parse_args()
    apk=Path(args.apk); out=Path(args.out); assets_dir=out/'assets'; assets_dir.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(apk) as z:
        dm=load_def_motion(z)
        units=list(args.unit)
        if args.prefix:
            units += [n for n in dm if n.startswith(args.prefix)]
        units=list(dict.fromkeys(units))
        if not units: raise SystemExit('No units selected')
        missing=[u for u in units if u not in dm]
        if missing: raise SystemExit('Unknown unit(s): '+', '.join(missing))
        resources={dm[n]['res'] for n in units}
        bile_cache={r:Bile(z.read(f'assets/{r}.bin'),z.read(f'assets/{r}.xml').decode('utf-8-sig'),z.read(f'assets/{r}.png')) for r in resources}

        unique=OrderedDict()
        unit_map={}
        for name in units:
            u=dm[name]
            mlist=[]
            for rec in u['motions']:
                aid=asset_id(u['res'],rec)
                key=(u['res'],rec['name'])
                unique.setdefault(key,(name,u,rec,aid))
                mlist.append({'type':rec['type'],'index':rec['index'],'direction':rec['dir'],'asset':aid,'speed':rec.get('speed',1.0),'effect':rec.get('effect')})
            unit_map[name]={'resource':u['res'],'native_anchor':{'x':u['x'],'y':u['y']},'dir':u.get('dir'),'motions':mlist}

        asset_manifest={}
        total=len(unique)
        for i,((res,motion_name),(rep_name,u,rec,aid)) in enumerate(unique.items(),1):
            target=assets_dir/aid
            if (target/'manifest.json').exists() and (target/'runtime_sheet.png').exists():
                meta=json.loads((target/'manifest.json').read_text(encoding='utf-8'))
                status='reuse'
            else:
                meta=extract_motion_to_dir(bile_cache[res],rep_name,u,rec,target,compact=True)
                status='ok'
            asset_manifest[aid]={
                'resource':res,'motion_name':motion_name,'motion_type':rec['type'],'motion_index':rec['index'],'direction':rec['dir'],
                'frame_count':meta['frame_count'],'fps':meta['fps'],'fixed_canvas':meta['fixed_canvas'],'runtime_sheet':meta['runtime_sheet'],
                'motion_speed_attr':meta.get('motion_speed_attr',1.0),'effect':meta.get('effect'),
                'representative_unit':rep_name,
            }
            print(f'[{i}/{total}] [{status}] {aid} <- {rep_name} / {rec["type"]}[{rec["index"]}]/{rec["dir"]}',flush=True)

    family={
        'format':'EW4_NATIVE_ANIMATION_FAMILY_V1','source_apk':apk.name,'prefix':args.prefix,'selected_units':units,
        'unit_count':len(units),'unique_asset_count':len(asset_manifest),'fps':24,
        'units':unit_map,'assets':asset_manifest,
    }
    (out/'family_manifest.json').write_text(json.dumps(family,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'unit_count':len(units),'unique_asset_count':len(asset_manifest),'out':str(out)},ensure_ascii=False))

if __name__=='__main__': main()
