#!/usr/bin/env python3
import json, hashlib, pathlib, collections, sys
ROOT=pathlib.Path(__file__).resolve().parent
N=ROOT/'SOURCE_NATIVE/EW4_iOS_NativePort/Resources'
L=ROOT/'SOURCE_LEAN/EW4_Web_Port_v0.61'

def j(p): return json.loads(pathlib.Path(p).read_text())
def sha(p):
    h=hashlib.sha256(); h.update(pathlib.Path(p).read_bytes()); return h.hexdigest()
def same(a,b): return pathlib.Path(a).is_file() and pathlib.Path(b).is_file() and sha(a)==sha(b)
errors=[]
report={}
# world/maps
worlds=j(N/'Data/worldmaps.json')['worlds']
battles=j(N/'Data/battles_runtime.json')['battles']
map_names={1:'europe',2:'america'}
report['worlds']={k:{'width':v['width'],'height':v['height'],'cells':len(v['cells'])} for k,v in worlds.items()}
for k,v in worlds.items():
    if len(v['cells']) != v['width']*v['height']: errors.append(f'world cell count {k}')
map_dist=collections.Counter()
header_bounds_ok=unit_bounds_ok=object_bounds_ok=True
for b in battles:
    mid=b['header']['map_id']; map_dist[mid]+=1
    wn=map_names.get(mid)
    if wn not in worlds:
        errors.append(f"unknown map id {mid} {b['file']}"); continue
    w=worlds[wn]; h=b['header']; x0,y0=h['origin_x'],h['origin_y']; x1,y1=x0+h['width'],y0+h['height']
    if not (0<=x0<x1<=w['width'] and 0<=y0<y1<=w['height']):
        header_bounds_ok=False; errors.append(f"header out of world {b['file']}")
    for u in b['units']:
        if not (x0<=u['q']<x1 and y0<=u['r']<y1):
            unit_bounds_ok=False; errors.append(f"unit out of battle rect {b['file']}#{u['index']}")
    for o in b['objects']:
        if not (x0<=o['q']<x1 and y0<=o['r']<y1):
            object_bounds_ok=False; errors.append(f"object out of battle rect {b['file']}#{o['index']}")
report['battle_count']=len(battles)
report['battle_map_distribution']={str(k):v for k,v in sorted(map_dist.items())}
report['battle_header_bounds_ok']=header_bounds_ok
report['battle_unit_bounds_ok']=unit_bounds_ok
report['battle_object_bounds_ok']=object_bounds_ok
map_sha={}
for name in ['europe','america']:
    a=N/'Maps'/f'{name}.png'; b=L/'assets/maps'/f'{name}.png'
    ok=same(a,b); map_sha[name]={'native_sha256':sha(a),'frozen_sha256':sha(b),'identical':ok}
    if not ok: errors.append(f'map sha mismatch {name}')
report['map_sha']=map_sha
# animation/unit resolution
anim=j(N/'Data/native_animation_core877.json')
units=anim['units']; assets=anim['assets']
ungraded={'Privateer','Frigate','Battleship','Ironclad','Small Fortress','Fortress','Large Fortress','Coastal Fort'}
name_counts=collections.Counter(); resolved_counts=collections.Counter(); unresolved=[]; ready_missing=[]; resource_missing=[]
resolved=0
for b in battles:
    countries={c['index']:c['code'] for c in b['countries']}
    for u in b['units']:
        army=u['army_name']; name_counts[army]+=1; code=countries.get(u['owner'],'fra')
        if army in ungraded: key=army
        else:
            grade=max(1,u['grade']+1); national=f'{army} {code} {grade}'; generic=f'{army} {grade}'
            key=national if national in units else generic
        au=units.get(key)
        if not au:
            unresolved.append((b['file'],u['index'],army,code,u['grade'],key)); continue
        ready=next((m for m in au['motions'] if m['type']=='ready' and m['index']==0),None)
        if not ready or ready['asset'] not in assets:
            ready_missing.append((key, ready)); continue
        asset=assets[ready['asset']]
        res=asset['resource']
        for ext in ['bin','xml','png']:
            if not (N/'Bile'/f'{res}.{ext}').is_file(): resource_missing.append(f'{res}.{ext}')
        resolved+=1; resolved_counts[army]+=1
