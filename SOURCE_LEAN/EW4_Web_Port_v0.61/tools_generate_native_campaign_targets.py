#!/usr/bin/env python3
import json, struct, hashlib, pathlib, sys
src=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data/ew4_p17_apk/assets')
out=pathlib.Path(sys.argv[2] if len(sys.argv)>2 else 'assets/data/native_campaign_targets.json')
MAP_WIDTH={1:79,2:55}
result={'format':'EW4 native campaign targets v1','evidence':{'header_bytes':72,'country_stride':180,'map_cell_owner_stride':1,'map_state_stride':16,'unit_state_stride':32,'map_target_byte':10,'unit_target_byte':19,'country_side_i32_offset':16},'battles':{}}
sha=hashlib.sha256(); totals={'battles':0,'map_type1':0,'map_type2':0,'unit_type1':0,'unit_type2':0}
for p in sorted(src.glob('*.btl')):
    data=p.read_bytes(); sha.update(p.name.encode()+b'\0'+data)
    if len(data)<72: continue
    h=struct.unpack_from('<18i',data,0); version,map_id,ox,oy,w,hgt,country_n,obj_n,unit_n,*_=h
    mw=MAP_WIDTH.get(map_id)
    if not mw: continue
    countries=[]
    for i in range(country_n):
        off=72+i*180
        if off+180>len(data): raise SystemExit(f'{p.name}: truncated country table')
        player_marker=struct.unpack_from('<i',data,off+12)[0]
        side=struct.unpack_from('<i',data,off+16)[0]
        countries.append({'owner':i,'side':side,'player_marker':player_marker})
    off=72+country_n*180+w*hgt
    maps=[]
    for i in range(obj_n):
        rec=data[off+i*16:off+(i+1)*16]
        if len(rec)!=16: raise SystemExit(f'{p.name}: truncated map-state table')
        t=rec[10]
        if t not in (1,2): continue
        pos=struct.unpack_from('<H',rec,0)[0]
        maps.append({'record_index':i,'pos':pos,'q':pos%mw,'r':pos//mw,'type':t})
        totals[f'map_type{t}']+=1
    off+=obj_n*16
    units=[]
    for i in range(unit_n):
        rec=data[off+i*32:off+(i+1)*32]
        if len(rec)!=32: raise SystemExit(f'{p.name}: truncated unit-state table')
        t=rec[19]
        if t not in (1,2): continue
        pos=struct.unpack_from('<H',rec,0)[0]
        units.append({'unit_index':i,'pos':pos,'q':pos%mw,'r':pos//mw,'type':t})
        totals[f'unit_type{t}']+=1
    result['battles'][p.name]={'map_id':map_id,'countries':countries,'map_targets':maps,'unit_targets':units}
    totals['battles']+=1
result['source_corpus_sha256']=sha.hexdigest(); result['totals']=totals
out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(result,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print(json.dumps(totals,ensure_ascii=False))
print('type2 stages:')
for name,b in result['battles'].items():
    hits=[x for x in b['map_targets']+b['unit_targets'] if x['type']==2]
    if hits: print(name,hits)
