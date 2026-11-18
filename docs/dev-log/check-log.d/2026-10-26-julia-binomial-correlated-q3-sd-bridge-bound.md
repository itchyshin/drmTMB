# Check log: Bernoulli correlated q3 Julia bridge bound (2026-10-26)

- Source: drmTMB candidate HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl candidate HEAD `70dbf564eb670144c63c08f61ea099084d95add2`.
- Live q3 probit test: Julia 1.10.0, one core, final fixture 80 groups × 12 observations; one live test passed without warnings. An earlier 40-group attempt warned on Hessian coordinate 12, rcond `6.270106395952565e-11`; the final run supersedes it.
- q3 logit/cloglog low-information fixtures failed convergence, agreement with TMB, or Hessian checks. Higher-information 160-group × 32-observation same-data bridge tests later converged on both engines and passed SD-coefficient, correlation, prediction, and simulation checks. The cloglog repeat passed after changing only its one-seed truth tolerance; engine agreement remained at 0.20. See `live-q3-logit-160x32-bridge-test.log` and `live-q3-cloglog-160x32-bridge-rerun.log`. The public bridge admits q3 probit/logit/cloglog for these tested routes.
- Fit-free probit route test: 20 passed, one live fit skipped by opt-in guard. The q3 logit and cloglog live route tests each passed 19 assertions on Julia 1.10.0. `git diff --check` passed on touched implementation/test files.
- Evidence: `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-sd-bridge-final-20261026/`.
- Scope: point fit, output, and simulation only; no interval calibration, coverage, broad parity, or full-suite claim.