report['battle_unit_count']=sum(name_counts.values())
report['battle_unit_visual_resolved']=resolved
report['unit_family_counts']=dict(sorted(name_counts.items()))
report['unit_family_resolved']=dict(sorted(resolved_counts.items()))
report['unresolved_units']=unresolved[:50]
report['ready_missing']=ready_missing[:50]
report['resource_missing']=sorted(set(resource_missing))
if unresolved: errors.append(f'unresolved unit visuals {len(unresolved)}')
if ready_missing: errors.append(f'missing READY assets {len(ready_missing)}')
if resource_missing: errors.append(f'missing BILE resource files {len(set(resource_missing))}')
# all assets references and BILE frozen identity
resources=sorted({a['resource'] for a in assets.values()})
report['animation_units']=len(units); report['animation_assets']=len(assets); report['bile_resources']=resources
bile_identity={}
for res in resources:
    per={}; allok=True
    for ext in ['bin','xml','png']:
        a=N/'Bile'/f'{res}.{ext}'; b=L/'assets/bile_runtime'/f'{res}.{ext}'
        ok=same(a,b); allok &= ok
        per[ext]={'identical':ok,'native_sha256':sha(a) if a.is_file() else None,'frozen_sha256':sha(b) if b.is_file() else None}
        if not ok: errors.append(f'BILE sha mismatch {res}.{ext}')
    per['all_identical']=allok; bile_identity[res]=per
report['bile_identity']=bile_identity
# transport assets exact frozen parity
sprites=j(N/'sprite_manifest.json'); lean_sprites=j(L/'assets/sprite_manifest.json')
trans={}
for key,expected in {'transportship1.png':(151,170,70,107),'transportship2.png':(150,194,94,119)}.items():
    e=sprites.get(key); le=lean_sprites.get(key); ok=bool(e and le)
    if ok:
        got=(e['w'],e['h'],e['refx'],e['refy']); ok &= got==expected and e==le
        na=N/'Sprites'/e['file'].removeprefix('assets/sprites/'); la=L/e['file']; ok &= same(na,la)
        trans[key]={'manifest':e,'expected':expected,'manifest_identical':e==le,'asset_identical':same(na,la),'ok':ok}
    else: trans[key]={'ok':False}
    if not ok: errors.append(f'transport parity {key}')
report['transport_assets']=trans
# renderer transport contract
scene=(ROOT/'SOURCE_NATIVE/EW4_iOS_NativePort/NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift').read_text()
checks={
 'embarked_branch':'if unit.embarked && statType != "warship"' in scene,
 'transport_render':'renderTransportUnit(unit, gameplay: gameplay, store: store)' in scene,
 'armored_function12':'gameplay.hasEquipmentFunction(unit, function: 12)' in scene,
 'move_facing':'updateTransportFacing(unitIndex: unitIndex, desiredFacing: sample.facing, gameplay: gameplay)' in scene,
 'ready_skip':'if unit.embarked && statType != "warship" { continue }' in scene,
 'embark_refresh':'refreshUnitNode(unitIndex, gameplay: gameplay)' in scene,
}
report['native_transport_renderer_contract']=checks
if not all(checks.values()): errors.append('native transport renderer contract')
# HP/status + markers
status_keys=['hpbar_green.png','hpbar_blue.png','hpbar_red.png','hpbar_black.png']
status={}
for key in status_keys:
    e=sprites.get(key); ok=e is not None
    if ok:
        na=N/'Sprites'/e['file'].removeprefix('assets/sprites/'); la=L/e['file']; ok=same(na,la)
    status[key]=ok
    if not ok: errors.append(f'status sprite {key}')
