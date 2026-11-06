# Live receipt: Bernoulli correlated q3 probit bridge

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Paired DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`.
- Runtime: Julia 1.10.0; `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`.
- Fixture: synthetic probit Bernoulli; final fixture 80 groups × 12 observations; correlated intercept plus two numeric slopes; one fixed predictor and one log-SD regression per coefficient.
- Result: one live test passed without warnings. It checks convergence, native TMB vs Julia coefficient/correlation outputs, group-SD prediction, and binary marginal simulation. The earlier 40-group attempt emitted a singular-Hessian warning and was superseded by this final run.
- Earlier diagnostic only: the superseded 40-group attempt reported a numerically singular Hessian at coordinate 12, `rcond = 6.270106395952565e-11`. The final 80-group run emitted no warning; neither run establishes calibrated uncertainty.
- q3 logit and q3 cloglog have separate higher-information live receipts in `q3-logit-receipt.md` and `q3-cloglog-receipt.md`. Lower-information candidate fits remained unstable.
- This is point-fit and output evidence only. No interval calibration, coverage, broad parity, or full-suite claim.
- Full final console: `live-q3-probit-80groups-final.log`. Earlier attempt logs are retained in the same directory.

## SHA-256

- Test: `d13ef1c5e3c667363d9f6cdf54416a42bfd63a8421477973a9c51d6ca0568087`
- Bridge: `896215ca04358b4b42c6d2c91f66c8ee8a5d882facd8b7237341ee1db65d5a95`
- Live log: `407fb980fc572c58a9fbf091eccd532afcbde802634531f73c988a369735e123`
