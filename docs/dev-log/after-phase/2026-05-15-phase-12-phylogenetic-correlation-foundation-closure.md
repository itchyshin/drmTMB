# After Phase: Phase 12 Phylogenetic Correlation Foundation Closure

Date: 2026-05-15

## Goal

Close the local Phase 12 phylogenetic correlation foundation without claiming
that phylogenetic random slopes or all location-scale-shape extensions are
complete. The closed surface is the fitted and documented set of bivariate
phylogenetic covariance, direct-SD, `corpair()`, and q=4 reporting paths that
keep phylogenetic correlation separate from residual `rho12`.

## Implemented

- Matching intercept-only `phylo(1 | species, tree = tree)` or labelled
  `phylo(1 | p | species, tree = tree)` terms in bivariate `mu1` and `mu2` fit
  a phylogenetic location-location covariance block.
- `corpairs(fit, level = "phylogenetic")`, `summary(fit)$covariance`,
  `profile_targets()`, and `check_drm()` expose the fitted phylogenetic
  mean-mean row separately from residual `rho12`.
- Predictor-dependent q=2 phylogenetic `corpair(species, level =
  "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ w` is fitted for
  the location-location endpoint and uses `newdata` for row-specific
  correlation values.
- Bivariate `sd_phylo1(species) ~ z` and `sd_phylo2(species) ~ z` direct-SD
  models fit response-specific phylogenetic location SD surfaces.
- The first constant all-four q=4 phylogenetic location-scale block fits
  matching labelled `phylo()` terms across `mu1`, `mu2`, `sigma1`, and
  `sigma2` and reports all six latent phylogenetic `corpairs()` rows.

## Scope Boundary

This closure is not the full Phase 12 programme. Phylogenetic random slopes,
phylogenetic intercept-slope correlations, phylogenetic slope-slope
`corpair()` regression, predictor-dependent q=4 phylogenetic correlations,
phylogenetic effects in residual `rho12`, phylogenetic location-scale-shape
models, and longer optional simulations remain planned.

## Mathematical Contract

For the fitted bivariate phylogenetic mean-mean block:

```text
a_1, a_2 ~ MVN(0, Sigma_phylo)
Cov(a_1, a_2) = rho_phylo sd_phylo1 sd_phylo2 A
```

where `A` is the tree-derived phylogenetic covariance matrix. This correlation
is a species-level phylogenetic latent correlation. It is not the residual
within-observation correlation `rho12`.

The q=2 predictor-dependent phylogenetic `corpair()` path models the same
location-location correlation as a species-level function while preserving a
positive-definite two-field phylogenetic covariance. The q=4 block extends the
constant correlation matrix to `mu1`, `mu2`, `sigma1`, and `sigma2`, with
scale endpoints on the `log(sigma)` predictor.

## Standing Review Closure

- Ada: close the fitted phylogenetic correlation foundation and keep slopes as
  the next research gate.
- Boole: supported syntax stays intercept-only for fitted `phylo()` covariance
  blocks; slope syntax remains planned.
- Gauss: q=2 phylogenetic correlation targets are direct, while q=4
  correlations are derived rows without direct interval support.
- Noether: equations, R syntax, `corpairs()` rows, direct-SD surfaces,
  `profile_targets()`, and diagnostics keep phylogenetic and residual
  correlations separate.
- Darwin: applied users can distinguish evolutionary shared-history
  correlations from ordinary species or individual correlations and residual
  coupling.
- Fisher: recovery evidence is broad-trend and CRAN-safe; larger optional
  simulations remain necessary before teaching slopes.
- Pat: tutorials tell users to inspect `corpairs(level = "phylogenetic")`,
  `rho12()`, and `check_drm()` as separate outputs.
- Jason: spatial remains a sibling lane, not evidence for phylogenetic slopes.
- Curie: focused tests cover bivariate phylogenetic fitting, direct-SD
  surfaces, q=2 `corpair()` regression, q=4 rows, diagnostics, summaries, and
  profile targets.
- Emmy: the public extractor surface is stable enough for the closed
  foundation, while future slopes need a new coefficient-aware contract.
- Grace: local tests, pkgdown, and package check are the gate; GitHub Actions
  remains the PR-side gate.
- Rose: stale wording should not say that phylogenetic slopes, q=4
  predictor-dependent correlations, or structured `rho12` effects are
  implemented.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-12-phylogenetic-correlation-foundation-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/34-validation-debt-register.md docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-15-phase-12-phylogenetic-correlation-foundation-closure.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "phylo-gaussian|phylo-utils|corpairs|profile-targets|summary|check-drm", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for Phase 12 closure wording and stale overclaims
  about phylogenetic slopes, structured `rho12`, and q=4
  predictor-dependent phylogenetic correlations.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in
2m 17.7s.

## Tests Of The Tests

The focused gate exercises positive fitted paths and unsupported syntax. The
phylogenetic tests fit univariate and bivariate phylogenetic location effects,
bivariate direct-SD surfaces, q=2 phylogenetic `corpair()` regression, and the
constant q=4 phylogenetic location-scale block. The diagnostic, summary,
`corpairs()`, and profile-target tests verify that phylogenetic rows remain
separate from residual `rho12` and that q=4 interval status stays derived.

## Consistency Audit

The ROADMAP now records the local Phase 12 phylogenetic correlation foundation
closure while keeping phylogenetic slopes, structured `rho12`, and
predictor-dependent q=4 phylogenetic correlations planned. The validation-debt
register points to this report and keeps the row partial because the slope and
long-simulation debts remain. The stale-overclaim scan found no current source
or rendered claim that phylogenetic slopes, structured `rho12`, or
predictor-dependent q=4 phylogenetic correlations are implemented.

## What Did Not Go Smoothly

The main risk is that Phase 12 sounds like all phylogenetic location-scale work
is complete. The closure intentionally names only fitted correlation,
direct-SD, and reporting foundations, with random slopes still held back.

## Known Limitations

- Phylogenetic random slopes are not implemented.
- Phylogenetic effects in residual `rho12` are not implemented.
- Predictor-dependent q=4 phylogenetic correlations remain planned.
- q=4 phylogenetic correlation rows are point summaries with derived interval
  status, not direct profile intervals.
- Long optional simulations for larger trees, near-zero phylogenetic SD, high
  residual noise, and combined phylogenetic plus non-phylogenetic species
  effects remain planned.
- GitHub Actions remains the PR-side gate.

## Next Actions

1. Treat phylogenetic random slopes as a separate implementation slice with
   storage-order, recovery, and diagnostic evidence.
2. Keep non-phylogenetic species covariance and residual `rho12` separate from
   phylogenetic covariance in tutorials and diagnostics.
3. Add predictor-dependent q=4 phylogenetic correlations only after the derived
   interval policy is settled.
