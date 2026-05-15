# Slice 56 derived-target status

Date: 2026-05-15

## Goal

Make the first nonlinear derived summaries visible as point estimates while
keeping their confidence-interval status honest.

## What changed

- Added `summary(fit)$derived` rows for simple univariate Gaussian
  random-intercept repeatability and phylogenetic signal when residual `sigma`
  is constant and no known sampling variance is present.
- Added matching `profile_targets()` rows with `target_class =
  "derived-summary"`, `target_type = "derived"`, `transformation =
  "variance_ratio"`, and `profile_note = "derived_target"`.
- Updated `confint(..., method = "profile")` so unavailable derived targets
  fail before starting an unsupported TMB profile.
- Added tests for ordinary repeatability, univariate phylogenetic signal, and
  the derived-target namespace.
- Updated `docs/design/12-profile-likelihood-cis.md`, `ROADMAP.md`, and
  `NEWS.md`.

## Standing-review notes

- Ada: this is a reporting/status slice. It does not implement nonlinear
  profile intervals.
- Fisher: repeatability and phylogenetic signal are useful point estimates, but
  their confidence intervals need a fix-and-refit or reparameterized profile
  method before we claim uncertainty.
- Boole: `derived:repeatability(group)` and
  `derived:phylogenetic_signal(species)` now give users stable names without
  implying they are direct TMB parameters.
- Noether: the variance-ratio formulas use SDs already reported by `sdpars`
  and the fitted residual `sigma`; known sampling variance is excluded from
  this first point-estimate path.
- Pat: the summary table now explains why a biologically familiar quantity can
  be printed but still lacks a 95% interval.
- Grace: focused `summary` and `profile-targets` tests are the required local
  gate before pkgdown and CI.
- Rose: q4 correlations, covariance products, multi-component ICCs, and
  double-hierarchical derived correlations remain status-only until a valid
  derived-interval method exists.

## Checks

Initial focused check:

- `Rscript -e 'devtools::test(filter = "summary|profile-targets", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::document()'`:
  passed and updated `man/summary.drmTMB.Rd` and
  `man/profile_targets.Rd`.
- `Rscript -e 'devtools::test(filter = "summary|profile-targets", reporter = "summary")'`:
  passed after documentation and formatting.
- `Rscript -e 'devtools::test(filter = "summary|profile-targets|phylo-gaussian|covariance-block-registry", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `air format` on changed R, test, doc, Rd, check-log, and after-task files:
  passed.
- `pkgdown::build_site()` and `pkgdown::check_pkgdown()`:
  passed.
- `git diff --check` and source/rendered wording scans:
  passed.

GitHub Actions remains the final merge gate.

## Known limitations

- This slice only adds simple univariate Gaussian variance-ratio point
  estimates.
- It does not add derived intervals, q4 correlation-function intervals,
  covariance-product intervals, conditional random-effect mode intervals,
  or derived summaries for models with known sampling variance or
  predictor-dependent residual scale.
