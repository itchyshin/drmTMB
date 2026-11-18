# Hurdle NB2 SD review-repair verification

The positive-count SD-design rank guards were exercised in native TMB and direct Julia tests. The paired R-to-Julia bridge test was rerun after these source changes and reached one live Julia bridge test with no test failures. The direct Julia Hurdle NB2 SD regression test passed 17/17 checks, including its independent scalar quadrature comparison; the Julia rank test passed 2/2. The native rank-refusal test passed.

The bridge fixture checks coefficient recovery in each engine and positive group-SD output separately in each engine. Its loose cross-engine coefficient comparison does not establish numerical parity of group-SD predictions. This evidence is narrow and unreviewed. It does not establish interval calibration, broad family/effect/provider parity, or completion of a programme gate.

Exact run outputs: `console.rerun.log`, `direct-julia-tests.log`, and `native-identifiability.log`. The 152-file source manifest is identical before and after the paired bridge rerun.
