# 2026-10-15: Round 5 Gamma mi() pole repair (#1513)

Reader: Shinichi, deciding whether #1513 can leave draft.

## Task goal

Bring the Gamma `mi()` pole rows at CV 0.5 and CV 1 inside `1e-4` per row
without loosening the bar, make Poisson times Gamma at CV 2 match
`integrate()` to `1e-4` at `y = 0` and at a large `y`, and check the
log-x integrand, gradient, Hessian and Jacobian. R/TMB side only. Refs
#1477 only.

## Findings

1. Mode residual after Newton step 5 (old rule, `y = 2.05`): score
   `-14.7` (CV 0.5), `-15.8` (CV 1), `-16.1` (CV 2). The iterate was not
   at the mode, so the nodes were centred on the wrong point.
2. The family-correct derivatives were already in. `drm_gamma_mi_grad_hess()`
   (new R function, the mirror of the C++ routine) matches central
   differences of the log integrand with Jacobian for Gaussian and Poisson
   at CV 0.5, 1, 2 (new test).
3. Integrand, gradient and Hessian are all on `u = log(x)`; the Jacobian is
   the `+u` term in the integrand and the `shape` (not `shape - 1`) in the
   score. Nodes are placed after step 5.
4. At CV 1 and above the log-x integrand has the left tail `exp(shape * u)`.
   Gauss-Hermite nodes could not reach it (0.28 at CV 1 even at the mode).
5. The test reference stopped at `log(mu) - 12`, which drops about 5% of the
   mass at CV 2. It is now a log-space `integrate()` over `[-60, u_hi]` plus
   the analytic tail.

## What changed

`src/drmTMB.cpp` and `R/missing-data.R`: safeguarded Newton (better of the
clamped log-x step and a Newton step on `G(x) = g / x`) and a sinh-mapped
trapezoid rule (51 nodes, `t` in `[-5, 4]`). `n_cpp = 45L`. Tests: per-row
Gaussian and Poisson tables, compiled-versus-`integrate()` per row via a
with/without-row objective difference, derivative check, two paired guard
tests, and Julia refusal tests (Gamma weights, Beta and Gamma unit weights).
Design doc `03-likelihoods.md` and `known-limitations.md` updated.

## Numbers

See the two tables in `docs/dev-log/check-log.md` (2026-10-15 entry). Worst
asserted row: `2.48e-5` (Gaussian CV 2, `y = 2.2`).

## Not done / open

- Full suite and C17 recertification: session 2.
- CV `>= 3`, and Poisson rows with `exp(eta)` at the prior mean of about
  `1e3` or more: five Newton steps are too few; twelve fix the moderate
  cases (error `3e-7` to `5e-5` at `exp(eta)` near `8e3`). Raising the step
  count departs from the five-step lock, so it is Shinichi's decision.
- Poisson times Gamma is not reachable through `drmTMB()` (the validator
  allows only a binary `mi()` predictor for Poisson), so its rows test the R
  mirror and the shared algorithm, not the compiled Poisson branch.
- `test-missing-predictor-prediction.R:291` errors identically on the
  unmodified draft head (`crossprod` on a non-numeric matrix); not touched.
- #1506, #1530 not rebased: #1511 is not merged.
