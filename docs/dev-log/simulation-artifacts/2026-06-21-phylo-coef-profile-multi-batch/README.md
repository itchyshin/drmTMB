# Multi-coef profile-batch parity (`phylo_coef_profile_bridge`, drmTMB#179 Stage A multi-coef)

**Date:** 2026-06-21 · **Lane:** Julia-via-R bridge · **Claim:** engine-vs-engine
PROFILE parity, NOT interval coverage, NOT release/CRAN.

## What this shows

One `confint(fit, parm = c("mu:(Intercept)", "mu:x"), method = "profile")` call profiles
the whole `mu` block of a Gaussian phylogenetic model in a SINGLE bridge round-trip and
returns every coefficient row (DRM.jl `result$multi`, joined by coefficient name). On
every well-fit cell the batched bridge endpoints match native per-coefficient
`tmbprofile` to **max |Δ| = 2.43e-5** (asserted test tolerance 1e-4).

## Grid

`bf(y ~ x + phylo(1 | species, tree), sigma ~ 1)`, `family = gaussian()`; seeds
{42, 7, 13, 101} × n_tip {40, 80} × coefs {(Intercept), x} = 16 cells.

- **10 / 16 good cells**: native and `engine = "julia"` logLik agree (|Δ| < 1e-2;
  measured ~1e-9). Batched profile endpoints match native to ≤ 2.43e-5 on every one,
  and every batched call returned `j_nrow == 2` (both coefficients in one round-trip).
- **6 / 16 excluded cells** (seed 13 @ n_tip 40; seeds 42, 101 @ n_tip 80): the
  `engine = "julia"` Gaussian phylo-MEAN fit returns a garbage POSITIVE logLik
  (+650, +2.0e15, +2.8e5 against the native −42 … −79) with divergent / ±Inf profile
  endpoints. This is a tracked upstream FIT bug (the deliberate skip at
  `tests/testthat/test-julia-tmb-parity.R:465`), NOT a defect of the batching path —
  the batched call still returned 2 rows. These cells are excluded from the parity
  assertion because there is no valid fit to compare against. The batching plumbing is
  proven correct on valid fits; this slice does NOT repair the Gaussian phylo-mean fit
  route, which itself returns a garbage fit on ~38% (6 / 16) of this grid.

## Files

- `parity.tsv` — per-cell results. Columns: `n_tip`, `seed`, `coef`, `good_fit`,
  `ll_native`, `ll_julia`, `j_nrow`, `t_lower`/`t_upper` (native profile),
  `j_lower`/`j_upper` (julia batched profile), `d_lower`/`d_upper` (|native − julia|).
- `generate.R` — seeded reproducer (sets `drmTMB.DRM.jl.path`, sweeps the grid, writes
  `parity.tsv`). Run under the bridge env: `DRM_JL_PATH`, `DRM_JL_PHYLO_PATH`,
  `JULIA_HOME`, `NOT_CRAN=true`.

## Boundary

Profile only; a SINGLE block (`mu`). Sigma coefficient profiles are not offered (DRM.jl
`parm = :sigma` diverges at the log-sigma boundary). Multi-coef BOOTSTRAP is not batched
(the single-coefficient contract is preserved). Bridge lane only — this is not a
native-TMB-standalone or direct-DRM.jl claim, and not interval coverage.
