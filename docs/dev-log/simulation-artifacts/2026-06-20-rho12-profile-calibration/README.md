# rho12 ~ x PROFILE-interval calibration (500 reps; profile vs Wald) — Profile cell evidence

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Gate:** Fisher

Profile-likelihood interval calibration for the predictor-dependent residual
correlation coefficients `rho12 ~ x` (the lead novelty), with Wald intervals
computed alongside for comparison. Same DGP as the rho12 ~ x recovery
(`2026-06-20-rho12-predictor-recovery/`): bivariate Gaussian,
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~ x)`,
`rho12_i = 0.999999 * tanh(a0 + a1 * x_i)`, `a0 = 0.4`, `a1 = 0.5`.

## Design (deterministic, `master_seed = 20260620`)

- 2 cells: `n in {300, 600}`. 500 reps/cell (1000 fits).
- `confint(method = "profile")` and `confint(method = "wald")` for the two rho12
  coefficients each rep; coverage = fraction of intervals containing the atanh-scale
  truth; widths and profile failures (`conf.status`) tracked.
- The profile engine used is `tmbprofile` (the `auto` engine falls back to
  `tmbprofile` for fixed-effect coefficients; the fast endpoint solver covers only
  direct scale/SD/correlation targets).

## Result (`tables/rho12-profile-calibration-summary.csv`; 0 fit errors, 0 CI failures, pdHess 1.000)

| cell | profile coverage | wald coverage | profile width | wald width |
| --- | --- | --- | --- | --- |
| n=300 rho12:(Intercept) | 0.948 | 0.946 | 0.213 | 0.213 |
| n=300 rho12:x | 0.922 | 0.920 | 0.207 | 0.207 |
| n=600 rho12:(Intercept) | 0.964 | 0.964 | 0.150 | 0.150 |
| n=600 rho12:x | 0.960 | 0.956 | 0.143 | 0.143 |

(coverage MCSE 0.008-0.012.)

## Finding

- **Profile intervals are well-calibrated** and track Wald closely (profile coverage
  >= Wald at every cell; widths near-identical). Both reach nominal by n=600
  (0.956-0.964); at n=300 the slope mildly undercovers (profile 0.922, Wald 0.920 --
  the same small-n behaviour that holds across both methods, not a profile defect).
- **No profile failures** (0/1000 CI attempts failed; all `conf.status = profile`,
  `profile.message = ok`). Profile and Wald agree to within Monte-Carlo noise.

## Scope / boundary

Native R/TMB, fixed-effect bivariate, predictor-dependent residual `rho12 ~ x`.
Profile-interval calibration for the two rho12 coefficients only. This matches the
already-covered Wald cell's scope and treatment; the n=300 slope cell mildly
undercovers under BOTH methods (clean by n=600). Random-effect rho12, structured
rho12, and the Julia bridge are separate cells. The asserted guarantee is
profile-vs-Wald parity and ~0.95 calibration at n>=600; not a small-n exactness
claim.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-rho12-profile-calibration/run.R 500
```
