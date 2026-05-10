# After Task: Team Feedback Usability Audit

## Goal

Act on Noether, Boole, and Curie's review feedback after the `0.1.1` dispatch,
while keeping changes small and testable.

## Implemented

- Tightened README scale wording so `sigma^2` is described as the Gaussian
  residual-variance and meta-analytic heterogeneity summary, not as a universal
  shortcut for every family.
- Added `check_drm()` and response-scale `sigma` interpretation to the README
  install smoke path.
- Changed README capability wording from residual variation to
  family-specific variation for non-Gaussian location-scale families.
- Added zero-truncated and hurdle NB2 variance equations to the response-family
  article.
- Added large-data prose explaining how to interpret the `optimizer_budget`
  diagnostic row.
- Clarified `drm_control()` usage: optimizer-only settings can be a plain
  control list, but optimizer settings inside `drm_control()` must go in
  `optimizer = list(...)`.
- Canonicalized extractor examples from `sigma = ~ ...` to `sigma ~ ...`.
- Marked the `0.1.0` Phase 9 roadmap note as historical.
- Added a bivariate known-sampling-covariance memory-light storage test.

## Mathematical Contract

No likelihood equations or parameter transforms changed. The response-family
article now documents existing truncated and hurdle NB2 variance formulas that
were already implemented.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `R/control.R`
- `R/methods.R`
- `man/drm_control.Rd`
- `man/predict.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`
- `man/summary.drmTMB.Rd`
- `tests/testthat/test-control.R`
- `vignettes/distribution-families.Rmd`
- `vignettes/large-data.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-team-feedback-usability-audit.md`

## Checks Run

- `air format README.md vignettes/distribution-families.Rmd vignettes/large-data.Rmd R/control.R R/methods.R ROADMAP.md tests/testthat/test-control.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'control')"`: passed with 68 tests, 0
  failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed.
- `Rscript -e "devtools::test()"`: passed with 1,480 tests, 0 failures, 0
  warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `git diff --check`: passed.
- `rg -n 'sigma = ~|Gaussian residual-variance|family-specific variation|optimizer_budget|Var\\[y_i \\| y_i > 0\\]|Historical .*0\\.1\\.0|memory-light storage keeps bivariate known-V' README.md ROADMAP.md R man tests/testthat/test-control.R vignettes pkgdown-site --glob '!pkgdown-site/search.json'`:
  passed; no `sigma = ~` examples remained.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes for `drmTMB 0.1.1`.

## Tests Of The Tests

The new bivariate storage-control test combines three behaviours that users are
likely to combine in practice: a dense known sampling covariance matrix,
memory-light fitted-object storage, and post-fit extractors. It verifies that
`fitted()`, `residuals(type = "pearson")`, `simulate()`, `sigma()`, `rho12()`,
`corpairs()`, and `check_drm()` still work when the original data, model frame,
and TMB object are not retained.

## Consistency Audit

Noether reviewed scale-language and equation consistency after the edits and
reported no blockers. Boole reviewed user-facing syntax and install guidance
and reported no blockers. Curie reviewed the new storage-control test for
runtime and fragility and reported no blockers.

## What Did Not Go Smoothly

The team missed a few basics before this audit: stale `sigma = ~` examples,
unclear `drm_control()` nesting guidance, and a too-broad `sigma^2` statement in
the README. The correction is procedural: every user-facing release pass now
needs Pat/Boole syntax review and Rose/Noether scale-language review before
claiming the install path is ready.

## Team Learning

Use `sigma` as the public modelling parameter, and reserve `sigma^2` wording for
Gaussian residual-variance and meta-analytic heterogeneity summaries unless a
family-specific transformation is stated. Installation examples should use
`pak`, call `check_drm()`, and show one response-scale interpretation users can
copy into their own notes.

## Known Limitations

The bivariate memory-light test is a focused method-availability smoke test; it
does not replace broad large-data benchmarks or sparse fixed-effect work.

## Next Actions

- Continue the sparse fixed-effect matrix design before claiming million-row
  readiness.
- Add broader benchmark evidence when a stable large-data fixture exists.
