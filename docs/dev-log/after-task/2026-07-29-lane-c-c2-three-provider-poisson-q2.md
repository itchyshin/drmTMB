# After Task: Lane C C2 three-provider Poisson q2

## 1. Goal

Move only `mc-0446`, `mc-0450`, and `mc-0454` from `not_implemented` to
technical `point_fit_recovery`.

## 2. Implemented

Ordinary Poisson now admits the exact labelled structured `mu`
intercept--slope q2 form for spatial coordinates, supplied relmat `Q`, and
animal `Ainv`, alongside the existing phylo form. Their direct SD/correlation
targets remain visible and are explicitly not profile-ready.

## 3a. Decisions and Rejected Alternatives

The approved exact provider forms were admitted. Mesh/range-estimating spatial
inputs, animal pedigree/A, relmat covariance/orientation variants, q4+, scale
side, zero inflation, ordinary-RE combinations, and all interval/coverage work
remain rejected or deferred. No remote compute was used.

## 3b. Mathematical Contract

For each provider, the latent field has covariance
`Sigma(tau0, tau1, rho) %x% Q^-1`, with
`rho = 0.999999 * tanh(eta_cor_phylo)`. Tests independently rebuild provider
precision, verify the determinant-normalized dense objective, central-FD/AD
gradient agreement, the `rho = 0` reduction, and correlation liveness.

## 4. Files Touched

The parser/status implementation, focused count tests, provider local-fixture
runner, retained receipts, three ledger cells, generated capability surface,
formula grammar, count map, README, vignette source, and known-limitations
boundary were synchronized.

## 5. Checks Run

- `testthat::test_file("tests/testthat/test-count-structured-mu.R")`: pass.
- `testthat::test_file("tests/testthat/test-profile-targets.R")`: pass.
- Three retained 3-seed local fixtures plus IID controls: pass.
- `python3 tools/capability_ledger.py --write --check`: pass.
- `tools/lane_preflight.sh`: rerun before the final claim.

## 6. Tests of the Tests

The q2 penalty is compared with an independent dense oracle at nonzero
correlation, so a parser-only or unmapped-correlation admission cannot pass.
Neighbour rejections cover non-q2 forms and NB2 provider boundaries.

## 7a. Issue Ledger

No existing issue required an update and no duplicate issue was opened; this
was the user-approved Lane C cohort execution.

## 8. Consistency Audit

The stale wording scan covered `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`,
`vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` with patterns
`labelled.*(count|poisson|nb2)|q2.*(count|poisson|nb2)|structured.*count` and
`C0-08|C0-09|C0-10|mc-0446|mc-0450|mc-0454`. The public grammar and vignette
source required narrow truth updates; ROADMAP/NEWS/navigation required none.

## 9. What Did Not Go Smoothly

The first new spatial fixture had a DGP-stage dimname bug. Its all-three-error
receipt is retained, then the runner was corrected and wrote a separate rerun
receipt. No model fit was overwritten or omitted.

## 10. Known Residuals

The all-attempt fixture is a local technical threshold, not an operating
characteristics study. The deliberate bound is recorded in the ledger and
receipts.

## 11. Team Learning

When an implementation activates a user-callable formula, point-fit-only status
and retained evidence are not enough: formula grammar and vignette source must
be made truthful in the same closeout.

## 12. Cross-Product Coverage

This covers ordinary univariate Poisson `mu` only, for one labelled q2
intercept--slope block using spatial coordinates, relmat `Q`, or animal `Ainv`.
It does NOT cover NB2 provider q2, any REML route, profile/interval dispatch,
bootstrap, calibration, coverage, missing responses, aggregation, Julia or
other engines, q4+, scale-side effects, zero inflation, ordinary-RE
combinations, multi-provider layouts, or alternative provider representations.

## Next Actions

The truthful backlog is now 35. The remaining rows require separate
architecture/estimand plans; do not infer a general count covariance grammar.
