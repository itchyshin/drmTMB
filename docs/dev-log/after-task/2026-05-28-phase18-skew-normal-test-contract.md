# After-Task Report: Phase 18 Skew-Normal First-Test Contract

Date: 2026-05-28

## Goal

Team B recorded the first-test contract for the planned skew-normal lane before
any `skew_normal()` constructor, test fixture, or C++ likelihood branch is
added. The reader is the future implementation contributor who must write the
density and boundary tests before claiming fitted support.

## Implemented

Added `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`.
The note keeps the first lane univariate and fixed-effect, with `mu` as the
response mean, `sigma` as the response standard deviation, and `nu` as the
residual slant or shape parameter.

## Mathematical Contract

The contract uses the moment-to-native transform from the previous
parameterization decision:

```text
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
```

The future density test must include constants, integrate to one, and match a
trusted native-density comparator after transforming to `xi`, `omega`, and
`alpha = nu`. At `nu = 0`, the density must reduce to the Gaussian
location-scale density with the same `mu` and `sigma`.

## Files Changed

- `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-tweedie-location-scale.R docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-tweedie-low-high-zero-comparator.md docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md docs/dev-log/after-task/2026-05-28-phase18-skew-normal-test-contract.md
```

The branch-level validation also reruns the focused Tweedie and skew-normal
boundary checks before publication.

```sh
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

The combined focused gate passed, full `devtools::test(reporter = "summary")`
passed, `pkgdown::check_pkgdown()` reported no problems, and `git diff --check`
was clean.

## Tests Of The Tests

No executable skew-normal tests were added in this design-only slice. The
tests-of-tests contract is explicit: the first implementation PR must add
density normalization, Gaussian normal-limit, sign-orientation,
false-positive, malformed-neighbour, extractor, and documentation checks before
`skew_normal()` is exposed.

## Consistency Audit

The note keeps one formula per distributional parameter and does not introduce
`skew ~ x`, `skew(id) ~ x`, `rho12`, bivariate skew-normal, composed families,
mixed responses, or random effects in `nu`. It also labels the example syntax
as planned, not runnable.

## GitHub Issue Maintenance

The issue audit found #3, "Add skew-normal location-scale-shape family", still
open. No new issue is needed for this design-only test contract.

## Known Limitations

The design contract is not fitted support. It does not add a constructor, TMB
branch, reference documentation, simulation, or examples. Those belong in a
future implementation PR after the tests are written.

## Next Actions

The next Team B slice should convert the contract into source-level density
tests and malformed-neighbour tests while still keeping the constructor hidden
until the density and normal-limit checks pass.
