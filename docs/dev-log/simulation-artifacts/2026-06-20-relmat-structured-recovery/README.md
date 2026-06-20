# Gaussian relmat (known-K) structured recovery (500 reps; evidence banked, cell HELD partial)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, pushes held) · **Gate:** Curie + Fisher (both HOLD)

Native R/TMB recovery for a **relmat** (user-supplied known relatedness) random
intercept, `bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1)`, `family = gaussian()`,
with a known AR(1) relatedness matrix K (`Q = solve(K)`). The recovery is clean and
promotion-grade for the relmat/known-K sub-capability, but the matrix "Structural
dependencies" point cell is **HELD at partial** (see verdict below).

## Design (deterministic, `master_seed = 20260620`)

- 2 cells: `n_id in {40, 80}`, `n_each = 6`. K = AR(1) correlation
  (`0.5^|i-j|`, PD). 500 reps/cell. Truth: `b0 = 0.25`, `b1 = 0.45`, `sigma = 0.4`,
  `sd_relmat = 0.6`. u = `sd_relmat * chol(K)' %*% rnorm(n_id)`.
- Recovered: fixed effects (`coef`), the relmat RE SD (`fit$sdpars$mu`,
  name `relmat(1 | id)`), residual `sigma`; Wald coverage for the two fixed effects.

## Result (`tables/relmat-recovery-summary.csv`, 0 fit errors, pdHess 1.000)

| target | n_id=40 (rel bias) | n_id=80 (rel bias) | Wald cov 40/80 |
| --- | --- | --- | --- |
| b0 (Intercept) | +0.8% (rmse 0.165) | +0.8% (rmse 0.113) | 0.944 / 0.958 |
| b1 (slope x) | +0.4% | +0.2% | 0.936 / 0.960 |
| **sd_relmat** | **-3.0%** | **-1.0%** | n/a |
| sigma | -0.2% | +0.1% | n/a |

Fixed effects unbiased; the structured (known-K) RE SD recovers cleanly with the
expected shrinking ML small-sample bias; fixed-effect Wald coverage is in
[0.936, 0.960] at every cell (no sub-0.93). The elevated intercept RMSE is
random-intercept grand-mean confounding (unbiased on average; RMSE scales ~n^-1/2),
not a defect.

## Verdict (Curie + Fisher, both HOLD the aggregate cell)

The recovery is promotion-grade for the **relmat/known-K** sub-capability. But the
matrix "Structural dependencies" point cell is a **single aggregate cell over six
structurally distinct sub-types** (animal, phylo, relmat, spatial, kernel, SPDE),
each requiring its own recovery per the row's next-gate. This evidence covers
**1 of 6** sub-types. Unlike the rho12 precedent (which parked `covered` on a
narrower per-capability TSV row), there is **no granular relmat row** in the matrix
for a scoped `covered` to live in -- so flipping the aggregate cell would read as
"structured-effect point recovery is covered," which is false for the other five
sub-types. The matrix's `partial` definition fits exactly.

**Action:** bank this evidence as a named relmat sub-type milestone in the
"Structural dependencies" next-gate text; keep the point cell `partial`;
re-evaluate when additional sub-types (animal/phylo first) have comparable recovery.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-relmat-structured-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, one relmat block with a user-supplied known K, complete
data, single predictor, POINT recovery only. NOT claimed: RE-SD interval
calibration; arbitrary-K PSD/name-alignment; animal/phylo/spatial/kernel/SPDE
sub-types; the Julia bridge; non-Gaussian families; estimated (unknown) covariance.
