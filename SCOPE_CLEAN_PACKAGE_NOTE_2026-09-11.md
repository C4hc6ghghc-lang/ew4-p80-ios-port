# P57 Scope-Clean Audited Package

This package is a cleanup/freeze checkpoint of the EW4 native iOS port. It does not introduce new gameplay systems.

Cleanup included:
- removed visible cheat/mod explanation text from runtime UI;
- removed fake 9999/999 medal/shield displays and restored real profile values;
- replaced resource emoji markers with original EW4 image resources;
- restored shop controller flow to select -> info -> explicit confirm;
- unified battle/academy general-info surfaces around the recovered original form structure;
- added a cross-project scope guard that rejects known ImperialFrontier-only concepts, visible cheat-explanation leakage, fake resource placeholders, and untraceable Native resources;
- retained only original EW4 behavior plus user-authorized EW4 modifications.

This remains a Linux-validated handoff checkpoint. Final iPhoneOS/Xcode semantic compilation and device QA are still required.
