# Slice 55 random-effect SD and correlation intervals

Date: 2026-05-15

## Goal

Stabilize the direct profile-likelihood interval contract for currently fitted
ordinary, phylogenetic, and coordinate-spatial random-effect SD and correlation
targets.

## What changed

- Added focused tests for the coordinate-spatial SD target
  `sd:mu:spatial(1 | site)`.
- Added `corpairs(conf.int = TRUE)` coverage for constant ordinary and
  phylogenetic random-effect correlations.
- Extended bivariate phylogenetic summary coverage so
  `summary(conf.int = TRUE, method = "profile", ci_parm = ...)` attaches
  direct SD and correlation intervals to profile-ready rows while leaving the
  nonlinear covariance interval unavailable.
- Updated `docs/design/12-profile-likelihood-cis.md`, `ROADMAP.md`, and
  `NEWS.md` to record the Slice 55 boundary.

## Standing-review notes

- Ada: this slice closes evidence for the direct random-effect interval surface
  rather than adding new covariance parameterizations.
- Fisher: a tiny four-species phylogenetic example gave weak profile evidence,
  so the summary test now uses a stronger eight-species design for finite
  two-sided profile bounds.
- Boole: constant latent correlation rows and predictor-dependent
  `corpair(...) ~ x` rows remain semantically separate. The former can attach
  `corpairs()` intervals; the latter still require `newdata`.
- Noether: covariance intervals remain unavailable because covariance is a
  nonlinear product of SD and correlation targets, not a direct scalar TMB
  parameter in this path.
- Grace: focused tests must pass before this slice is merged; full pkgdown and
  CI remain the merge gate.
- Rose: q4 unstructured ordinary or phylogenetic rows remain
  `derived_interval_unavailable`; this slice should not overclaim them.

## Checks

Initial focused check:

- `Rscript -e 'devtools::test(filter = "spatial-gaussian|summary|profile-targets", reporter = "summary")'`:
  passed after strengthening the bivariate phylogenetic summary simulation.
- `Rscript -e 'devtools::test(filter = "profile-targets|summary|spatial-gaussian|phylo-gaussian|covariance-block-registry", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `pkgdown::build_site()` and `pkgdown::check_pkgdown()`:
  passed.
- `git diff --check`:
  passed.

## Known limitations

- This slice does not add profile intervals for q4 unstructured correlations,
  covariance products, ICCs, repeatability, phylogenetic signal, conditional
  random-effect modes, or modelled `corpair(...) ~ x` summary rows without
  `newdata`.
- Boundary and one-sided profile diagnostics remain a later Phase 6 slice.
