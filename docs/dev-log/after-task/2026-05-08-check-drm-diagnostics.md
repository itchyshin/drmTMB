# After Task: `check_drm()` Fit Diagnostics

## Goal

Add a first-pass diagnostic function that helps users inspect a fitted
`drmTMB` model before interpreting coefficients, fitted values, residual
correlations, random-effect scales, or structured-effect summaries.

## Implemented

- Added exported `check_drm()` and `check_drm.drmTMB()`.
- Added `print.drm_check()` for compact status output.
- Returned a `drm_check` data frame with columns `check`, `status`, `value`,
  and `message`.
- Added `attr(x, "ok")`, which is `FALSE` when any check has status
  `warning` or `error`.
- Added checks for:
  - optimizer convergence;
  - finite objective and log-likelihood values;
  - fixed-parameter gradient size;
  - positive-definite Hessian flag from `TMB::sdreport()`;
  - dropped rows;
  - positive fitted scale values;
  - bivariate residual `rho12` boundary values;
  - known sampling covariance summaries, including dense matrix
    rank/conditioning;
  - ordinary random-effect replication;
  - ordinary random-slope design variation;
  - phylogenetic species replication.

## Mathematical Contract

`check_drm()` does not change the likelihood. It inspects the fitted model and
reports whether basic numerical and design conditions look plausible.

For bivariate Gaussian models, the residual correlation check is on the
response scale:

```text
rho12_i = tanh(eta_rho12_i)
```

The boundary diagnostic flags fitted `rho12_i` values whose absolute value is
larger than the requested threshold.

For known sampling covariance, the diagnostic records whether the model used a
diagonal/vector representation or a dense matrix representation. For dense
matrices it reports rank and a rough condition number based on the positive
eigenvalues of the symmetrised covariance matrix.

For random slopes, the design diagnostic checks whether the fitted data contain
within-group variation in random-slope design values and whether implemented
correlated random-effect blocks have the expected within-group design rank.
This is a warning-light check, not a formal identifiability proof.

## Files Changed

- `R/check.R`
- `NAMESPACE`
- `man/check_drm.Rd`
- `tests/testthat/test-check-drm.R`
- `_pkgdown.yml`
- `README.md`
- `NEWS.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'check-drm')"`: 38 passed, 0 failed.
- `Rscript -e "devtools::test()"`: 556 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::build_site()"`: completed successfully and generated
  `reference/check_drm.html`.
- Generated-site search found `check_drm()` on the home page, reference index,
  reference page, getting-started article, location-scale article,
  bivariate-coscale article, and changelog.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The test suite mutates otherwise valid fitted objects to force diagnostic
  branches for nonzero optimizer convergence, non-finite objective values,
  gradient evaluation failure, non-finite gradients, non-positive-definite
  Hessian status, and scale-extraction failure.
- Dedicated tests cover dropped-row notes, `rho12` boundary warnings, singleton
  random-effect replication notes, weak random-slope design notes, dense known
  sampling covariance summaries, phylogenetic replication notes, scalar
  threshold validation, and unused `...` rejection.
- The print test captures both `cli` message output and data-frame output so
  the test log stays readable.

## Consistency Audit

- `check_drm()` is exported in `NAMESPACE`, documented in `man/check_drm.Rd`,
  and listed in `_pkgdown.yml`.
- README, NEWS, the overview vignette, location-scale tutorial, bivariate
  coscale tutorial, and structured-effect design note now describe the same
  first-pass diagnostic surface.
- `pkgdown::build_site()` was rerun after source documentation changed.
- The generated pkgdown site was searched directly for `check_drm`, known
  sampling covariance summaries, weak random-slope wording, logo/favicons, and
  changelog content.

## What Did Not Go Smoothly

- The first dropped-row test expected `attr(x, "ok")` to be `FALSE` for a
  `note`; this was corrected so only `warning` and `error` statuses make the
  whole check fail.
- The first print test used `expect_output()` and missed the `cli` header
  stream. It now captures both streams explicitly.
- Reviewer and systems-audit passes caught that the exported function was
  initially under-explained in vignettes and generated pkgdown pages.
- The first known-`V` and random-slope diagnostics were too thin. They now
  report dense known-covariance rank/conditioning and weak within-group
  random-slope design variation.

## Team Learning

- Diagnostics should be treated like user-facing modelling functions: exported
  function, reference docs, examples, tests, vignettes, NEWS, generated site,
  check-log, and after-task report must move together.
- A diagnostic row with status `note` should mean "inspect this" rather than
  "the model failed"; the status semantics need to stay stable across future
  checks.
- Tests for diagnostics need synthetic failure objects as well as successful
  fitted models.
- `pkgdown::check_pkgdown()` is not a freshness check; generated pages must be
  rebuilt and searched after reference or vignette changes.

## Known Limitations

- `check_drm()` is not a substitute for simulation recovery, comparator checks,
  profile-likelihood CIs, or bootstrap diagnostics.
- Random-slope design checks are simple within-group variation and rank checks;
  they do not prove random-effect variance components are identifiable.
- Dense known-covariance diagnostics report rank and conditioning but do not
  yet recommend a remedy.
- Future phylogenetic plus non-phylogenetic species effects, spatial fields
  plus site/study effects, and cross-formula covariance blocks still need
  separability diagnostics.

## Next Actions

- Add `check_drm()` examples to future phylogenetic and meta-analysis tutorials
  when those workflows are expanded.
- Add comparator-backed diagnostics for `check_drm()` once profile-likelihood
  and bootstrap uncertainty tools arrive.
- Keep the diagnostic surface conservative: add new rows only when tests can
  force both ordinary and problematic cases.
