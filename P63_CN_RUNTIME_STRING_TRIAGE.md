# P63 Runtime String Triage Rule

The historical 111-candidate runtime-string differential is a **review queue**, not 111 confirmed defects.

P63 uses four conceptual buckets:

1. **Release-visible + original authority proven** — safe to correct. P63 corrected the exchange, deploy-general, unit-info, stage-intro, battle-shop, and HQ-shop labels in this bucket.
2. **DEBUG-only** — not a Release defect. `statusHandler` / `debugMessage` strings are the main proven example.
3. **Approved override / modified-game behavior** — preserve unless the user explicitly changes the modification.
4. **Uncertain or dynamically composed** — do not change until the actual render path and original authority are both established.

Future cleanup should search from actual visible render calls back to `strings_cn.json` / original layout XML, not from raw text occurrence counts forward.
