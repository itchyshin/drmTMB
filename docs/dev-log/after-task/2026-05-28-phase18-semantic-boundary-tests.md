# After-Task Report: Phase 18 Semantic Boundary Tests

Date: 2026-05-28

## Goal

Add the next narrow Team A and Team B test hardening slice after PR #349:
Tweedie comparator cells should reassert public `fitted()` and `nu` semantics,
and skew-normal should keep a no-fit boundary tied to the new first-test
contract.

## Implemented

`tests/testthat/test-tweedie-location-scale.R` now checks, inside each
optional `glmmTMB` comparator cell, that `fitted(fit)` equals
`predict(fit, dpar = "mu")`, response-scale `nu` stays in `(1, 2)`, and
response-scale `nu` matches the inverse-link transform from the link-scale
prediction.

`tests/testthat/test-skew-normal-boundary.R` now reads
`docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md` and
checks planned-only syntax, absent-constructor wording, no-C++ admission
criteria, and the `rho12` exclusion.

## Files Changed

- `tests/testthat/test-tweedie-location-scale.R`
- `tests/testthat/test-skew-normal-boundary.R`
- `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`
- `docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-tweedie-location-scale.R tests/testthat/test-skew-normal-boundary.R docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-semantic-boundary-tests.md
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Focused Tweedie location-scale and skew-normal-boundary tests passed.
`pkgdown::check_pkgdown()` reported no problems, and `git diff --check` was
clean.

## Tests Of The Tests

The Tweedie additions run inside the optional external-comparator fixture, so
they combine the public semantic checks with independent `glmmTMB`
coefficient, power, and log-likelihood comparisons. The skew-normal additions
are boundary tests: they assert that the design files stay planned-only while
the constructor remains absent.

## Consistency Audit

No new model surface was opened. Tweedie remains fixed-effect, univariate, and
intercept-only in `nu`. Skew-normal remains design-only with no constructor,
R builder, TMB branch, reference page, or runnable example.

## Next Actions

Team A can move to weights, offsets, or missing-row comparator documentation.
Team B can move to support/missingness and rank-deficiency decisions before
source-level skew-normal density tests.
