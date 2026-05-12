# After Task: Univariate Mu/Sigma Covariance Bridge

## Goal

Implement the first univariate Gaussian labelled cross-formula covariance
slice: matching intercept-only `(1 | p | id)` terms in `mu` and `sigma` should
fit one group-level mean-scale correlation without changing the broader
double-hierarchical roadmap.

## Implemented

- `drmTMB()` now accepts matching labelled univariate Gaussian random
  intercepts in `mu` and `sigma`, for example:

```r
drmTMB(
  bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
  family = gaussian(),
  data = dat
)
```

- The fitted correlation appears in `corpars$mu_sigma` with the label
  `cor(mu:(Intercept),sigma:(Intercept) | p | id)`.
- `corpairs()` reports the same value as a group-level `mean-scale` row with
  `from_dpar = "mu"` and `to_dpar = "sigma"`.
- `profile_targets()` exposes the direct target
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`.
- The TMB template now has an `eta_cor_mu_sigma` parameter and explicit
  `sigma_re_cross_cor` / `sigma_re_cross_mu` data vectors, so only the matched
  labelled sigma latent rows condition on their corresponding mu latent rows.
- The manually built phylogenetic-prior TMB fixture now supplies dummy fields
  for the new TMB data and parameter names.

## Mathematical Contract

For group `j`, the implemented model slice is:

```text
mu_i = X_mu[i, ] beta_mu + b_j
log(sigma_i) = X_sigma[i, ] beta_sigma + a_j

[b_j, a_j]' =
  diag(sd_mu, sd_sigma) L(rho_mu_sigma) [u_j, v_j]'
[u_j, v_j]' ~ Normal([0, 0]', I)
```

The fitted `rho_mu_sigma` is a group-level mean-scale correlation. It is not
residual `rho12`, not a bivariate response-response correlation, and not a
general covariance matrix for slopes or structured effects.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-phylo-utils.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/04-random-effects.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md`
- `man/drmTMB.Rd`
- `man/corpairs.Rd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-univariate-mu-sigma-covariance-bridge.md`

## Checks Run

- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `air format R/drmTMB.R R/methods.R tests/testthat/test-gaussian-random-intercepts.R src/drmTMB.cpp NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/04-random-effects.md docs/design/17-correlated-random-effect-blocks.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd`:
  passed.
- `air format docs/design/01-formula-grammar.md vignettes/location-scale.Rmd`:
  passed after stale-wording cleanup.
- `air format tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 206 expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|corpairs|profile-targets')"`:
  passed with 427 expectations.
- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: passed with 45
  expectations after updating the hand-built TMB fixture.
- `Rscript -e "devtools::test()"`: first run failed in
  `test-phylo-utils.R` because the manual TMB data list did not include the new
  `n_mu_sigma_re_cors` field; after adding the dummy fields, the rerun passed
  with 1835 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "for (x in c('formula-grammar', 'location-scale')) pkgdown::build_article(x)"`:
  passed.

## Tests Of The Tests

The main positive test fits simulated data with known `sd_mu`, `sd_sigma`, and
`rho_mu_sigma`, then checks convergence, recovery within broad simulation
tolerances, `corpars$mu_sigma`, `corpairs()`, profile target naming, and
nonzero fitted sigma-link random-effect variation.

A second test fits the labelled `mu`/`sigma` block together with an independent
unlabelled `sigma` random intercept. It checks the internal
`sigma_cross_cor_id0`, `sigma_cross_mu_index0`, `sigma_re_cross_cor`, and
`sigma_re_cross_mu` mappings so the correlation is not applied to every sigma
random effect.

Negative tests still reject labelled `sigma` covariance without a matching
labelled `mu` intercept and reject matching `mu` random-slope blocks in this
phase.

## Consistency Audit

The status inventory was updated in `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, and
`vignettes/formula-grammar.Rmd`. Design notes now describe the implemented
intercept-only `mu`/`sigma` block while keeping random slopes, bivariate
`sigma1`/`sigma2` random effects, phylogenetic covariance, spatial covariance,
and general structured covariance as planned work.

The stale-wording scans were:

```sh
rg -n 'labelled `sigma` blocks|sigma random intercepts only|share covariance across `mu`, `sigma`|Matching labelled.*future|Cross-formula covariance blocks \| Planned' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes man
rg -n 'Labelled covariance blocks are not implemented|cross-formula covariance blocks \| Planned|cross-formula.*future work|same label.*future|mu/sigma.*planned|mean-scale.*planned|residual-scale random-effect covariance blocks\. Started|corpars\$mu_sigma|rho ~|meta_gaussian\(|tau ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man
```

The first search had no matches after cleanup. The second found only
intentional current-status strings and guardrail references for `rho ~`,
`meta_gaussian()`, `tau ~`, and `meta_known_V()`.

## What Did Not Go Smoothly

The first full test run exposed a real fixture drift: `test-phylo-utils.R`
manually builds a TMB data list for the phylogenetic prior branch, and that
list did not include the new dummy `mu`/`sigma` covariance fields. The package
model builders already supplied those fields; the manual fixture needed to
match the new TMB signature.

A stale tutorial sentence in `vignettes/location-scale.Rmd` still said labels
did not share covariance across `mu` and `sigma`. The final prose pass updated
that sentence to say only the matching intercept-only `mu`/`sigma` slice is
implemented.

## Team Learning

- Ada kept the slice small: one univariate intercept-only bridge, not the full
  double-hierarchical covariance endpoint.
- Noether kept residual `rho12` separate from group-level mean-scale
  covariance.
- Curie caught the need for a neighbouring-feature test with an extra
  independent `sigma` random intercept.
- Rose caught stale wording that would have made the docs contradict the new
  parser and likelihood path.
- Grace's full test run caught the hand-built TMB fixture drift.

## Known Limitations

- Only one labelled `mu`/`sigma` covariance block is implemented in this phase.
- The block is intercept-only. Random slopes, multiple labelled blocks, and
  labelled random-effect scale targets remain planned.
- Bivariate `sigma1`/`sigma2`, cross-response mean-scale, phylogenetic,
  spatial, and structured covariance blocks remain planned.
- No independent marginal-likelihood comparator was added for this slice; the
  evidence is simulation-style recovery, extractor/profile surface checks,
  malformed-input tests, and full package tests.

## Next Actions

1. Add a small independent likelihood or simulation-recovery comparator for the
   univariate `mu`/`sigma` covariance block if this slice becomes a release
   highlight.
2. Keep bivariate residual-scale covariance and phylogenetic covariance in
   separate branches so `rho12`, group-level mean-scale covariance, and
   structured covariance remain distinct.
3. Consider adding a `check_drm()` diagnostic row for fitted `mu`/`sigma`
   covariance blocks after the first extractor and profile surfaces have been
   reviewed.
