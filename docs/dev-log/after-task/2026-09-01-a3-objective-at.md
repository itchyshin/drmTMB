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

## Update 2026-09-01: adversarial-pass fix (penalty convention mismatch)

An independent adversarial pass, reproduced by the coordinator on a
different seed, refuted the anchor's generality: on a penalized (MAP) phylo
fit, `objective_at(fit, <own optimum>)` differed from `-logLik(fit)` by
exactly `fit$phylo_penalty`, silently. Root cause: `fit$logLik` is stored on
the **unpenalized** convention (`-opt$objective + phylo_penalty`,
`R/drmTMB.R:684`), while the first-pass `objective_at()` returned the
**penalized** `obj$fn()` value directly. The original test suite and both
oracle runs used fixed-effect Gaussian fits, which carry no penalty, so the
mismatch was verified only where it could not fail.

**Convention chosen: (a)** -- `objective_at()` now reports on the same
*unpenalized* convention as `logLik()`, not the raw penalized objective the
optimizer minimises. Reasoning: the verb's whole purpose is a cross-engine,
cross-point comparison, and a return value whose meaning silently depends on
fit type (penalized vs. not) is worse than useless for that; a hard error on
every penalized fit (option b) would also block the ordinary case this
diagnostic exists for (comparing a MAP fit's objective at another engine's
point). The documented cost: for a penalized fit, `objective_at()` no longer
equals what `fit$obj$fn()` alone would return at that point -- use
`fit$obj$fn()` directly if the raw penalized objective is what is wanted.
This is stated as a single actionable sentence in both the roxygen `@return`
paragraph and `NEWS.md`.

**Implementation.** After `object$obj$fn(full)`, the penalty is
re-evaluated **at the queried point** via `object$obj$report()$phylo_penalty`
(not the frozen `object$phylo_penalty` cached at the fit's own optimum) and
subtracted, so the unpenalized convention holds away from the optimum too,
not only at it. The re-pin to the fit's own optimum (`fn()` then `report()`
then `drm_pin_tmb_object_to_optimum()`) is unchanged; `report()` reads
`obj$env$last.par` as left by the immediately preceding `fn(full)` call, so
no extra argument marshalling is needed.

**MSPL guard.** `objective_at.drmTMB()` now calls
`drm_abort_mspl_inference(object, "objective_at")` first, matching
`logLik()`, `confint()`, and `profile()`. Before the fix this path was
unguarded: `logLik()` aborts on MSPL fits but `objective_at()` did not, so
the same class of silent, undefined comparison was reachable there too.

**New tests** (`tests/testthat/test-objective-at.R`, +6 test blocks): a
penalized MAP phylo fit anchored against `-logLik(fit)` at its own optimum
(fixef labels only -- `sd:` labels are not addressable for `phylo()` random
effects, a pre-existing and out-of-scope limitation of the public start
label vocabulary), and an MSPL fit asserting `objective_at()` errors with
class `drmTMB_mspl_inference_unsupported`, matching `logLik()`. Verified RED
against the pre-fix code (`git stash` on `R/objective-at.R` alone): the
penalized-phylo test failed with `actual: 34.7` vs `expected: 32.1`
(matching the coordinator's report), and the MSPL test failed because no
error was thrown. GREEN with the fix: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 18
]` for `test-objective-at.R` alone.

Oracle: `Rscript ".../.unlazy/rev-parity/bin/objective-at-anchor.R"` still
prints `OBJECTIVE AT ANCHOR OK` (that fixture is unpenalized fixed-effect
Gaussian, so it exercises the fixed branch of the convention, unchanged by
this fix).

Filtered suite: `devtools::test(filter = "objective|profile|start")`:
`[ FAIL 0 | WARN 6 | SKIP 0 | PASS 1153 ]` (up from 1147; the same 6
pre-existing `sd_phylo1()`/`sd_phylo2()` deprecation warnings in
`test-profile-targets.R`, unrelated). Did not run the full suite (another
run was already in progress elsewhere per the coordinator's instruction).
