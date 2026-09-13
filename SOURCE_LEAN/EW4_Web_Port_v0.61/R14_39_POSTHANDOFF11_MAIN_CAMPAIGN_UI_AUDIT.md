# r14-39 Post-Handoff 11 — Main Menu / Campaign Selection Native Geometry

Authority: original APK `assets/layout-568h.xml`.

## Main menu (`form_mainmenu`)
- title texture: x=20 y=15, original texture rendered at scale 0.5 (current extracted PNG is 759x192 -> 380x96 CSS target)
- menu x=435, button size 134x33
- button y: 115 / 153 / 191 / 229 / 267
- bottom homepage / achievement / mail retain original x=0/35/70 y=287 size 33x33

## Campaign selector (`form_selcampaign`)
Native pin positions restored exactly:
1. France: 300,118
2. Coalition: 356,70
3. Holy Roman: 415,140
4. East: 490,95
5. USA: 76,103
6. UK: 265,38

The screen title is restored to original `title_campaigns` wording: `剧 本` rather than the Web-era `战役` label.

## Deliberate non-change
The generic `user_window` title/back/load chrome is not claimed 1:1 in this patch. Layout gives button presence and screen content geometry, but the generic renderer's exact title plaque composition is shared native UI code and remains a separate audit item.
