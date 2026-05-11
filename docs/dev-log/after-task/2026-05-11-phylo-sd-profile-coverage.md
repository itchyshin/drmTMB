# After Task: Phylogenetic SD Profile Coverage

## Goal

Add focused coverage for profile-likelihood intervals on the implemented
univariate Gaussian phylogenetic `mu` standard deviation.

## Implemented

- Added a deterministic profile-target test fixture with a small balanced
  ultrametric tree.
- Added a public `confint()` profile test for
  `sd:mu:phylo(1 | species)`.
- The test compares `confint.drmTMB()` with a manual `TMB::tmbprofile()` call
  for `log_sd_phylo`.
- `NEWS.md`, `ROADMAP.md`, and `docs/design/12-profile-likelihood-cis.md` now
  include phylogenetic `mu` SD as an explicitly covered direct profile target.

## Mathematical Contract

The fitted phylogenetic SD target maps to the direct TMB parameter
`log_sd_phylo`. If the profile interval on the internal scale is `[L, U]`,
`confint.drmTMB()` reports `[exp(L), exp(U)]` on the SD scale. This is an
interval for the magnitude of the phylogenetic `mu` random effect, not an
interval for phylogenetic correlation between two responses.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-phylo-sd-profile-coverage.md`

## Checks Run

- exploratory R snippets over seeds `20260601` to `20260610`
- `air format tests/testthat/test-profile-targets.R`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::test()"`

The focused profile-target suite passed with 106 expectations, no failures, no
warnings, and no skips. The full package test suite passed with 1586
expectations, no failures, no warnings, and no skips.

## Tests Of The Tests

The test independently constructs the one-hot linear combination for
`log_sd_phylo[1]`, profiles it with `TMB::tmbprofile()`, and checks that
`confint.drmTMB()` returns the same interval after the `exp()` transformation.
The seed sweep was used to avoid a weak fixture with profile warnings.

## Consistency Audit

- The docs now claim phylogenetic `mu` SD profile support only after this
  focused test was added.
- The docs do not claim bivariate phylogenetic correlation, non-phylogenetic
  species correlation, or phylogenetic location-scale covariance support.
- The target remains a direct SD target, not a derived phylogenetic-signal
  interval.

## What Did Not Go Smoothly

The first tiny exploratory phylogenetic fixture produced a profile warning
because the fitted phylogenetic SD was too close to the lower boundary. The
test now uses a stronger 16-tip, six-observation-per-tip fixture with seed
`20260603`, which profiled cleanly in the seed sweep.

## Team Learning

Fisher's lesson is that profile tests need enough curvature around variance
components. Darwin and Rose's lesson is to keep phylogenetic SD, phylogenetic
correlation, and residual `rho12` separate in both code and prose.

## Known Limitations

- No phylogenetic correlation between two responses is implemented.
- No non-phylogenetic species covariance layer is implemented.
- No phylogenetic signal or repeatability profile interval is implemented.

## Next Actions

1. Add response-scale residual `rho12` contrast design before exposing
   row-level residual-correlation intervals.
2. Keep bivariate phylogenetic and non-phylogenetic species covariance on the
   Phase 12/13 roadmap until likelihoods and simulation recovery exist.
