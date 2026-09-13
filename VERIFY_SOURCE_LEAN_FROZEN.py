#!/usr/bin/env python3
from pathlib import Path
import hashlib,sys
ROOT=Path(__file__).resolve().parent
BASE=ROOT/'SOURCE_LEAN'/'EW4_Web_Port_v0.61'
MAN=ROOT/'P43_SOURCE_LEAN_FROZEN_SHA256.tsv'
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for c in iter(lambda:f.read(1024*1024),b''):h.update(c)
    return h.hexdigest()
exp={}
for line in MAN.read_text(encoding='utf-8').splitlines()[1:]:
    rel,size,digest=line.split('\t');exp[rel]=(int(size),digest)
act={str(p.relative_to(BASE)).replace('\\','/'):(p.stat().st_size,sha(p)) for p in BASE.rglob('*') if p.is_file()}
missing=sorted(set(exp)-set(act));extra=sorted(set(act)-set(exp));changed=sorted(k for k in set(exp)&set(act) if exp[k]!=act[k])
print(f'SOURCE_LEAN expected={len(exp)} actual={len(act)} missing={len(missing)} extra={len(extra)} changed={len(changed)}')
if missing:print('missing sample',missing[:10])
if extra:print('extra sample',extra[:10])
if changed:print('changed sample',changed[:10])
sys.exit(1 if missing or extra or changed else 0)
