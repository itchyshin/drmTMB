# After Task: Bivariate Phylogenetic Covariance Integration

## Goal

Close the partial bivariate phylogenetic covariance lane by treating matching
intercept-only `phylo()` terms in `mu1` and `mu2` as a tested and documented
feature, not as planned plumbing.

## Implemented

The bivariate Gaussian path now has a complete first phylogenetic mean-mean
covariance slice. A model with matching terms such as
`mu1 = y1 ~ x + phylo(1 | species, tree = tree)` and
`mu2 = y2 ~ x + phylo(1 | species, tree = tree)` estimates two phylogenetic
location SDs and one phylogenetic mean-mean correlation. The fitted SDs are
reported in `sdpars$mu` as `mu1:phylo(1 | species)` and
`mu2:phylo(1 | species)`. The fitted correlation is reported in
`corpars$phylo`, appears in `corpairs(level = "phylogenetic")`, and stays
separate from residual `rho12`.

`profile_targets()` now maps bivariate phylogenetic SD targets to
`log_sd_phylo` and the phylogenetic correlation target to
`eta_cor_phylo_mu`, so those direct targets are marked ready rather than
`missing_tmb_parameter`.

The phylogenetic/spatial design note also records the late external numerical
scout from this phase: exact sparse tree precision remains the right first
path for this bivariate phylogenetic block, while SPDE/GMRF and Vecchia-style
methods stay on the future spatial roadmap.

## Mathematical Contract

The implemented bivariate phylogenetic mean block is

```text
mu1_i = X_mu1[i, ] beta_mu1 + a_1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_2[species_i]
[a_1, a_2] ~ MVN(0, A %x% Sigma_phylo)
```

`Sigma_phylo` has two positive SDs and one bounded correlation:

```text
sd_phylo1 = exp(log_sd_phylo[1])
sd_phylo2 = exp(log_sd_phylo[2])
rho_phylo = 0.999999 * tanh(eta_cor_phylo_mu)
```

The observation-level residual correlation remains
`rho12 = 0.99999999 * tanh(eta_rho12)`.

## Files Changed

- `R/profile.R`
- `R/methods.R`
- `tests/testthat/test-phylo-gaussian.R`
- `man/corpairs.Rd`
- `man/predict.drmTMB.Rd`
- README, NEWS, roadmap, formula grammar, likelihood design, random-effect
  design, profile-target design, phylogenetic/spatial design, correlation-pair
  design, mammal route, known limitations, bivariate tutorial, phylogenetic
  tutorial, source map, and check log

## Checks Run

- `air format R/profile.R R/methods.R tests/testthat/test-phylo-gaussian.R`
- `Rscript -e "devtools::test(filter = 'phylo|profile-targets')"`:
  295 passed.
- `Rscript -e "devtools::test(filter = 'phylo|profile-targets|biv-gaussian|corpairs')"`:
  518 passed after the resumed prediction-path assertion was added.
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: completed
  successfully.
- `git diff --check`
- `Rscript -e "devtools::test()"`: 1968 passed after the resumed prediction
  assertion.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  0 errors, 0 warnings, 0 notes.
- stale-wording scan for claims that bivariate phylogenetic covariance remains
  planned.

## Tests Of The Tests

The new bivariate phylogenetic Gaussian test simulates data from known
phylogenetic SDs and a known phylogenetic mean-mean correlation using a
hand-built ultrametric tree. It fits the intended bivariate model, checks
convergence, fixed effects, phylogenetic SDs, `corpars$phylo`, residual
`rho12`, `corpairs()`, profile-target readiness, and compares the fitted
objective to a dense marginal-likelihood calculation on the same tree-implied
covariance. The resumed test also checks that fitted-row predictions for
`mu1` and `mu2` include the matching phylogenetic effects, while `newdata`
predictions remain fixed-effect population-level predictions.

## Consistency Audit

The source docs and generated help now describe bivariate phylogenetic
`mu1`/`mu2` covariance as implemented only for matching intercept-only
`phylo()` terms. Remaining planned wording is reserved for phylogenetic slopes,
phylogenetic scale effects, structured `rho12`, spatial effects, bivariate
random slopes, lifestyle-specific phylogenetic covariance matrices, and dense
`meta_known_V(V = V)` combinations. The late external numerical scout is
captured in `docs/design/16-phylo-spatial-common-math.md` rather than expanding
this fitted slice into spatial or high-dimensional multivariate machinery.

## What Did Not Go Smoothly

The first live fit showed that the likelihood and extractors were already
mostly wired, but `profile_targets()` exposed the closure bug: bivariate
phylogenetic SD and correlation rows were present but not profile-ready because
they mapped to the wrong internal TMB parameter names. A tiny deterministic
dense-comparator fixture also hit an optimizer limit, so the comparator check
was folded into the larger seeded simulation that converges reliably.

## Team Learning

- Ada should treat profile-target readiness as part of feature closure, not as
  later polish.
- Gauss should keep the first bivariate phylogenetic block narrow:
  intercept-only location effects, two SDs, one bounded correlation.
- Noether should keep `rho12` out of the phylogenetic covariance equation.
- Curie should prefer CRAN-safe seeded simulations with dense comparators over
  tiny fixtures that are too easy to push to a boundary.
- Rose should continue stale-wording scans whenever a feature moves from
  roadmap prose to fitted code.

## Known Limitations

- Bivariate phylogenetic covariance is implemented only for matching
  intercept-only `mu1`/`mu2` terms using the same tree object and grouping
  variable.
- Phylogenetic slopes, phylogenetic `sigma1`/`sigma2` effects, structured
  `rho12`, spatial effects, and lifestyle-specific phylogenetic covariance
  matrices remain planned.
- Bivariate random effects still cannot be combined with dense
  `meta_known_V(V = V)`.

## Next Actions

1. Add `check_drm()` diagnostics for bivariate phylogenetic replication and
   near-boundary phylogenetic SDs if examples show weak identification.
2. Decide whether non-phylogenetic species covariance should share the current
   ordinary labelled block path or get a reader-facing species-level example.
3. Keep phylogenetic scale effects out of the fitted surface until the
   location block has longer simulation evidence.
