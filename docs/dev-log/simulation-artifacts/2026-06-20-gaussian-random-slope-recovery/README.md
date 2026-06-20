# Gaussian random-slope recovery (500 reps; Curie+Fisher verified)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Curie + Fisher (both promote)

Native R/TMB recovery for a single **correlated random intercept+slope** block,
`bf(y ~ x + (1 + x | id), sigma ~ 1)`, `family = gaussian()`. It promotes the
matrix "Random slopes" **point** cell `partial -> covered`, scoped to point recovery.

## Design (deterministic, `master_seed = 20260620`)

- 2 cells: `n_group in {40, 80}`, `n_per_group = 8`, `x` a within-group sequence
  (slope identifiability). 500 reps/cell.
- Truth: `b0 = 0.2`, `b1 = 0.5`, `sigma = 0.6`, `sd_intercept = 0.5`,
  `sd_slope = 0.35`, `cor = 0.2`.
- Recovered per rep: fixed effects (`coef`), the two RE SDs (`fit$sdpars$mu`),
  residual `sigma`; Wald coverage for the two fixed effects only.

## Result (`tables/random-slope-recovery-summary.csv`, 0 fit errors, pdHess 1.000)

| target | n_group=40 (rel bias) | n_group=80 (rel bias) |
| --- | --- | --- |
| b0 (Intercept) | +1.0% | +0.3% |
| b1 (slope x) | -0.8% | -0.1% |
| sd_intercept | -2.8% | -1.0% |
| **sd_slope** | **-6.7%** | **-1.1%** |
| sigma | 0.0% | 0.0% |

Fixed-effect Wald coverage: n_group=40 b0 0.932 / b1 0.922; n_group=80 b0 0.960 /
b1 0.946.

## Promotion outcome (Curie + Fisher, both promote)

- **point `partial -> covered`** (PROMOTED), scoped to native R/TMB Gaussian
  correlated random-slope POINT recovery. Fixed effects near-unbiased at both group
  counts; the RE SDs are **consistent** with the expected ML small-sample downward
  bias (sd_slope -6.7% at n_group=40 shrinking to -1.1% at n_group=80; sd_int -2.8%
  -> -1.0%). "Covered" for the RE SDs means *recovered up to a documented, shrinking
  ML bias*, NOT unbiased; the n_group=40 sd_slope bias is statistically real
  (bias/MCSE = -6.2), not noise. Fisher recomputed the headline stats from the raw
  per-fit CSV and they match the summary exactly.
- **Not claimed / out of scope:** the random-effect correlation `rho` (truth 0.2)
  was not extracted or validated; RE-SD Wald/profile interval calibration; the
  independent-slope-only fit (the correlated model subsumes it for point recovery,
  a procedural deviation from the design-168 milestone ordering, not an evidentiary
  gap); non-Gaussian families; structured/phylogenetic slopes; profile/bootstrap;
  the Julia bridge.
- **Wald cell stays partial:** n_group=40 b1 Wald coverage 0.922 (< 0.93 floor).

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, one correlated random-slope block, complete data, single
predictor `x`, POINT recovery only. Not a calibration proof, not a blanket
random-slope claim.
