# After Task: Structured Gaussian Public Prose Cleanup

## Goal

Advance #442 by making public prose distinguish fitted one-slope Gaussian `mu`
support from Phase 18 Actions or artifact readiness for `phylo()`, `spatial()`,
`animal()`, and `relmat()`.

## Implemented

- `vignettes/phylogenetic-spatial.Rmd` now teaches the structural-dependence
  ladder with the current fitted boundary: all four structured layers have a
  first univariate Gaussian one-slope `mu` route, while multiple structured
  slopes, slope correlations, structured residual `rho12`, structured `sigma`
  slopes, and non-Gaussian structured slopes remain planned.
- The route table now names one-slope `animal()`, `phylo()`, `spatial()`, and
  `relmat()` examples and keeps the combined `phylo()` plus `spatial()` route
  planned.
- `ROADMAP.md` no longer says the phylogenetic path lacks the first one-slope
  baseline. It now separates fitted one-slope routes from Actions artifact
  readiness.
- `README.md` adds the same conservative artifact boundary: only
  `spatial_mu_slope` is currently a manual Phase 18 Actions task; `phylo()`,
  `animal()`, and `relmat()` one-slope artifact rows remain wrapper targets.

## Boundary

This was a prose and status-ledger cleanup only. It did not change likelihood
code, formula grammar, registry data, tests, simulations, or pkgdown-generated
HTML. q=4 remains fitted and diagnostic-heavy, with derived intervals limited
or unavailable unless a direct profile target is explicitly available.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
checks used focused source scans plus `git diff --check`; no R tests were run
because executable code did not change.
