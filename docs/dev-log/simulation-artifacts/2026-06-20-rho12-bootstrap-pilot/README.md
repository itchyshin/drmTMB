# rho12 ~ x parametric-BOOTSTRAP interval pilot — Bootstrap cell evidence (partial)

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Gate:** Fisher

Parametric-bootstrap interval pilot for the predictor-dependent residual
correlation coefficients `rho12 ~ x`, completing the "all three interval methods"
picture for the lead-novelty row (Wald covered, profile covered, bootstrap here).
Same DGP as the rho12 recovery / profile calibration: bivariate Gaussian,
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~ x)`,
`rho12_i = 0.999999 * tanh(a0 + a1 * x_i)`, `a0 = 0.4`, `a1 = 0.5`.

## Design (deterministic, `master_seed = 20260620`)

- `confint(method = "bootstrap")` — a PARAMETRIC bootstrap (`simulate(nsim = R)` from
  the fit, refit each), so each CI costs R refits; this is therefore a bounded
  **pilot**, not a 500-rep calibration.
- 2 cells: `n in {300, 600}`. **100 reps/cell, R = 199** bootstrap refits per CI
  (≈ 40,000 refits total). 0 fit errors, 0 CI failures, pdHess 1.000.

## Result (`tables/rho12-bootstrap-pilot-summary.csv`)

| cell | bootstrap coverage | mean width | (profile / wald coverage) |
| --- | --- | --- | --- |
| n=300 rho12:(Intercept) | 0.95 | 0.213 | 0.948 / 0.946 |
| n=300 rho12:x | 0.91 | 0.216 | 0.922 / 0.920 |
| n=600 rho12:(Intercept) | 0.98 | 0.152 | 0.964 / 0.964 |
| n=600 rho12:x | 0.95 | 0.146 | 0.960 / 0.956 |

(bootstrap coverage MCSE 0.014-0.029 at 100 reps.)

## Finding

- **Bootstrap intervals are feasible and approximately calibrated.** 0/100 CI
  failures per cell; widths match the Wald/profile widths closely; coverage tracks
  the other two methods. The n=300 slope (0.91) mildly undercovers — the same
  small-n pattern as Wald (0.920) and profile (0.922) at n=300; the n=600 intercept
  (0.98) is mildly over but within ~2 MCSE of nominal at this pilot size.
- This is a **pilot** (100 reps, R=199): it establishes feasibility + approximate
  calibration, not the tight calibration the 500-rep Wald/profile cells carry. A
  full 500-rep bootstrap calibration is impractical (each CI = R refits).

## Scope / boundary

Native R/TMB, fixed-effect bivariate, predictor-dependent `rho12 ~ x`, parametric
bootstrap. Pilot-scale feasibility + approximate calibration -> the Bootstrap cell
moves planned -> **partial** (not covered). Random-effect rho12, structured rho12,
and the Julia bridge remain separate cells. The asserted guarantee is bootstrap
interval feasibility (0 failures) and approximate calibration at pilot scale.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-rho12-bootstrap-pilot/run.R 100 199
```
