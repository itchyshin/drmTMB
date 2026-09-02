# A3: `objective_at()` -- evaluate the fitted objective at a supplied point

**Date:** 2026-09-01
**Branch:** `claude/rev-parity-a3-objective-at`
**Design:** `docs/design/35-optimizer-start-map-multistart.md`, "Objective At A Point"

## What changed

- New `R/objective-at.R`: exported S3 generic `objective_at(object, ...)` and
  a `drmTMB` method `objective_at.drmTMB(object, at, ...)`.
- `at` is a named list keyed by the same public start labels as
  `drm_control(start = ...)` (`fixef:<dpar>:<column>`, `sd:<dpar>:<term>`,
  `cor:<dpar>:<term>`). Label parsing and internal-slot resolution reuse
  `drm_parse_public_start_label()` and `drm_resolve_public_start_target()`
  from `R/drmTMB.R` verbatim -- no second translation layer.
- Evaluation reuses the pattern already used for profile-CI endpoints
  (`profile_endpoint_evaluator()`, `profile_lincomb()` in `R/profile.R`):
  copy `fit$opt$par`, splice in the resolved positions (found by matching
  `names(fit$opt$par)` against the resolved TMB component, exactly as
  `profile_lincomb()` does), call `fit$obj$fn(full)`.
- **No mutation**: `drm_pin_tmb_object_to_optimum()` is called both before
  and after the `fn()` call, restoring `obj$env$last.par` /
  `last.par.best` to the fit's selected optimum.
- Unknown labels, non-numeric/non-finite values, and unnamed elements of
  `at` all error before `fn()` is ever called.

## Return shape

A single unnamed numeric scalar (the TMB objective at `at`). The oracle does
`if (is.list(got)) got[[1L]] else got`, so a bare scalar satisfies it
directly without the list branch.

## Tests

`tests/testthat/test-objective-at.R` (new, 6 `test_that()` blocks / 12
expectations): generic + method existence, the self-consistency anchor
(`objective_at(fit, at = <own optimum>)` == `-logLik(fit)`), no-mutation via
`vcov()` before/after, monotonic increase when perturbed off the optimum,
`sd:` label support, and error paths (unknown label, malformed `at`).

Ran RED first (`could not find function "objective_at"` -- 8 failures for
the right reason), then GREEN: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]`.

## Oracle

```
Rscript ".../.unlazy/rev-parity/bin/objective-at-anchor.R"
OBJECTIVE AT ANCHOR OK
```

## Filtered suite

`devtools::test(filter = "objective|profile|start")`: `[ FAIL 0 | WARN 6 |
SKIP 0 | PASS 1147 ]`. The 6 warnings are pre-existing `sd_phylo1()` /
`sd_phylo2()` deprecation warnings in `test-profile-targets.R`, unrelated to
this change. Did not run the full suite (43-46 min; reserved for the
integration gate).

## Scope discipline

`devtools::document()` also rewrote `man/confint.drmTMB.Rd` (roxygen-version
prose drift: `` \code{exp()} `` -> `exp()`) and added two unrelated new man
pages (`drm_julia_joint_prepare.Rd`, `drm_julia_joint_result.Rd`) from other
in-tree roxygen comments. Reverted `confint.drmTMB.Rd` to its committed text
and removed the two unrelated new man pages by hand so the diff is scoped to
`objective_at()`.

## Boundary (unchanged, per task brief)

Did not touch the Julia-bridge objective-at counterpart (design 35's "The
bridge counterpart" section) -- that is a separate, held slice. Did not
touch `tests/testthat/test-start-contract.R`, `.unlazy/**`,
`R/julia-bridge.R`, `R/check.R`, `inst/extdata/julia-capabilities.tsv`,
`docs/dev-log/coordination-board.md`, or `.github/workflows/`.
