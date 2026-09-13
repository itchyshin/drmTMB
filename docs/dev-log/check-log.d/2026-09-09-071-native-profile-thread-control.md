# Native profile thread-control repair

The four-fixture runner incorrectly forwarded `threads = FALSE` to native TMB
profiles. That option belongs to the Julia bridge. On the frozen NB2 RI random
intercept SD target it changed the native result from a boundary-aware finite
interval to `profile_failed/nonfinite_interval`.

The runner now supplies `threads = FALSE` only to Julia. A direct regression on
the frozen NB2 RI data returns native `sd:mu:(1 | group)` profile `[0,
0.7763259969]` with `profile` status. The previous non-finite scalar SD rows
are therefore stale harness artifacts and must be regenerated; this repair does
not alter a model objective or claim integrator parity.
