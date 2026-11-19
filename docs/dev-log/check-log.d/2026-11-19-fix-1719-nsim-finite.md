# Check log: finite `nsim` guard for sibling count validators (#1719)

**Date:** 2026-11-19
**Branch:** `cursor/fix-1719-count-validators-inf-726d`

## Change

New internal `drm_validate_nsim()` in `R/utils.R` requires one numeric,
finite, whole `nsim` in `[1, .Machine$integer.max]` and returns it as an
integer. It replaces the inline checks in `drm_quantile_residuals()`
(`R/adequacy.R`), `simulate.drm_pair_association()` (`R/associate-pairs.R`)
and the three Julia marginal simulators in `R/julia-simulate.R` (Binomial
SD, Gamma animal SD, NB2 animal SD slope). `simulate.drmTMB()` is not
touched; its guard is #1696.

## Failure on main

`74007c485`. `nsim = Inf` at each of the five sites gave the warning "NAs
introduced by coercion to integer range" and then the base-R `simpleError`
"missing value where TRUE/FALSE needed" (the old `nsim != as.integer(nsim)`
comparison is `NA`). `tests/testthat/test-fix-1719-nsim-finite.R`: all 5
tests error on main.

## Verification with the fix

R 4.6.2, TMB 1.9.25, `pkgload::load_all()`.

| File | Result |
| --- | --- |
| `test-fix-1719-nsim-finite.R` | 155 pass |
| `test-adequacy.R` | 20 pass, 2 skips (`tweedie` not installed) |
| `test-associate-pairs-*` (arc6, bernoulli-bernoulli, bernoulli-nb2, gaussian-bernoulli, gaussian-nb2, nbinom2-nbinom2) | pass, 0 failures |
| `test-julia-predict-quantile.R`, `test-julia-binomial-sd.R`, `test-binomial-sd-simulation.R` | pass, live-Julia skips only |
| Gamma/NB2 animal simulation files | pass, live-Julia skips only |

## Claim boundary

Error wording for these five sites changes to one shared sentence; no
existing test pinned the old wording. No simulation draw changes for valid
`nsim`.
