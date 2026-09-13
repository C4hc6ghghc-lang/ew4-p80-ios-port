#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, os, re, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Resources"
CORE = ROOT / "NativeCore"
IOS = ROOT / "iOSApp"
DOCS = ROOT / "Docs"
MANIFEST = DOCS / "NATIVE_RESOURCE_MANIFEST_SHA256.tsv"

ESSENTIAL = [
    "Data/battles_runtime.json",
    "Data/worldmaps.json",
    "Data/army_stats.json",
    "Data/commanders.json",
    "Data/native_animation_core877.json",
    "Data/original_layout-568h.xml",
    "Bile/def_motion.xml",
    "Maps/europe.png",
    "Maps/america.png",
    "Audio/battle1.mp3",
    "Audio/battle2.mp3",
    "Audio/battle3.mp3",
    "Audio/battle4.mp3",
    "Audio/defeat_music.mp3",
    "sprite_manifest.json",
]

BUILD_RELEVANT_SUFFIXES = {".swift", ".yml", ".yaml", ".sh", ".py"}
FORBIDDEN_NATIVE_TOKENS = [
    "import WebKit",
    "import JavaScriptCore",
    "WKWebView",
    "evaluateJavaScript",
    "JSContext(",
]

class Gate:
    def __init__(self):
        self.checks=[]
        self.errors=[]
        self.warnings=[]
    def ok(self,name,detail=""):
        self.checks.append({"name":name,"status":"PASS","detail":detail})
    def fail(self,name,detail):
        self.checks.append({"name":name,"status":"FAIL","detail":detail})
        self.errors.append(f"{name}: {detail}")
    def warn(self,name,detail):
        self.checks.append({"name":name,"status":"WARN","detail":detail})
        self.warnings.append(f"{name}: {detail}")

