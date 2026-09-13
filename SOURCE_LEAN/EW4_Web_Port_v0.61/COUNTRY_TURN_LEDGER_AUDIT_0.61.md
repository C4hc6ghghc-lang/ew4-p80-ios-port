# EW4 Web Port 0.61 · Country turn / resource ledger audit

## Runtime change in this pass

- AI is no longer executed as one merged enemy phase. Living non-player countries act one country at a time.
- In **conquest**, AI target selection is pairwise country-vs-country and respects the decoded conquest relation groups, so same-group allies do not attack each other.
- In **campaign/tutorial**, the conquest relation byte is deliberately not reused as an alliance group. The recovered player-centric hostility model is preserved, while separate non-player countries are kept in one conservative enemy bloc so the new scheduler does not make enemy countries fight each other.
- Hostile conquest AI countries may capture each other's facilities; allied and neutral ownership is not captured.
- Every country has an independent money / industry / food ledger. The selected player UI remains bound to the selected player ledger.
- Save schema is v2 and persists `countryResources`; schema-v1 saves remain readable and preserve the legacy player treasury.

## BTL country-resource evidence

The decoder exposes a stable three-value country record at `country.raw_u32_36_180[30..32]`. Its native field names are not yet binary-symbol confirmed, so the port labels it a **high-confidence BTL country economy triplet**, not a fully named native structure.

| conquest | default country | header 18/19/20 | country 30/31/32 |
|---|---|---:|---:|
| conquest1.btl | 法国 | 50/70/500 | 100/20/500 |
| conquest2.btl | 美国 | 380/150/500 | 450/180/400 |
| conquest3.btl | 法国 | 0/0/400 | 100/50/400 |
| conquest4.btl | 法国 | 0/0/600 | 0/0/600 |
| conquest5.btl | 美国 | 0/20/400 | 0/20/400 |
| conquest6.btl | 法国 | 135/40/500 | 0/0/500 |

The mismatches prove that the battle header triplet cannot be reused as a universal treasury for every selectable conquest nation. In conquest mode the port therefore binds the selected country to its own country record. Campaign/tutorial mode keeps the stage header treasury for the player to preserve stage-specific behavior already used by 0.61.

## Relation / action-order rule used now

### Conquest
- relation hint/group 1 and 2: same number = ally, different number = hostile.
- group 4 and owner 255: neutral.
- unresolved final decoded relation byte: conservative hostile fallback, matching the prior port rather than silently removing combat.
- action sequence: BTL `countries[]` index order among living, non-player, non-neutral countries.

### Campaign / tutorial safety rule
The campaign country `relation_hint` is **not** the same semantic as the conquest alliance group. Copenhagen proves this directly: player Britain and enemy Denmark both carry hint `1`. Reusing conquest semantics would make them allies and break the stage. Therefore the current port preserves player-vs-nonplayer hostility from recovered 0.61 and treats separate non-player campaign countries as one conservative enemy bloc for AI-vs-AI decisions. Exact campaign ally/third-party diplomacy remains a separate native reverse-engineering task.

The per-country action sequence is deterministic but the exact native scheduler order is **not yet binary-confirmed**.

## Still intentionally absent

AI now owns and accrues its own ledger, but AI recruitment / construction spending has not been invented. Until the native AI economy-spending path is recovered, the ledger is authoritative state plumbing rather than a claim that the full original AI economy has been reconstructed.
