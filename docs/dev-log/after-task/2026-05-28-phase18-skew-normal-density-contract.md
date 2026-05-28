# After-Task Report: Phase 18 Skew-Normal Density Contract Fixture

Date: 2026-05-28

## Goal

Turn the accepted skew-normal moment-parameterization math into a test-only
density fixture while keeping `skew_normal()` absent.

## Implemented

`tests/testthat/helper-skew-normal-density.R` now provides test-only reference
helpers for the public-moment to native-density transform, log density, third
central moment, and numerical density integral.

`tests/testthat/test-skew-normal-density-contract.R` checks that the transform
preserves public `mu` and `sigma`, integrates to one, reduces to the Gaussian
location-scale density at `nu = 0`, records the expected public sign
orientation, and still leaves the `skew_normal()` constructor absent.

The Phase 18 simulation programme and roadmap now record this as density
contract evidence before implementation, not fitted skew-normal support.

## Files Changed

- `tests/testthat/helper-skew-normal-density.R`
- `tests/testthat/test-skew-normal-density-contract.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/helper-skew-normal-density.R tests/testthat/test-skew-normal-density-contract.R docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-skew-normal-density-contract.md
Rscript --vanilla -e "devtools::test(filter = '^skew-normal-(boundary|density-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); stopifnot(!exists('skew_normal', envir = asNamespace('drmTMB'), inherits = FALSE)); cat('skew_normal constructor absent\n')"
rg -n "skew_normal\\(" R src NAMESPACE man
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.
Focused `test-skew-normal-boundary` and
`test-skew-normal-density-contract` passed, the constructor-absence check
confirmed that `skew_normal` is absent, the package-code support scan found no
matches, and `git diff --check` was clean.

## Known Limitations

This is not a fitted-family PR. It adds no `skew_normal()` constructor, no
`R/` family code, no `src/` or TMB branch, no `NAMESPACE` entry, no
formula-grammar change, no exported documentation, and no user-facing example.
It does not test optimization, recovery, malformed-neighbour errors,
extractors, simulation, intervals, or runtime.
