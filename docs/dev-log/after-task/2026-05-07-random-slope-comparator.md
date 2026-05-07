# After-Task Report: Random-Slope Comparator Smoke Test

Date: 2026-05-07

## Task

Add a Tier 1 comparator check for the newly implemented independent Gaussian
`mu` random-slope model.

## Outcome

Added a test comparing:

```r
drmTMB(
  bf(y ~ x + (1 | id) + (0 + x | id)),
  family = gaussian(),
  data = dat
)
```

against the equivalent maximum-likelihood `lme4` model:

```r
lme4::lmer(
  y ~ x + (1 | id) + (0 + x | id),
  data = dat,
  REML = FALSE
)
```

The comparison covers:

- fixed-effect estimates;
- independent random-intercept and random-slope SDs;
- residual SD;
- marginal log-likelihood.

The test uses `skip_if_not_installed("lme4")` so the package remains checkable
when optional comparator packages are unavailable.

## Consistency Check

The comparator deliberately uses separate random-effect terms, not
`(1 + x | id)`. This matches the implemented `drmTMB` covariance semantics:
independent random intercept and random slope. Correlated random-slope blocks
remain a future feature and need a separate comparator after implementation.

## Validation

Command run:

```text
Rscript -e "devtools::test(filter = 'comparators')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
git diff --check
```

Result:

- targeted comparator tests: 14 passed, 0 failed.
- full `devtools::test()`: 191 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

## Files Changed

- `tests/testthat/test-comparators.R`
  - added the independent random-slope comparator test.
- `docs/design/05-testing-strategy.md`
  - moved independent random-slope comparator coverage to implemented checks;
  - kept correlated random-slope comparator coverage as planned.
- `docs/dev-log/check-log.md`
  - recorded scope, command, result, and remaining limitation.

## What Did Not Go Smoothly

- The main risk was accidentally comparing against the wrong `lme4` syntax.
  The comparator uses `(1 | id) + (0 + x | id)` because this matches
  independent covariance semantics exactly.

## Team Learning

- Fisher should continue checking that comparator tests match the same
  likelihood, estimation mode, and covariance structure before results are
  treated as evidence.
- Rose should flag any future wording that says "random slopes agree with
  lme4" without specifying independent versus correlated random slopes.
