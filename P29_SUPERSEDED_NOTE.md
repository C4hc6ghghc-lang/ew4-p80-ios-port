# P29 interpretation superseded by P30 native caller proof

P29's formula reverse engineering remains valid, but its statement that a qualifying fast Conquest automatically writes Asia was incomplete.

P30 followed the native `form_complete` callbacks and proved the exact interaction: qualifying fast victories first open `group_challenge`. The player chooses either `btn_chal_asia` (apply Asia override, then max-only write) or the ordinary Europe/America button (write the pending normal result). P30 implements this original choice.
