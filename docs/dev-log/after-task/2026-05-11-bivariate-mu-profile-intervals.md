# After Task: Bivariate Mu Profile Intervals

## Goal

Verify that the bivariate Gaussian `mu1`/`mu2` random-intercept covariance
targets exposed by `profile_targets()` can also be used directly with
`confint(method = "profile")`.

## Implemented

- Added a profile confidence-interval test for
  `sd:mu:mu1:(1 | p | id)`, `sd:mu:mu2:(1 | p | id)`, and
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`.
- Checked that the returned intervals are on the response scale, use
  `log_sd_mu` for both SD targets and `eta_cor_mu` for the correlation target,
  preserve the expected target indices, give positive SD bounds, and keep the
  correlation interval inside the correlation boundary.
- Checked that these group-level covariance targets remain separate from
  residual `rho12`.
- Updated `NEWS.md` and `docs/design/12-profile-likelihood-cis.md` so release
  notes and the profile-CI test checklist name the bivariate covariance
  profile interval route explicitly.

## Mathematical Contract

The bivariate covariance block estimates group-level random-intercept SDs for
`mu1` and `mu2` plus a group-level correlation. Profile intervals are fitted on
the internal `log_sd_mu` and `eta_cor_mu` scales, then transformed to response
SDs with `exp()` and to bounded correlations with the guarded TMB correlation
transform. These targets are group-level covariance parameters, not residual
within-observation `rho12`.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-bivariate-mu-profile-intervals.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R NEWS.md docs/design/12-profile-likelihood-cis.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 193
  expectations.
- `Rscript -e "devtools::test(filter = 'profile-targets|biv-gaussian')"`:
  passed with 316 expectations.
- `Rscript -e "devtools::test()"`: passed with 1789 expectations.
- `Rscript -e "devtools::document()"`: passed and left no generated
  documentation changes.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new test combines the existing bivariate covariance likelihood with the
profile-CI path and checks target ordering, internal TMB parameter mapping,
response-scale transformations, and the residual-`rho12` boundary. The first
draft used vector comparisons with `expect_gt()`, which failed because
testthat expects a single comparison there; the final test asserts the full
logical vectors explicitly.

## Consistency Audit

- `rg -n 'sd:mu:mu1:\(1 \| p \| id\)|cor:mu:cor\(mu1:\(Intercept\),mu2:\(Intercept\) \| p \| id\)|residual `rho12`|residual rho12' NEWS.md README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-profile-targets.R`:
  confirmed that the new target names and residual-`rho12` separation appear in
  the intended release, design, vignette, and test surfaces.
- `rg -n 'rho ~|meta_gaussian|tau ~|meta_known_V\([^V]|profile.*bivariate|bivariate.*profile|planned.*implemented|implemented.*planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml`:
  found only intentional guardrails, planned-feature wording, and the new
  bivariate profile coverage.

## What Did Not Go Smoothly

One exploratory stale-wording scan used double quotes around backticked
`rho12`, so `zsh` tried command substitution. The scan was rerun with single
quotes and the clean command is recorded above. I also tried `pkgdown --version`
out of habit; this project uses `pkgdown` through R, so
`Rscript -e "pkgdown::check_pkgdown()"` is the relevant check.

## Team Learning

Noether's perspective mattered here: target names, internal parameters, and
response-scale interpretation must line up exactly, because `rho12` and
group-level covariance correlations answer different scientific questions.

## Known Limitations

- This task verifies direct profile-interval plumbing for the bivariate
  group-level covariance targets. It is not a long-running simulation study of
  profile interval coverage.
- Derived double-hierarchical intervals for repeatability, total variance, and
  structured covariance-layer summaries remain planned.

## Next Actions

1. Add long optional coverage simulations for bivariate group-level covariance
   intervals before making strong coverage claims.
2. Keep the next issue #5 implementation slice focused on one covariance
   expansion at a time, with `corpairs()` output and simulation recovery before
   broadening the grammar.
