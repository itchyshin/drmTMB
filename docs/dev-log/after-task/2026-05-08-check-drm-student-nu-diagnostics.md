# After Task: `check_drm()` Student-t `nu` Diagnostics

## Goal

Add a first-pass diagnostic for Student-t `nu` so robust continuous fits flag
tail-shape boundary behaviour before users interpret coefficients or fitted
values.

## Implemented

- `check_drm()` now adds a `student_nu` row for Student-t models.
- It returns `error` when fitted `nu` is non-finite or not above 2.
- It returns `warning` when fitted `nu` is very close to the finite-variance
  boundary at 2.
- It returns `note` when fitted `nu` is large enough that the Student-t fit may
  be close to Gaussian.
- README, overview, model-workflow, NEWS, roxygen, and design documentation now
  describe the same diagnostic surface.

## Mathematical Contract

The implemented Student-t family uses

```text
nu_i = 2 + exp(eta_nu_i)
```

so the response-scale parameter should satisfy `nu_i > 2` for every fitted
observation. `check_drm()` inspects the fitted response-scale vector, not only
the coefficient vector, because future and current formulae can make `nu_i`
vary with predictors.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `README.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-workflow.Rmd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `man/check_drm.Rd`
- `NEWS.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'check-drm|student-location-scale')"`
- `Rscript -e "devtools::document()"`
- `air format .` failed because `air` is not installed.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

All targeted tests, full tests, pkgdown checks, pkgdown build, and package
check passed after the implementation and documentation updates.

## Tests Of The Tests

The first targeted test failed because the initial "ordinary" Student-t fixture
landed at the `nu = 2` boundary. That showed the diagnostic was active and the
fixture was wrong for the intended ok branch. The final tests use controlled
coefficient mutations to exercise ok, near-boundary warning, large-`nu` note,
non-finite error, and predictor-varying range behaviour.

## Consistency Audit

Rawls reviewed the patch and found two P2 issues: user-facing diagnostic lists
omitted finite-objective checks in some places, and tests did not cover the
error branch or predictor-varying `nu`. Both were fixed before closure.

Stale-wording scans checked the `check_drm()` diagnostic lists and Student-t
`nu` wording across source docs, generated pkgdown pages, tests, and NEWS.

## What Did Not Go Smoothly

A stale-wording search initially used backticks inside a double-quoted shell
command, which made `zsh` try to execute `check_drm()` and `nu` as commands.
The scan was rerun with safe quoting.

## Team Learning

For diagnostics of distributional shape parameters, tests should separate
"does the optimizer estimate this from data" from "does the diagnostic classify
known fitted values correctly." Controlled coefficient mutations are a good
tool for the second job.

## Known Limitations

- The thresholds `nu < 2.05` and `nu > 100` are pragmatic first-pass
  diagnostics, not formal inferential rules.
- `check_drm()` does not yet compare Student-t and Gaussian fits automatically.
- Profile-likelihood or bootstrap uncertainty for `nu` is future work.

## Next Actions

- Consider adding a model-comparison helper or vignette note for Gaussian
  versus Student-t fits.
- Add profile-likelihood confidence intervals later once the common profiling
  API is designed.
