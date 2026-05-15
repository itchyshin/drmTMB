# After Task: Slices 28-30 q2 phylogenetic corpair implementation

## Goal

Fit the first predictor-dependent phylogenetic latent correlation model while
keeping residual `rho12`, constant q=4 phylogenetic covariance, direct
`sd_phylo*()` models, and spatial planning in separate model families.

## Implemented

- Added fitted q=2 syntax:
  `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ w`.
- Required matching labelled `phylo(1 | p | species, tree = tree)` terms in
  bivariate `mu1` and `mu2`.
- Rejected q=4 endpoint pairs, direct-SD mixtures, mismatched groups or blocks,
  and spatial `corpair()` regression before optimization.
- Routed phylogenetic `corpair()` coefficients through `beta_cor_mu` and exposed
  them through `coef()`, `summary()`, `vcov()`, and `profile_targets()`.
- Updated `corpairs(level = "phylogenetic")` so modelled q=2 rows report the
  response-scale mean, minimum, maximum, number of species-level values, and
  `newdata_required` interval status.
- Updated `NEWS.md`, `ROADMAP.md`, formula grammar docs, likelihood docs, common
  phylo/spatial math docs, known limitations, `corpairs`/`corpair` docs, and the
  structured-dependence article.

## Mathematical Contract

The fitted route is q=2 and location-location only. Let `z1` and `z2` be two
independent unit phylogenetic fields over the augmented tree precision. For an
observed species `l`,

```text
rho_l = tanh_guard(W_l alpha)
c_l = sqrt((1 + rho_l) / 2)
d_l = sqrt((1 - rho_l) / 2)
a1_l = tau1 (c_l z1_l + d_l z2_l)
a2_l = tau2 (c_l z1_l - d_l z2_l)
```

This keeps the full tree-coupled covariance positive definite and reduces to the
existing constant bivariate phylogenetic covariance when the correlation
predictor is constant. It is not residual `rho12` regression, and it is not the
q=4 location-scale/scale-scale contract.

## Files Changed

- `R/drmTMB.R`, `R/methods.R`, `R/profile.R`, `R/formula-markers.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-phylo-gaussian.R`,
  `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-profile-targets.R`
- `NEWS.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/16-phylo-spatial-common-math.md`,
  `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/known-limitations.md`
- `vignettes/phylogenetic-spatial.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/bivariate-coscale.Rmd`
- `man/corpair.Rd`

## Checks Run

- `air format` on touched R, C++, test, vignette, and design files: passed.
- `devtools::document()`: passed.
- `devtools::test(filter = "phylo-gaussian", reporter = "summary")`: passed.
- `devtools::test(filter = "phylo-gaussian|biv-gaussian|profile-targets", reporter = "summary")`:
  passed.
- `devtools::test(reporter = "summary")`: passed.
- `pkgdown::build_site()`: passed and refreshed local pkgdown pages.
- `pkgdown::check_pkgdown()`: passed.
- Stale wording scan for old planned/not-fitted phylogenetic `corpair()` text:
  passed with only intentional q=4/spatial planned-boundary hits.
- `git diff --check`: passed before this report and will be rerun before commit.

## Tests Of The Tests

The new CRAN-safe q=2 phylogenetic `corpair()` test verifies convergence, finite
objective value, fitted coefficient exposure, TMB parameter mapping, `corpairs()`
modelled-row reporting, response/link transform consistency, `newdata_required`
interval status, and profile-target exposure for the predictor slope. It is
deliberately a smoke test. It does not claim recovery of `alpha_cor`; a small
eight-species article-scale design is too weak and can push fitted correlations
toward the guard.

The existing ordinary q=2 `corpair()` tests still cover group-level malformed
input and modelled reporting. The updated bivariate Gaussian malformed-input
test now confirms that phylogenetic `corpair()` without matching labelled
`phylo()` terms errors with the new implementation-specific message.

## Consistency Audit

The implemented-versus-planned boundary is now consistent across the main
reader-facing files:

- q=2 ordinary and phylogenetic `mu1`-`mu2` `corpair()` regression is fitted;
- q=4 ordinary and phylogenetic location-scale/scale-scale correlation
  regression is planned;
- spatial random effects and spatial `corpair()` regression are planned;
- `rho12` remains residual-only;
- `corpairs()` is the extractor, while singular `corpair()` is formula syntax.

The local pkgdown site was rebuilt so the open article no longer shows the old
"planned but not fitted" text for q=2 phylogenetic `corpair()`.

## What Did Not Go Smoothly

Curie found that the first tiny simulation can fit extreme q=2 phylogenetic
correlation-regression coefficients even though the plumbing is correct. I kept
the CRAN test as a convergence/reporting smoke test instead of pretending it is
recovery evidence. The recovery slice should use larger simulations, stronger
replication, multiple seeds, and sign/rank checks outside the fastest package
test path.

Rose found stale wording in the structured-dependence article, formula grammar
vignette, roxygen example, known limitations, and generated pkgdown pages. Those
were corrected before commit.

## Team Learning

- Ada: keep slice boundaries explicit; this closeout covers Slices 28-30 but
  does not spend Slice 31's recovery budget.
- Boole: endpoint-specific `from`/`to` syntax remains clearer than
  class-wide `location-scale` fitting for q=4.
- Gauss: the two-field loading contract keeps the likelihood positive
  definite, but recovery evidence needs larger simulations.
- Noether: equations and R syntax must keep `rho12`, q=2 phylogenetic
  `corpair()`, and q=4 `corpairs()` rows in separate layers.
- Curie: smoke tests should say smoke tests; do not let a saturated small
  simulation masquerade as recovery.
- Fisher: interval claims should stay at direct fixed-effect/profile targets
  and `newdata` rows; q=4 derived rows still need a later profile strategy.
- Darwin: the life-history trade-off example should emphasize `mu1`-`mu2` as
  the first biologically natural phylogenetic correlation-regression row.
- Pat: the article needs runnable syntax for fitted paths and labelled
  "planned q=4" blocks for non-runnable future paths.
- Grace: rebuild pkgdown after source-doc changes because the user is reading
  local generated HTML in the app browser.
- Rose: stale-status scans need both source docs and `pkgdown-site`, not one or
  the other.

## Known Limitations

- Only q=2 phylogenetic `mu1`-`mu2` predictor-dependent `corpair()` regression
  is fitted.
- q=4 phylogenetic `mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`,
  `mu2`-`sigma2`, and `sigma1`-`sigma2` correlation regression remains planned.
- Spatial random effects and spatial `corpair()` regression remain planned.
- Direct-SD `sd_phylo1()` / `sd_phylo2()` mixtures with phylogenetic
  `corpair()` regression are intentionally rejected in this phase.
- Random slopes remain post-Slice-40 planning work.

## Next Actions

1. Run Slice 31 as recovery/diagnostic evidence for q=2 phylogenetic
   `corpair()` regression.
2. Decide whether spatial implementation starts from an internal covariance
   prototype, an SPDE/GMRF mesh route, or an sdmTMB/fmesher-inspired contract
   with explicit provenance and citation notes.
3. Keep the random-slope covariance roadmap after Slice 40, starting with one
   structured slope before considering two or more slopes.
