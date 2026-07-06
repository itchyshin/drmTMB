# Row 87 recovery evidence — non-count structured `mu` one-slope (recovery-only)

Date: 2026-07-06 · Branch: `drmtmb/row87-noncount-structured-slope`

## What this is

Recovery-only evidence for the three non-count family × provider structured `mu`
**one-slope** cells that close the final Q-Series row (row 87):

- `Gamma()` × `relmat(1 + x | id, K = I)`
- `student()` × `spatial(1 + x | id, coords)`
- `beta()` × `animal(1 + x | id, pedigree = unrelated)`

These are native TMB ML/Laplace **point fits** (no `src/*.cpp` change; the shared
`build_structured_mu_structure()` machinery carries the slope column). This is **not**
interval, coverage, `inference_ready`, `supported`, REML, AI-REML, labelled covariance,
multiple-slope, scale/shape/inflation-slope, or bridge evidence — all of which stay planned.

## Design (ADEMP)

- **DGP:** linear predictor `= b0 + b1*x + u_int[level] + u_slp[level]*x`, with
  `u_int ~ N(0, sd_int^2)` and `u_slp ~ N(0, sd_slp^2)` carried through the provider
  covariance (relmat `K = I`; spatial coords-precision on a circle; animal pedigree
  `A = I`). Family noise: Gamma `shape = 25`; Student `df = 12`, resid scale `0.25`;
  beta `phi = 8`.
- **Truth:** `sd_int` / `sd_slp` = 0.5 / 0.35 (gamma), 0.5 / 0.35 (student), 0.4 / 0.30 (beta).
- **Ladder:** `n_levels ∈ {10, 20, 30}`, `n_per_level = 25`, 30 seeds/rung.
- **Control:** `sd_slp = 0`, `n_levels = 30`, 30 seeds (separability check).
- **Estimands:** `sd_int`, `sd_slp`. **Performance:** convergence, `pdHess`, mean estimate, RMSE.

## Results — crossed ladder (`recovery-summary.tsv`)

RMSE of both variance components **falls as levels increase**, means near truth:

| family | conv | pdHess | RMSE sd_int (10→30) | RMSE sd_slp (10→30) |
| --- | --- | --- | --- | --- |
| gamma_relmat | 90/90 | 100% | 0.110 → 0.081 → 0.071 | 0.070 → 0.043 → 0.030 |
| beta_animal | 90/90 | 100% | 0.107 → 0.094 → 0.053 | 0.096 → 0.064 → 0.049 |
| student_spatial | 83/90 (26/28/29) | tracks conv | 0.129 → 0.103 → 0.065 | 0.087 → 0.058 → 0.052 |

## Control — true `sd_slp = 0` (`recovery-summary-control.tsv`)

Slope SD collapses to ≈0 while the intercept SD is still recovered → the two SDs are
**separately identified**; no false-positive slope heterogeneity:

| family | mean sd_slp (truth 0) | mean sd_int (recovered) |
| --- | --- | --- |
| gamma_relmat | 0.008 | 0.475 |
| student_spatial | 0.003 | 0.478 |
| beta_animal | 0.037 | 0.379 |

## Verdict

All three recover (RMSE falls with levels; control confirms separability). **gamma** and
**beta** are clean at 100% convergence/pdHess. **student_spatial** recovers with a
documented small-sample caveat: convergence 86.7% → 96.7% across the ladder (heavy tails +
spatial structure at few sites); use `n_levels ≥ 20` for reliable fits. Honest bucket:
`point_fit` / `non_gaussian_point_only`, coverage/interval unsupported.

## Reproduce

```sh
Rscript recovery-ladder.R full      # crossed ladder → recovery-{raw,summary}.tsv
Rscript recovery-ladder.R control   # null-slope control → recovery-{raw,summary}-control.tsv
```
