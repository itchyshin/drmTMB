# Live receipt: Bernoulli correlated q3 logit bridge

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Paired DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`.
- Runtime: Julia 1.10.0; `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`.
- Fixture: independent synthetic Bernoulli-logit data; 160 groups × 32 observations; one unlabelled correlated intercept-plus-two-slope block; separate group-level SD regressions for all three coefficients; true partial correlations `(0.35, -0.25, 0.4)`.
- Result: one live R-to-Julia test passed 19 assertions without warnings. Native TMB and Julia converged. The test compares all three SD coefficient vectors and correlations across engines, checks each generated SD slope, compares group-SD predictions, and verifies binary marginal simulation.
- Julia coefficients: `(-0.826, 0.381)`, `(-0.608, 0.499)`, `(-0.606, 0.472)`. Native TMB: `(-0.859, 0.401)`, `(-0.667, 0.547)`, `(-0.630, 0.490)`. This is one high-information fixture; lower-information q3 logit fixtures were unstable.
- Live console: `live-q3-logit-160x32-bridge-test.log`; the separate initial diagnostic with a temporary R admission override is retained as `live-q3-logit-160x32-diagnostic.log`.
- This is point/output evidence only. It does not establish interval calibration, low-information stability, broad parity, or programme completion.

## SHA-256

- bridge: `896215ca04358b4b42c6d2c91f66c8ee8a5d882facd8b7237341ee1db65d5a95`
- test: `a8488b82ab7447303397abc0e7e33bbadf9d9a0ba013193a2a61b78bbb13125e`
- probit_test: `a8488b82ab7447303397abc0e7e33bbadf9d9a0ba013193a2a61b78bbb13125e`
- live_log: `0f96225ae29e5567b4bfec31db475981304706441460ab320d17f7b50ee70bcf`
