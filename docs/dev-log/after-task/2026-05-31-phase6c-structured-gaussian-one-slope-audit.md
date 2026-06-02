# After Task: Phase 6c Structured Gaussian One-Slope Audit

## Goal

Close #442 by checking the fitted Gaussian structured one-slope `mu` routes
against tests, extractors, diagnostics, roadmap rows, and planned-neighbour
boundaries before Phase 18 power simulations use these cells.

## Implemented

This was a status and evidence audit only. It did not change parser,
likelihood, TMB, extractor, simulation-runner, formula-grammar, or missing-data
code.

The implemented claim is narrow: `phylo()`, coordinate `spatial()`,
`animal()`, and `relmat()` each fit one numeric univariate Gaussian `mu` slope
as independent structured intercept and slope fields. The audit does not claim
multiple structured slopes, structured slope correlations, residual-scale
structured slopes, structured `rho12`, non-Gaussian structured slopes, or broad
q2/q4 recovery and coverage evidence.

## Mathematical Contract

For observation `i` in structured level `j`, the audited one-slope route is:

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta_0 + beta_1 x_ij + a_0j + x_ij a_1j
a_0 ~ MVN(0, sd_intercept^2 C)
a_1 ~ MVN(0, sd_slope^2 C)
Cov(a_0, a_1) = 0
```

The matching syntax is one of:

```r
bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1)
bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)
bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1)
bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)
```

The slope-field SD is a direct structured-SD target. An intercept-slope
correlation is not fitted for these structured one-slope routes.

## Files Changed

- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `ROADMAP.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-structured-gaussian-one-slope-audit.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format ROADMAP.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/dev-log/after-task/2026-05-31-phase6c-structured-gaussian-one-slope-audit.md docs/dev-log/check-log.md
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian|spatial-gaussian|animal-relmat-gaussian|profile-targets|check-drm', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n 'Structured Gaussian Audit Closure|one numeric univariate Gaussian `mu` slope|derived-unavailable|structured_effects\\(\\)|#335|#446|#442 audit ledger' ROADMAP.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/dev-log/after-task/2026-05-31-phase6c-structured-gaussian-one-slope-audit.md pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'phylogeny has intercept-level effects but no fitted slope|one-slope.*planned.*phylo|spatial_mu_slope.*only|only.*spatial_mu_slope|structured slope correlations (are )?(fitted|implemented)|residual-scale structured slopes (are )?(fitted|implemented)|structured `rho12` (is |are )?(fitted|implemented)|non-Gaussian structured slopes (are )?(fitted|implemented)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

No tests were added. The audit reuses existing focused evidence:

- `tests/testthat/test-phylo-gaussian.R` covers the fitted phylogenetic
  one-slope route, `ranef()`, `profile_targets()`, and `check_drm()`.
- `tests/testthat/test-spatial-gaussian.R` covers the fitted coordinate-spatial
  one-slope route, q2/q4 extractor rows, planned-neighbour boundaries, and
  diagnostics.
- `tests/testthat/test-animal-relmat-gaussian.R` covers `animal()` and
  `relmat()` one-slope routes, q2/q4 relatedness rows, `corpairs()`,
  `profile_targets()`, and `check_drm()`.
- `tests/testthat/test-profile-targets.R` and
  `tests/testthat/test-check-drm.R` cover the shared interval-target and
  diagnostic surfaces used by the audit.

## Consistency Audit

The audit checked the current status inventory rather than only the new note:
`README.md`, `ROADMAP.md`, `docs/design`, `docs/dev-log/known-limitations.md`,
`vignettes`, and the rendered `pkgdown-site`. The stale-wording scan looked
for old no-slope wording, claims that only `spatial_mu_slope` exists, and
claims that structured slope correlations, residual-scale structured slopes,
structured `rho12`, or non-Gaussian structured slopes are fitted.

## GitHub Issue Maintenance

#442 owns this audit and can close after this PR lands. #335 is already closed
by `structured_effects()`, so no new metadata/extractor issue is needed. Phase
18 wrapper, artifact-routing, recovery, coverage, and power planning remain in
#446 or future focused issues.

## What Did Not Go Smoothly

The broad draft branch had already explored wrapper and artifact-routing work.
This closeout deliberately extracted only the audit claim that can be proven on
current `main`, leaving broader simulation wiring outside this PR.

## Team Learning

Rose's useful distinction here is between a fitted model surface and an
artifact route. A fitted one-slope path can be ready for small smoke cells while
still lacking recovery, coverage, and power evidence for formal Phase 18
promotion.

## Known Limitations

The audited one-slope routes fit independent structured intercept and slope
fields. They do not fit structured intercept-slope correlations, multiple
structured slopes, residual-scale structured slopes, random effects in
`rho12`, non-Gaussian structured slopes, or broad q2/q4 coverage grids.

## Next Actions

- Close #440 next if the bivariate Gaussian slope-only evidence gate is still
  the smallest open capability issue.
- Use #446 for the random-slope simulation power, accuracy, and coverage plan.
- Leave missing-data design and implementation to the separate missing-data
  thread.
