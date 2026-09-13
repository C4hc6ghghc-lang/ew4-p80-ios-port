#!/usr/bin/env python3
from pathlib import Path
import hashlib, re, sys
ROOT=Path(__file__).resolve().parent
NATIVE=ROOT/'SOURCE_NATIVE'/'EW4_iOS_NativePort'
SWIFT=NATIVE/'NativeCore'/'Sources'
RES=NATIVE/'Resources'
TRUTH=ROOT/'SOURCE_LEAN'/'EW4_Web_Port_v0.61'

foreign_markers=[
    'ImperialFrontier','leaningFrance','leaningCoalition','strictNeutral','天灾级','大军团','42国',
    '1×/2×/4×/8×','1x/2x/4x/8x','极速 AI','AI 五档','五档 AI'
]
visible_cheat_markers=['勋章无限','盾牌无限','买卖不扣有限货币','买入/卖出不扣货币','FREE','∞','候选将领信息 · 只读','请选择物品']
resource_emoji=['🏅','💰','⚙️','🌾']
errors=[]
swift_files=list(SWIFT.rglob('*.swift'))
for p in swift_files:
    text=p.read_text(errors='ignore')
    for marker in foreign_markers:
        if marker in text: errors.append(f'foreign marker {marker!r}: {p.relative_to(ROOT)}')
    for marker in visible_cheat_markers:
        if marker in text: errors.append(f'visible cheat copy {marker!r}: {p.relative_to(ROOT)}')
    for marker in resource_emoji:
        if marker in text: errors.append(f'resource emoji {marker!r}: {p.relative_to(ROOT)}')
    if re.search(r'label\(\s*"9999?"', text): errors.append(f'dummy visible resource count: {p.relative_to(ROOT)}')

# Build truth hash index once. Resource provenance is byte identity, not filename similarity.
truth_hashes=set()
for p in TRUTH.rglob('*'):
    if p.is_file():
        try: truth_hashes.add(hashlib.sha256(p.read_bytes()).digest())
        except OSError: pass
resource_files=[p for p in RES.rglob('*') if p.is_file()]
unmatched=[]
for p in resource_files:
    if hashlib.sha256(p.read_bytes()).digest() not in truth_hashes:
        unmatched.append(str(p.relative_to(ROOT)))
if unmatched:
    errors.extend('unprovenanced Native resource: '+x for x in unmatched)

print(f'Runtime Swift: {len(swift_files)}')
print(f'Native resources provenanced: {len(resource_files)-len(unmatched)}/{len(resource_files)}')
if errors:
    print('EW4_SCOPE_GUARD_FAIL')
    for e in errors[:100]: print(' -',e)
    if len(errors)>100: print(f' ... {len(errors)-100} more')
    sys.exit(1)
print('EW4_SCOPE_GUARD_PASS')
