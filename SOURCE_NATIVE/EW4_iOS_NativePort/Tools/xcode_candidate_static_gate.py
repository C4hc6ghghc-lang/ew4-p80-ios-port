#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CORE=ROOT/'NativeCore'
IOS=ROOT/'iOSApp'
errors=[]; checks=[]
def ok(name,detail): checks.append({'name':name,'passed':True,'detail':detail})
def fail(name,detail): checks.append({'name':name,'passed':False,'detail':detail}); errors.append(f'{name}: {detail}')
def need_text(path, patterns, name):
    if not path.is_file(): return fail(name,f'missing {path.relative_to(ROOT)}')
    s=path.read_text(encoding='utf-8')
    miss=[p for p in patterns if not re.search(p,s,re.M)]
    if miss: fail(name,f'missing patterns {miss}')
    else: ok(name,str(path.relative_to(ROOT)))

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--report',default=str(ROOT/'Docs/XCODE_CANDIDATE_STATIC_GATE.json')); a=ap.parse_args()
    need_text(CORE/'Package.swift',[
        r'// swift-tools-version:\s*6\.0', r'\.iOS\(\.v15\)',
        r'\.library\(name:\s*"EW4NativeCore"', r'\.library\(name:\s*"EW4NativeRenderer"'
    ],'swift_package_contract')
    need_text(IOS/'project.yml',[
        r'name:\s*EW4NativePort', r'path:\s*\.\./NativeCore',
        r'path:\s*\.\./Resources\s*\n\s*type:\s*folder\s*\n\s*buildPhase:\s*resources',
        r'product:\s*EW4NativeCore', r'product:\s*EW4NativeRenderer',
        r'PRODUCT_BUNDLE_IDENTIFIER:\s*local\.ew4\.nativeport', r'SWIFT_VERSION:\s*6\.0',
        r'IPHONEOS_DEPLOYMENT_TARGET:\s*"15\.0"', r'UIInterfaceOrientationLandscapeLeft', r'UIInterfaceOrientationLandscapeRight'
    ],'xcodegen_project_contract')
    need_text(IOS/'App/EW4NativePortApp.swift',[
        r'import\s+SwiftUI', r'import\s+SpriteKit', r'import\s+EW4NativeCore', r'import\s+EW4NativeRenderer',
        r'@main\s*\nstruct\s+EW4NativePortApp', r'NativeResourceStore\(\)', r'NativeBattleSaveSlotStore\.applicationSupport\(\)'
    ],'ios_app_entry_contract')
    need_text(ROOT/'Tools/build_unsigned_ipa.sh',[
        r'xcodegen dump', r'xcodegen generate', r'xcodebuild\s+\\\n\s*-resolvePackageDependencies',
        r'-configuration Release', r'-sdk iphoneos', r'generic/platform=iOS',
        r'CODE_SIGNING_ALLOWED=NO', r'xcrun lipo -info', r'WebKit\|JavaScriptCore',
        r'verify_ipa_payload\.py'
    ],'mac_build_script_contract')
    app=(IOS/'App/EW4NativePortApp.swift').read_text(encoding='utf-8')
    forbidden=[x for x in ('WKWebView','JavaScriptCore','evaluateJavaScript') if x in app]
    if forbidden: fail('app_no_web_runtime',str(forbidden))
    else: ok('app_no_web_runtime','0 forbidden runtime tokens')
    product_swift=list((CORE/'Sources').rglob('*.swift'))+list((IOS/'App').rglob('*.swift'))
    if len(product_swift)==110: ok('p80_product_swift_count','110 product Swift files (109 package sources + 1 app entry)')
    else: fail('p80_product_swift_count',f'expected 110, got {len(product_swift)}')
    report={'checkpoint':'P80_NATIVE_FIRE_PRESENTATION_CLOSURE','passed':not errors,'checks':checks,'errors':errors}
    out=Path(a.report); out.parent.mkdir(parents=True,exist_ok=True); out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'passed':not errors,'checks':len(checks),'errors':errors},ensure_ascii=False,indent=2))
    return 0 if not errors else 1
if __name__=='__main__': raise SystemExit(main())
