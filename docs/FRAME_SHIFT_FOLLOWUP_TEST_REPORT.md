# Frame-shift follow-up

Implemented inactive-panel amber edge arrows for offscreen living enemies, including diagonal clipped borders and simultaneous left/right threats. Visible and dead enemies do not retain indicators. Migration uses each adjacent role gap × 0.1 in real seconds. Between waves, the current Future/Present gap × 0.1 sets a real-time intermission; inactive slowdown and environmental dilation do not prolong it. Pausing freezes both systems.

Dragging temporal roles costs 5 ADD per position crossed, charged once for the exchange (10 between Past and Future). Insufficient funds leave roles and balance unchanged. A same-role drop is free, as is selecting the active panel. ADD can reach zero; existing minimum attack damage remains one. Both previews glide to their destination while paused and the temporary graphics clean up after landing.

Nine relevant suites passed: frame_shift_followup (26), causal_lifecycle (22), causal_swap_score (22), causal_pause_ui (9), wave_difficulty (66), wave_combat (30), manga_ui (36), dilation_clock (7), causal_end_to_end (86): **304 passing assertions**, no engine errors or warnings. The end-to-end scenario earns enough ADD through actual melee input before its actual mouse role drags and reaches singularity without injected scores or gaps. Historical role-law fixtures explicitly fund swaps; exact debit and rejection checks live in frame_shift_followup.

Godot MCP startup check passed. No visual inspection or screenshots were performed for this follow-up, as requested.
