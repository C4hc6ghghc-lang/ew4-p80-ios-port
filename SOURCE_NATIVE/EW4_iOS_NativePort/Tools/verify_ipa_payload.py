#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, plistlib, struct, zipfile
from pathlib import Path

REQUIRED_SUFFIXES = [
    "GameAssets/Resources/Data/battles_runtime.json",
    "GameAssets/Resources/Data/worldmaps.json",
    "GameAssets/Resources/Data/native_animation_core877.json",
    "GameAssets/Resources/Bile/def_motion.xml",
    "GameAssets/Resources/Maps/europe.png",
    "GameAssets/Resources/Maps/america.png",
    "GameAssets/Resources/Audio/battle1.mp3",
    "GameAssets/Resources/sprite_manifest.json",
]
FORBIDDEN_EXT = {'.apk','.aab','.html','.js','.mjs'}

def sha256(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):
            h.update(chunk)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('ipa')
    ap.add_argument('--report')
    args=ap.parse_args()
    ipa=Path(args.ipa).resolve()
    errors=[]
    with zipfile.ZipFile(ipa) as z:
        bad=z.testzip()
        if bad: errors.append(f'zip CRC failure: {bad}')
        names=z.namelist()
        apps=sorted({n.split('/')[1] for n in names if n.startswith('Payload/') and len(n.split('/'))>2 and n.split('/')[1].endswith('.app')})
        if len(apps)!=1: errors.append(f'expected exactly one app under Payload, found {apps}')
        app=apps[0] if len(apps)==1 else None
        if app:
            prefix=f'Payload/{app}/'
            if any(n.startswith(prefix+'Resources/') for n in names):
                errors.append('reserved Resources directory at iOS app root prevents installation')
            try:
                info=plistlib.loads(z.read(prefix+'Info.plist'))
                for key in ('CFBundleIdentifier','CFBundleExecutable','CFBundleVersion','CFBundleShortVersionString'):
                    if not info.get(key): errors.append(f'missing app metadata: {key}')
                if info.get('CFBundlePackageType') != 'APPL': errors.append('not an application bundle')
                if info.get('UIDeviceFamily') != [1,2]: errors.append('iPhone/iPad device family missing')
                binary=z.read(prefix+info['CFBundleExecutable'])
                if binary[:4] != b'\xcf\xfa\xed\xfe' or struct.unpack_from('<I',binary,4)[0] != 0x0100000c:
                    errors.append('expected native arm64 Mach-O executable')
            except (KeyError,ValueError,plistlib.InvalidFileException,struct.error) as error:
                errors.append(f'invalid app metadata/executable: {error}')
            for suffix in REQUIRED_SUFFIXES:
                if prefix+suffix not in names: errors.append(f'missing bundle sentinel: {suffix}')
            forbidden=[n for n in names if n.startswith(prefix) and Path(n).suffix.casefold() in FORBIDDEN_EXT]
            if forbidden: errors.append(f'forbidden native payload files: {forbidden[:20]}')
            # Detect the classic flattened-resource failure explicitly.
            flat=[prefix+'battles_runtime.json',prefix+'worldmaps.json',prefix+'europe.png']
            if any(x in names for x in flat): errors.append('flattened resource sentinel detected at app root')
        apk_aab=[n for n in names if Path(n).suffix.casefold() in {'.apk','.aab'}]
        if apk_aab: errors.append(f'APK/AAB entries in IPA: {apk_aab[:20]}')
    report={
        'ipa':str(ipa),
        'size_bytes':ipa.stat().st_size,
        'sha256':sha256(ipa),
        'passed':not errors,
        'errors':errors,
    }
    out=Path(args.report).resolve() if args.report else ipa.with_suffix(ipa.suffix+'.verify.json')
    out.write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report,indent=2))
    return 0 if not errors else 1

if __name__=='__main__':
    raise SystemExit(main())