markers={}
for i in range(22):
    key=f'mark_unit_{i}.png'; e=sprites.get(key); ok=e is not None
    if ok:
        na=N/'Sprites'/e['file'].removeprefix('assets/sprites/'); la=L/e['file']; ok=same(na,la)
    markers[key]=ok
    if not ok: errors.append(f'marker sprite {key}')
report['status_sprites']=status; report['army_markers_0_21']=markers
# known locked presentation source constants
lod=(ROOT/'SOURCE_NATIVE/EW4_iOS_NativePort/NativeCore/Sources/EW4NativeCore/NativePresentationLODCore.swift').read_text()
timing=(ROOT/'SOURCE_NATIVE/EW4_iOS_NativePort/NativeCore/Sources/EW4NativeCore/NativeAnimationTiming.swift').read_text()
report['presentation_source_contract']={
 'lod_threshold_0_5':'detailZoom = 0.5' in lod,
 'lod_min_0_76':'unitZoomMinimum = 0.76' in lod,
 'lod_max_1_18':'unitZoomMaximum = 1.18' in lod,
 'anchor_consumed':'nativeAnchor.x * scale' in timing and 'nativeAnchor.y * scale' in timing,
}
if not all(report['presentation_source_contract'].values()): errors.append('presentation source contract')
report['errors']=errors
# P79 dynamic battlefield overlay closure
# Verify every battle flag frame, battle commander portrait, morale marker and Native renderer route.
commanders=j(N/'Data/commanders.json')

def sprite_identity(key):
    e=sprites.get(key); le=lean_sprites.get(key)
    if not e or not le:
        return {'ok':False,'reason':'missing_manifest'}
    nr=N/'Sprites'/e['file'].removeprefix('assets/sprites/')
    lr=L/e['file']
    ok=(e==le and same(nr,lr))
    return {
      'ok':ok, 'manifest_identical':e==le,
      'asset_identical':same(nr,lr), 'manifest':e,
      'native_sha256':sha(nr) if nr.is_file() else None,
      'frozen_sha256':sha(lr) if lr.is_file() else None,
    }

def flag_code(raw):
    return {'gb':'gbr','fr':'fra','de':'pru'}.get((raw or '').lower(), (raw or '').lower())

# Country flags actually reachable in the frozen 101 battle runtime.
raw_country_codes=sorted({str(c.get('code') or '').lower() for b in battles for c in b.get('countries',[]) if c.get('code')})
canonical_country_codes=sorted({flag_code(x) for x in raw_country_codes})
flag_assets={}
flag_errors=[]
for raw in raw_country_codes:
    canonical=flag_code(raw)
    per=[]
    for frame in range(1,5):
        key=f'{canonical}{frame}.png'
        ev=sprite_identity(key)
        per.append({'key':key,**ev})
        if not ev['ok']:
            flag_errors.append(f'{raw}->{canonical}:{key}')
    flag_assets[raw]={'canonical':canonical,'frames':per,'ok':all(x['ok'] for x in per)}
flagpole_identity=sprite_identity('flagpole.png')
if not flagpole_identity['ok']: flag_errors.append('flagpole.png')
if flag_errors: errors.append(f'battle flag overlay assets {len(flag_errors)}')
report['battle_flag_overlay']={
  'raw_country_codes':raw_country_codes,
  'canonical_country_codes':canonical_country_codes,
  'legacy_aliases':{k:flag_code(k) for k in ['gb','fr','de']},
  'flagpole':flagpole_identity,
  'country_frames':flag_assets,
  'errors':flag_errors,
}

# Commander bubble assets for every valid commander used by the battle runtime.
commander_ids=sorted({int(u['commander_id']) for b in battles for u in b['units'] if u.get('commander_id') not in (None,0)})
commander_asset_results={}
commander_errors=[]
for cid in commander_ids:
    c=commanders.get(str(cid))
    if not c:
        commander_errors.append(f'missing commander data {cid}'); continue
    key=f"{c['name']}.png"
    ev=sprite_identity(key)
    commander_asset_results[str(cid)]={'name':c['name'],'key':key,**ev}
    if not ev['ok']: commander_errors.append(f'{cid}:{key}')
