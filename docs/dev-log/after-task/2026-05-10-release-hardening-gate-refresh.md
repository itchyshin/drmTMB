# After Task: Release-Hardening Gate Refresh

## Goal

Push `drmTMB` closer to a credible `0.1.0` preview by refreshing the public
release checklist, defining the Phase 9 preview boundary, and checking whether
implemented families have enough test evidence for first users.

## Implemented

The release checklist now records a concrete Phase 9 decision: `0.1.0` includes
the implemented location-only `cumulative_logit()` MVP and `beta_binomial()`
with `cbind(successes, failures)`. Ordinal scale or discrimination formulae,
denominator aliases, zero-one-inflated beta, and ordered beta remain
post-preview unless implemented with tests before the version bump.

The family coverage audit is archived in
`docs/dev-log/release-audits/2026-05-10-family-coverage.md`. It maps every
implemented preview family to simulation or recovery, independent likelihood,
comparator, boundary, malformed-input, and method coverage.

## Mathematical Contract

No likelihood or formula grammar changed. The task clarified release scope
only: public `sigma` remains the modelled scale parameter, `rho12` remains the
residual bivariate correlation parameter, and unsupported grammar such as
`rho ~`, `meta_gaussian()`, `tau ~` for meta-analysis, bivariate random effects,
ordinal scale formulae, and denominator aliases beyond
`cbind(successes, failures)` remains outside the `0.1.0` claim.

## Files Changed

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md`
- `docs/dev-log/release-audits/2026-05-10-family-coverage.md`
- `docs/dev-log/after-task/2026-05-10-release-hardening-gate-refresh.md`

## Checks Run

- `rg -n "test_that\\(" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R`
- `rg -n "likelihood matches independent|matches independent|comparator|recover|reject|unsupported|malformed|boundary|edge|complete-case|weights|simulation|simulate|finite|approaches|offset|zero" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R`
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: completed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O\\.Dea/Nakagawa|O\\.Dea-style|rho ~|meta_gaussian\\(|tau ~|family = c\\(gaussian\\(\\), poisson\\(\\)\\)" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/release-checklists docs/dev-log/release-audits vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`:
  found only guardrail prose, planned-feature prose, design checks, and one
  negative test.
- `rg -n 'Development status|development version|0\\.0\\.0\\.9000|0\\.1\\.0|pak::pak|development build; 0\\.1\\.0 preview planned|Phase 9|family coverage|cbind\\(successes, failures\\)' README.md ROADMAP.md docs/dev-log/release-checklists/2026-05-10-0.1.0-preview-release.md docs/dev-log/release-audits/2026-05-10-family-coverage.md pkgdown-site/index.html pkgdown-site/ROADMAP.html`:
  confirmed rendered status, install, roadmap, and release-boundary text.
- Chrome/Playwright layout sanity check over `pkgdown-site/index.html`: desktop
  `1280 x 900` and mobile `390 x 844` had no horizontal overflow.
- `git diff --check`: clean.

## Tests Of The Tests

The audit did not add new tests. Its evidence is the existing full suite plus a
source-level mapping of implemented families to test files. The strongest tests
are independent likelihood checks for non-Gaussian families, base R or package
comparators where overlap exists, simulation and boundary checks, and malformed
input tests that enforce the preview boundary.

## Consistency Audit

The release checklist, roadmap, known limitations, README, rendered pkgdown
landing page, and rendered roadmap now tell the same story: `0.0.0.9000` is the
current development version, `0.1.0` is the first preview target, and Phase 9 is
closed for preview at the implemented ordinal and beta-binomial MVPs.

## What Did Not Go Smoothly

The public GitHub issue had lagged behind the local release checklist, so the
first public tracking artifact did not include the latest comparator and
release-gate evidence. Rose's process fix is to sync public issues immediately
after local checklist edits. The issue has now been updated from the local
checklist and labelled `release`, `0.1.0`, `pkgdown`, and `CRAN-ish`.

## Team Learning

Ada should keep the release gate visible while choosing the next task. Grace
should require the local full-suite and package checks before a release-boundary
claim is treated as closed. Curie and Fisher should keep asking whether each
family has executable likelihood or simulation evidence, not only examples. Pat
and Rose should keep checking whether the public tracker and landing page answer
the first-user questions before new features are added.

## Known Limitations

This task does not implement new model classes. Full double-hierarchical
covariance, bivariate random-effect covariance blocks, ordinal scale or
discrimination formulae, denominator aliases, spatial effects, phylogenetic
scale effects, skew-normal, and skew-t remain post-preview work.

## Next Actions

1. Commit and push this release-hardening batch.
2. Monitor GitHub Actions for the pushed commit.
3. If CI stays green, move to final `0.1.0` hygiene: dated `NEWS.md`, version
   bump, final site inspection, and tag only after macOS, Ubuntu, and Windows
   pass.
