# After Task: `check_drm()` SE and SD Diagnostics

## Goal

Finish the interrupted `check_drm()` diagnostic expansion so fitted models report
two common inference warning lights before users interpret fixed effects or
random-effect variance components.

## Implemented

- Added a `standard_errors_finite` row to `check_drm()`.
- Added a `random_effect_sd_boundary` row to `check_drm()` for fits with fitted
  random-effect standard deviations.
- Added `sd_boundary` as a user-facing threshold argument, defaulting to `1e-4`.
- Updated the `check_drm()` documentation and NEWS entry.
- Added tests for ordinary successful fixed-effect SE extraction, non-finite
  fixed-effect SEs, near-zero random-effect SDs, non-positive random-effect SDs,
  and `sd_boundary` validation.

## Mathematical Contract

No likelihood equations, formula grammar, or parameter transforms changed.
`check_drm()` inspects fitted objects after optimization.

For fixed effects, the diagnostic reads the diagonal of `vcov(fit)` and checks
that every standard error is finite. This is a post-fit inference diagnostic; it
does not replace the Hessian positive-definiteness row.

For random-effect standard deviations, the diagnostic reads `fit$sdpars` on the
response scale. A non-finite or non-positive value is an `error`; a positive
value below `sd_boundary` is a `warning` because the variance component is close
to the lower boundary at zero.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-workflow.Rmd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd docs/design/16-phylo-spatial-common-math.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and refreshed
  `man/check_drm.Rd`.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 71
  expectations, 0 failures, 0 warnings, 0 skips.
- `Rscript -e "devtools::test(filter = 'check-drm|control')"`: passed with 139
  expectations, 0 failures, 0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1657 expectations, 0 failures,
  0 warnings, 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/check_drm.html` and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n "standard_errors_finite|random_effect_sd_boundary|sd_boundary|standard errors|finite fixed-effect standard errors|random-effect standard deviations|random-effect standard deviations near zero" R/check.R tests/testthat/test-check-drm.R man/check_drm.Rd NEWS.md vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd docs/design/16-phylo-spatial-common-math.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-check-drm-se-sd-diagnostics.md pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, generated documentation, NEWS, and generated-site
  wording.
- `rg -n 'optimizer convergence, fixed gradients|scale positivity|known sampling covariance summaries, and random-effect design|Current first-pass.*check_drm\\(\\).*optimizer convergence, fixed-parameter gradients' README.md ROADMAP.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  found only the historical `NEWS.md` / generated-news 0.1.0 release bullet,
  which was true for that release and intentionally left unchanged.

## Tests Of The Tests

The new tests mutate otherwise valid fitted objects. That keeps the diagnostic
branches deterministic without relying on an optimizer to land exactly on a
singular covariance matrix or a near-zero variance component.

## Consistency Audit

The source, generated Rd topic, NEWS bullet, overview vignette, model-workflow
vignette, structured-effect design note, unit tests, and check log now name the
same two diagnostics: finite fixed-effect standard errors and random-effect
standard deviations near the lower boundary.

## What Did Not Go Smoothly

The interrupted patch had added calls to missing helper functions, so every
`check_drm()` call failed until those internals were completed. The first audit
also found older prose lists in the overview vignette, model-workflow vignette,
and phylogenetic/spatial design note; those were synchronized before closing.

## Team Learning

- Rose: diagnostic changes need a stale-list scan because `check_drm()` is
  described in prose as well as Rd output.
- Pat: the warning should tell users what to inspect next, not just print a
  small SD value.
- Fisher: a near-zero random-effect SD is a boundary diagnostic, not an
  automatic decision to simplify the model.

## Known Limitations

- The standard-error row checks fixed-effect SEs from `vcov(fit)`. It does not
  yet report profile-likelihood interval failures or random-effect uncertainty.
- The random-effect SD boundary row is a first-pass diagnostic. It flags small
  fitted SDs but does not prove whether a variance component should be removed.

## Next Actions

- Keep future `check_drm()` additions synchronized across the overview vignette,
  model-workflow vignette, reference documentation, and generated examples.
- Add profile-interval failure diagnostics separately if profile-likelihood
  intervals become part of the default post-fit workflow.
