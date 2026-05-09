# After Task: Explicit TMB Data Routing Guard

## Goal

Make `make_tmb_data()` reject unknown internal model labels instead of relying
on a bivariate Gaussian fallthrough after Gaussian and Student-t routes.

## Implemented

- Wrapped the bivariate Gaussian TMB data list in an explicit
  `identical(spec$model_type, "biv_gaussian")` branch.
- Added a final `cli::cli_abort()` for unknown internal model labels.
- Added a package-skeleton regression test for the unknown-label error path.
- Updated the likelihood routing design to say unknown labels are rejected.
- Updated the previous routing after-task note so it no longer records the
  fallthrough as a continuing limitation.

## Mathematical Contract

No likelihood equation changed. The routing contract now matches the
implemented branch map:

```text
gaussian      -> model_type = 1
biv_gaussian  -> model_type = 2
student       -> model_type = 3
```

The hidden phylogenetic prior parity branch, `model_type = 99`, remains
constructed directly by tests rather than by public model fitting.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-package-skeleton.R`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-likelihood-routing-table.md`
- `docs/dev-log/after-task/2026-05-08-explicit-tmb-data-routing-guard.md`

## Checks Run

- `git diff --check`
- `Rscript -e "devtools::test(filter = '^package-skeleton$')"`
- `Rscript -e "devtools::test(filter = '^biv-gaussian$')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: clean.
- Package-skeleton tests: 40 passed, 0 failed.
- Bivariate Gaussian tests: 84 passed, 0 failed.
- Hooke/Emmy read-only review: no P1/P2 findings; one stale after-task P3
  sentence was corrected.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 647 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

## Tests Of The Tests

The new test exercises the failure path directly:

```r
drmTMB:::make_tmb_data(list(model_type = "broken"))
```

That call now errors with an internal unknown-model-type message. The bivariate
targeted tests verify that the explicit `"biv_gaussian"` route still builds
valid `model_type = 2` TMB data through ordinary user fits.

## Consistency Audit

- The source map already documented `model_type = 1`, `2`, `3`, and hidden
  `99`.
- The likelihood design now matches the code: unknown labels are rejected.
- The previous after-task note no longer says the fallthrough is a current
  limitation.

## What Did Not Go Smoothly

The missing guard was discovered while writing architecture documentation, not
while editing code. That is useful: the source map and Rose-style audits are
catching places where implementation and design drift apart.

## Team Learning

Treat architecture tables as executable expectations. If a table says routes
are explicit, add a guard or a test that makes the statement true.

## Known Limitations

This is only internal hardening. It does not change supported families or add
mixed composed families such as `c(gaussian(), poisson())`.

## Next Actions

- Watch GitHub Actions for the pushed commit.
- Continue using explicit routing guards when new families are added.
