# After task: message when unused factor levels are dropped (#1584)

**Reader:** drmTMB users who `subset()` data and then fit.

**What changed.** `drm_droplevels_fixed_predictors()` (R/drmTMB.R) still drops
unused levels from fixed-effect factor predictors, but now emits a
`cli::cli_inform()` message of class `drmTMB_dropped_factor_levels` naming the
column and the dropped levels. Users can silence it with `droplevels(data)`.

**Test.** `tests/testthat/test-dinnage-audit-wave1.R` (#1584): fails on main
(no message), passes with the fix; also checks no message when nothing is unused.

**Local suite.** Full testthat run (R 4.3.3, `%||%` shimmed): 6 failures, all
identical on unmodified main (glmmTMB comparator tests, sparse-state
reconciliation, vignette manifest) — environment-related, not touched here.
`devtools::document()` produced no change attributable to this PR (only
roxygen-version churn, reverted); no Rd regenerated.
