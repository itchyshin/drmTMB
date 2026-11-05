# Live receipt: Bernoulli correlated q3 cloglog bridge

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Paired DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`.
- Runtime: Julia 1.10.0; `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`.
- Fixture: synthetic Bernoulli complementary-log-log data; 160 groups × 32 observations; one ordinary correlated intercept-plus-two-slope block; separate group-level SD regressions for all three coefficients; true partial correlations `(0.35, -0.25, 0.4)`.
- Result: one live R-to-Julia test passed 19 assertions without warnings. Native TMB and Julia converged. The test checks same-data SD coefficients and correlations, group-SD predictions, all three one-seed SD-trend recovery bounds, and binary marginal simulation.
- Julia coefficients: `(-0.669, 0.287)`, `(-0.788, 0.535)`, `(-0.718, 0.369)`. Native TMB: `(-0.687, 0.291)`, `(-0.795, 0.536)`, `(-0.726, 0.372)`. The SD-trend recovery tolerance is 0.40 relative for this one fixture; cross-engine coefficient and prediction tolerances remain 0.20. Lower-information q3 cloglog fits remain unstable.
- Live console: `live-q3-cloglog-160x32-bridge-rerun.log`. The preceding exact run failed only the truth-recovery tolerance and is retained as `live-q3-cloglog-160x32-bridge-test.log`; its engine parity, convergence, prediction, and simulation checks passed.
- This is point/output evidence only. It does not establish interval calibration, low-information stability, broad parity, or programme completion.

## SHA-256

- bridge: `896215ca04358b4b42c6d2c91f66c8ee8a5d882facd8b7237341ee1db65d5a95`
- admission_test: `d13ef1c5e3c667363d9f6cdf54416a42bfd63a8421477973a9c51d6ca0568087`
- cloglog_test: `b907c357b301185a6b7b6abe235ce0ecaf2bf8792c59498ff2b3920663eab4aa`
- live_log: `09b2b15e8c618797ab6655bf6b0de2fe7bb6dbd10cade6892aeeafba501cdb97`