def sha256_file(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()

def load_manifest(path: Path):
    rows={}
    lines=path.read_text(encoding='utf-8').splitlines()
    if not lines or lines[0] != 'path\tsize_bytes\tsha256':
        raise ValueError('bad manifest header')
    for line in lines[1:]:
        rel,size,sha=line.split('\t')
        rows[rel]=(int(size),sha)
    return rows

def text(path: Path) -> str:
    return path.read_text(encoding='utf-8')

def require_literal(g: Gate, path: Path, pattern: str, name: str):
    s=text(path)
    if re.search(pattern,s,re.M): g.ok(name,str(path.relative_to(ROOT)))
    else: g.fail(name,f"missing frozen pattern {pattern!r} in {path.relative_to(ROOT)}")

def main():
    ap=argparse.ArgumentParser(description='EW4 Native IPA preflight / noon-regression guard')
    ap.add_argument('--report', default=str(DOCS/'NATIVE_IPA_PREFLIGHT_REPORT.json'))
    ap.add_argument('--no-hash', action='store_true', help='skip full resource hash verification')
    args=ap.parse_args()
    g=Gate()

    # 1) Tree + essential runtime resources.
    for p in [RES, CORE, IOS, MANIFEST]:
        if p.exists(): g.ok(f"exists:{p.name}",str(p.relative_to(ROOT)))
        else: g.fail(f"exists:{p.name}","missing")
    missing=[x for x in ESSENTIAL if not (RES/x).is_file()]
    if missing: g.fail('essential_resources',f"missing {missing}")
    else: g.ok('essential_resources',f"{len(ESSENTIAL)}/{len(ESSENTIAL)} present")

    # 2) Resource namespace integrity. This project MUST preserve directories.
    files=[p for p in RES.rglob('*') if p.is_file()]
    bybase=defaultdict(list)
    for p in files: bybase[p.name.casefold()].append(str(p.relative_to(RES)))
    dup={k:v for k,v in bybase.items() if len(v)>1}
    g.ok('resource_inventory',f"files={len(files)} bytes={sum(p.stat().st_size for p in files)} duplicate_basename_groups={len(dup)}")

    spec=text(IOS/'project.yml')
    folder_pattern=r"-\s*path:\s*\.\./Resources\s*\n\s*type:\s*folder\s*\n(?:\s*#[^\n]*\n)*\s*buildPhase:\s*\n\s*copyFiles:\s*\n\s*destination:\s*resources\s*\n\s*subpath:\s*GameAssets"
    if re.search(folder_pattern,spec,re.M):
        g.ok('xcodegen_resource_folder_reference',f"folder reference required; duplicate basename groups={len(dup)}")
    else:
        g.fail('xcodegen_resource_folder_reference',"../Resources must be type: folder + copyFiles into GameAssets; flattening can overwrite duplicate basenames")

    # 3) Full resource hash contract.
    if not args.no_hash:
        try:
            expected=load_manifest(MANIFEST)
            actual={str(p.relative_to(RES)).replace(os.sep,'/'):(p.stat().st_size,sha256_file(p)) for p in files}
            missing_keys=sorted(set(expected)-set(actual))
            extra_keys=sorted(set(actual)-set(expected))
            changed=sorted(k for k in set(expected)&set(actual) if expected[k]!=actual[k])
            if missing_keys or extra_keys or changed:
                g.fail('resource_sha256_manifest',f"missing={len(missing_keys)} extra={len(extra_keys)} changed={len(changed)} samples={{'missing':missing_keys[:5],'extra':extra_keys[:5],'changed':changed[:5]}}")
            else:
                g.ok('resource_sha256_manifest',f"{len(expected)}/{len(expected)} exact")
        except Exception as e:
            g.fail('resource_sha256_manifest',repr(e))

    # 4) No old-container dependency and no JS/Web runtime shortcut in native build inputs.
    bad_abs=[]; bad_web=[]
    scan_roots=[CORE, IOS]
    for base in scan_roots:
        if not base.exists(): continue
        for p in base.rglob('*'):
            if '.build' in p.parts:
                continue
            if not p.is_file() or p.suffix.lower() not in BUILD_RELEVANT_SUFFIXES:
                continue
            try: s=text(p)
            except UnicodeDecodeError: continue
            if '/mnt/data/' in s: bad_abs.append(str(p.relative_to(ROOT)))
            for token in FORBIDDEN_NATIVE_TOKENS:
                if token in s: bad_web.append((str(p.relative_to(ROOT)),token))
    if bad_abs: g.fail('no_absolute_container_paths',f"hits={bad_abs}")
    else: g.ok('no_absolute_container_paths','0 hits')
    if bad_web: g.fail('no_web_runtime_shortcut',f"hits={bad_web}")
    else: g.ok('no_web_runtime_shortcut','0 WebKit/JavaScriptCore runtime hits')

    # 5) Native noon-regression constants: any drift must be evidence-backed and deliberate.
    src=CORE/'Sources'/'EW4NativeCore'
    require_literal(g,src/'LogicalGeometry.swift',r"public static let width\s*=\s*568\.0",'freeze_568_width')
    require_literal(g,src/'LogicalGeometry.swift',r"public static let height\s*=\s*320\.0",'freeze_320_height')
    require_literal(g,src/'NativeCamera.swift',r"public static let minZoom\s*=\s*0\.2",'freeze_camera_min_zoom')
    require_literal(g,src/'NativeCamera.swift',r"public static let maxZoom\s*=\s*1\.0",'freeze_camera_max_zoom')
    require_literal(g,src/'NativeCamera.swift',r"public static let detailZoom\s*=\s*0\.5",'freeze_camera_detail_zoom')
    require_literal(g,src/'NativeCamera.swift',r"public static let tapAxisSlop\s*=\s*15\.0",'freeze_tap_slop')
    require_literal(g,src/'NativeCamera.swift',r"public static let pinchMinDistance\s*=\s*40\.0",'freeze_pinch_threshold')
    require_literal(g,src/'NativePresentationLODCore.swift',r"public static let unitZoomExponent\s*=\s*0\.46",'freeze_unit_zoom_exponent')
    require_literal(g,src/'NativePresentationLODCore.swift',r"public static let unitZoomMinimum\s*=\s*0\.76",'freeze_unit_zoom_min')
    require_literal(g,src/'NativePresentationLODCore.swift',r"public static let unitZoomMaximum\s*=\s*1\.18",'freeze_unit_zoom_max')
    require_literal(g,src/'NativeAnimationTiming.swift',r"let scale\s*=\s*0\.5\s*\*\s*unitZoom",'freeze_native_animation_half_scale')
    require_literal(g,src/'NativeBattleHUDCore.swift',r"undo\s*=\s*NativeHUDRect\(x:\s*0,\s*y:\s*293,\s*width:\s*37,\s*height:\s*37\)",'freeze_native_undo_geometry')
    require_literal(g,src/'NativeBattleHUDCore.swift',r"next\s*=\s*NativeHUDRect\(x:\s*541,\s*y:\s*293,\s*width:\s*37,\s*height:\s*37\)",'freeze_native_next_geometry')

    # 6) Release must not run the full resource auditor during every production launch.
    app=text(IOS/'App'/'EW4NativePortApp.swift')
    idx=app.find('NativeResourceAuditor.audit')
    if idx >= 0 and app.rfind('#if DEBUG',0,idx) > app.rfind('#endif',0,idx):
        g.ok('release_boot_audit_disabled','full audit is DEBUG-only')
    else:
        g.fail('release_boot_audit_disabled','NativeResourceAuditor.audit must be guarded by #if DEBUG')

    # 7) Native deliverable hygiene.
    bad_bins=[]; web_payload=[]
    for p in ROOT.rglob('*'):
        if not p.is_file(): continue
        suf=p.suffix.casefold()
        if suf in {'.apk','.aab'}: bad_bins.append(str(p.relative_to(ROOT)))
        if p.is_relative_to(RES) and suf in {'.html','.js','.mjs'}: web_payload.append(str(p.relative_to(ROOT)))
    if bad_bins: g.fail('no_apk_aab',str(bad_bins[:20]))
    else: g.ok('no_apk_aab','0 direct APK/AAB')
    if web_payload: g.fail('no_web_payload_in_native_resources',str(web_payload[:20]))
    else: g.ok('no_web_payload_in_native_resources','0 html/js/mjs runtime resources')

    passed=not g.errors
    report={
        'project':'EW4 Native unified Codex IPA handoff preflight',
        'passed':passed,
        'root':str(ROOT),
        'checks':g.checks,
        'errors':g.errors,
        'warnings':g.warnings,
        'resource_file_count':len(files),
        'duplicate_basename_groups':len(dup),
    }
    out=Path(args.report)
    if not out.is_absolute(): out=ROOT/out
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding='utf-8')
    print(json.dumps({'passed':passed,'checks':len(g.checks),'errors':g.errors,'resource_files':len(files),'duplicate_basename_groups':len(dup)},ensure_ascii=False,indent=2))
    return 0 if passed else 1

if __name__=='__main__':
    raise SystemExit(main())
