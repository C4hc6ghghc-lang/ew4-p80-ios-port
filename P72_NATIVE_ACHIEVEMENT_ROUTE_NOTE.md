# P72 Native Achievement Route Note

P72 restores the missing Native Achievement route without inventing platform services or reward triggers.

- `NativeAchievementCore` mirrors mature P28 local formulas: 84 Campaign stages / 420 maximum stars; native aggregate military and nobility level/score formulas; max-only Europe/America/Asia stored values rendered with `rule_0..9`.
- `NativeOriginalAchievementScene` consumes original Achievement art (`button_champion`, `button_rank`, `board_rankclass`, `marker_rank`, `marker_class`, continent art, rule digits, stage star, bottom pattern, general boards).
- Main menu now assigns `menu.achievementHandler` and coordinator opens `form_achivement` audio + scene.
- Champion/Ranking do not navigate to fabricated online/GameCenter flows in PORT_ONLY.
- A reusable `NativeOriginalClaimScene` restores the 200x100 `form_claim` visual shell for medal/item rewards, but no unproven Achievement trigger is attached.

Verification: Native 271/271, mature JS 126/126, Sources+Tests parse 182/182, all Native Swift 184/184, SOURCE_LEAN 6321/6321 frozen, Native Resources 1751/1751 provenanced, resource audit errors=[], IPA preflight 26/26.
