# After Task: Slice 184 Two-Block Validation

## Goal

Harden the two independent univariate `mu`/`sigma` covariance-block surface
with diagnostics and interval-target evidence.

## Implemented

`check_drm()` now reports one
`mu_sigma_random_effect_covariance` diagnostic row per independent matched
univariate `mu`/`sigma` block when a model contains multiple `eta_cor_mu_sigma`
targets. The profile tests now check that the second mean-scale correlation
target is a direct `eta_cor_mu_sigma` profile target and can be profiled on the
bounded response-correlation scale.

## Mathematical Contract

For independent blocks `p | id` and `q | site`, diagnostics and profile targets
should remain block-specific:

```text
cor(b_id, a_id)       -> eta_cor_mu_sigma[1]
cor(b_site, a_site)   -> eta_cor_mu_sigma[2]
```

The two rows are not a single larger covariance block, and residual `rho12`
remains separate.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `man/check_drm.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-184-two-block-validation.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm|profile-targets", reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new `check_drm()` test fits two matched blocks and verifies two diagnostic
rows with separate `id` and `site` group counts. The new profile test fits the
same two-block surface and profiles the second `cor:mu_sigma` target, checking
that it uses `eta_cor_mu_sigma` index 2 and returns finite bounded confidence
limits.

## Consistency Audit

The roadmap and NEWS now distinguish Slice 183 structural support from Slice
184 diagnostics and interval-target evidence. `check_drm()` documentation now
describes one or more univariate `mu`/`sigma` blocks rather than a single
matched block.

## What Did Not Go Smoothly

The old diagnostic path treated multiple registry mean-scale pairs as complex
and returned a single note. The fix was to route multiple direct q=2
`mu`/`sigma` blocks through the existing non-registry cross-correlation index,
which already records the intended block-specific `eta_cor_mu_sigma` IDs.

## Team Learning

Ada split structural fitting from validation rather than bundling it into one
large PR. Gauss and Noether checked that profile index order matches the TMB
parameter vector. Fisher and Curie required an interval check for the second
correlation, not only target listing. Grace kept roxygen and pkgdown in the
loop because `check_drm()` user-facing documentation changed. Rose recorded
the distinction between independent blocks and future larger covariance
surfaces.

## Known Limitations

This slice does not add slope-level mean-scale covariance, correlated
residual-scale slopes, bivariate random slopes, or q > 2 direct correlation
intervals.

## Next Actions

Slice 185 should define the first bivariate random-slope policy without
opening q=8 endpoint covariance blocks prematurely.