board_identity=sprite_identity('board_smallgenerals.png')
if not board_identity['ok']: commander_errors.append('board_smallgenerals.png')
if commander_errors: errors.append(f'battle commander overlay assets {len(commander_errors)}')
report['battle_commander_overlay']={
  'commander_id_count':len(commander_ids),
  'commander_ids':commander_ids,
  'board':board_identity,
  'portraits':commander_asset_results,
  'errors':commander_errors,
}

# Morale markers.
morale_keys=['morale_up.png','morale_down1.png','morale_down2.png','morale_down3.png']
morale_assets={k:sprite_identity(k) for k in morale_keys}
morale_errors=[k for k,v in morale_assets.items() if not v['ok']]
if morale_errors: errors.append(f'battle morale overlay assets {len(morale_errors)}')
report['battle_morale_overlay']={'assets':morale_assets,'errors':morale_errors}

# Current Native renderer must consume all three dynamic overlay branches for both normal and transport units.
overlay_core=(ROOT/'SOURCE_NATIVE/EW4_iOS_NativePort/NativeCore/Sources/EW4NativeCore/NativeBattlefieldOverlayCore.swift').read_text()
overlay_checks={
 'overlay_core_exists': bool(overlay_core),
 'native_scale_0_5': 'nativeAssetScale = 0.5' in overlay_core,
 'flag_120ms': 'flagFrameMilliseconds = 120.0' in overlay_core,
 'legacy_alias_gb': 'case "gb": return "gbr"' in overlay_core,
 'legacy_alias_fr': 'case "fr": return "fra"' in overlay_core,
 'legacy_alias_de': 'case "de": return "pru"' in overlay_core,
 'normal_path_overlay': scene.count('addNativeBattlefieldOverlays(to: tactical') >= 2,
 'flag_route': 'addNativeBattleFlag(to: container' in scene,
 'commander_route': 'addNativeCommanderBubble(to: container' in scene,
 'morale_route': 'installNativeMoraleMarker(to: container' in scene,
 'dynamic_flag_update': 'updateNativeBattlefieldOverlays(nowMilliseconds: now)' in scene,
 'flag_z_behind_unit': 'root.zPosition = 0' in scene and 'model.zPosition = 1' in scene,
 'commander_above_status': 'board.zPosition = 20' in scene and 'portrait.zPosition = 21' in scene,
 'morale_top': 'marker.zPosition = 22' in scene,
}
report['native_dynamic_overlay_renderer_contract']=overlay_checks
if not all(overlay_checks.values()): errors.append('native dynamic battlefield overlay renderer contract')

report['errors']=errors
out=ROOT/'P79_MAP_UNIT_DYNAMIC_OVERLAY_AUDIT.json'; out.write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps({
 'errors':errors,
 'battles':len(battles),
 'map_distribution':report['battle_map_distribution'],
 'worlds':report['worlds'],
 'unit_count':report['battle_unit_count'],
 'resolved':resolved,
 'unit_families':len(name_counts),
 'animation_units':len(units),
 'animation_assets':len(assets),
 'bile_resources':len(resources),
 'transport_ok':all(x['ok'] for x in trans.values()),
 'status_ok':all(status.values()),
 'markers_ok':all(markers.values()),
 'battle_flag_codes':len(raw_country_codes),
 'battle_flag_frames_ok':not flag_errors,
 'battle_commander_ids':len(commander_ids),
 'battle_commander_overlays_ok':not commander_errors,
 'morale_overlays_ok':not morale_errors,
 'dynamic_overlay_renderer_ok':all(overlay_checks.values()),
},ensure_ascii=False))
sys.exit(1 if errors else 0)
