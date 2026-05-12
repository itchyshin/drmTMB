# After Task: Covariance Profile Intervals In Summary

## Goal

Check that `summary(conf.int = TRUE, method = "profile")` can attach profile
intervals to the implemented group-level covariance rows that already appear in
`summary(fit)$parameters`.

## Implemented

Extended the existing summary tests for:

```r
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))
```

and:

```r
bf(
  mu1 = y1 ~ x + (1 | p | id),
  mu2 = y2 ~ x + (1 | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

The tests request profile intervals for the `corpars$mu_sigma` and
`corpars$mu` rows, then check that the reported summary bounds are finite and
surround the fitted correlation estimate.

## Mathematical Contract

This task did not change summary or profiling code. It verifies that the
summary table can carry profile intervals for direct random-effect correlation
targets exposed by `profile_targets()`.

## Files Changed

- `tests/testthat/test-summary.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-covariance-profile-intervals-in-summary.md`

## Checks Run

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 63
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'summary\(conf.int = TRUE|corpars\$mu_sigma|corpars\$mu|residual rho12|profile bounds|method = "profile"' tests/testthat/test-summary.R docs/dev-log/after-task/2026-05-12-covariance-profile-intervals-in-summary.md docs/dev-log/check-log.md`:
  confirmed the summary profile path, covariance row estimates, residual-`rho12`
  boundary wording, and check-log entry.
- `git diff --check`: passed.

## Tests Of The Tests

The tests use existing deterministic summary fixtures and request profile
intervals through the public `summary()` path, not by calling the lower-level
profile helper directly. Each check verifies that the summary interval brackets
the fitted row estimate.

## Consistency Audit

No user-facing documentation changed. The assertions keep group-level
covariance rows separate from residual `rho12` and verify the same row names
that users see in `summary(fit)$parameters`.

## What Did Not Go Smoothly

Nothing unusual. Smoke tests confirmed finite bounds before the assertions were
added.

## Team Learning

- Ada kept this as a summary-surface follow-up to the direct `confint()` tests.
- Curie checked the public summary path rather than duplicating lower-level
  profile mechanics.
- Noether kept `mu_sigma`, bivariate `mu`, and residual `rho12` namespaces
  separate.

## Known Limitations

- The tests cover profile intervals for direct covariance rows only.
- Derived covariance summaries and larger structured covariance blocks remain
  outside this slice.

## Next Actions

1. Stop adding adjacent profile tests unless a new implemented target appears.
2. Use the next checkpoint for broader validation or for reviewing the current
   worktree boundary before committing.
