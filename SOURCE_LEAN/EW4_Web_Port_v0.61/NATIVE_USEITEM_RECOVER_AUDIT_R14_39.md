# EW4 r14-39 — native battle use-item / recover audit

Authority: original EW4 v1.4.42 APK, `layout-568h.xml`, `def_item.xml`, x86_64 `libeuropean-war-4.so`.

## Original form and fixed item bank

`form_useitem` is a native user window of **280x175**. Its listbox is `lbox_item` at x=9, y=35, w=269, h=45, and the description group is x=2, y=88, w=275, h=84. The constructor at `0x4A250` inserts exactly five IDs in order: **11, 12, 13, 14, 15**.

## Validation / application

`0x51A30` validates the selected item. `0x525C0` applies it. Function-specific behavior is:

- Spirit (12, function 6): current morale <= 0; temporary morale base +1, duration 3 turns.
- Wine (11, function 7): current morale < 0; temporary morale base 0, duration 3 turns.
- Medikit (13, function 8): +65 current HP.
- Medikit L (14, function 8): +130 current HP.
- First Aid Box (15, function 8): +200 current HP.
- Medical healing clamps to existing max HP.

The battle form uses the global item bank/inventory; it is not a commander equipment-slot action.

## Audio / visual result

The successful battle action branch around `0x596A8..0x59756` unconditionally plays `sfx_supply.wav` and creates `effect_recover.xml` after a successful use of any of these five consumables. This must not be generalized to passive facility supply, Training round heal, nobility heal, or manual-training level-up heal.

## Turn-action semantics

The same successful application function sets unit `+0x28 = 0` and `+0x5A = 1`. Cross-reference proves `+0x28` is current movement: it is initialized from UnitDef movement at `0x50E5B..0x50E6B` and refreshed from the base movement plus commander modifier at `0x5293A..0x5295D`. The `+0x5A` byte is cleared on round refresh (`0x529A1`) and set by action-consuming operations, including manual Training (`0x52381..0x5238D`) and item use (`0x5261E..0x52627`). The Web binary action model maps this pair to `moved=true` + `attacked=true` after success.

## Remaining boundary

The additional validator field at `+0x60` is now identified as **remaining construction/build rounds** for fortress-family units. Native fortress construction writes the card `buildround` into this field; round refresh decrements it, and actions are gated while it remains above zero. The original build-card values are Small Fortress 2, Fortress 3, Large Fortress 4, Coastal Fort 3.

Nearby action-state bytes `+0x5B/+0x5C` are still not fully named. They are not required to reproduce the five battle-consumable effects, so their semantics are not invented here. A broader unit-action-state reconstruction should resolve them before claiming the entire native action-state machine is complete.
