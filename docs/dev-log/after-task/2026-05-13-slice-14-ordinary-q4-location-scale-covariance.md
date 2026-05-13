# After Task: Slice 14 Ordinary q4 Location-Scale Covariance

## Goal

Fit the first production ordinary bivariate q=4 covariance block for the Family
A path without claiming phylogenetic, spatial, random-slope, or
predictor-dependent correlation support.

## Implemented

The same labelled random-intercept term can now appear in all four bivariate
Gaussian distributional formulas:

```r
bf(
  mu1 = y1 ~ x + (1 | p | id),
  mu2 = y2 ~ x + (1 | p | id),
  sigma1 = ~ z + (1 | p | id),
  sigma2 = ~ z + (1 | p | id),
  rho12 = ~ w
)
```

This routes to one ordinary q=4 latent covariance block. The block contributes
to `mu1`, `mu2`, `log(sigma1)`, and `log(sigma2)`, reports four SDs, and reports
six latent correlations through `corpars$re_cov`, `corpairs()`, and
`summary(fit)$covariance`. Residual `rho12` remains a separate within-row
correlation.

## Mathematical Contract

For group \(j\),

```text
u_j = [b_mu1_j, b_mu2_j, a_sigma1_j, a_sigma2_j]'
u_j ~ MVN(0, Sigma_id)
```

`b_mu*` enters the location linear predictor. `a_sigma*` enters the
log-residual-SD linear predictor. The six correlations in `Sigma_id` are latent
group-level correlations; they are not residual `rho12`.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|covariance-block-registry|summary|corpairs", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|covariance-block-registry|summary|corpairs|profile-targets|check-drm", reporter = "summary")'`:
  passed.

## Tests Of The Tests

The new bivariate Gaussian test fits a real q=4 TMB random-effect block, checks
that the old pairwise `u_mu` and `u_sigma` paths are not double-counting the
same label, verifies the q=4 registry dimensions, requires six fitted
`corpairs()` rows, confirms residual `rho12` is still separate, and checks that
fitted predictions include q4 random-effect contributions. The malformed-input
test keeps all-four random-slope syntax rejected while bivariate random-slope
scale terms remain planned.

## Consistency Audit

Synchronized `NEWS.md`, formula grammar, likelihood docs, the
double-hierarchical endpoint note, the labelled covariance assembler note, and
known limitations. A stale-wording scan for the old q4 rejection/planned phrases
returned no matches in those status docs.

## What Did Not Go Smoothly

The first malformed random-slope test expected the q4 detector's
intercept-only error, but the bivariate `sigma` random-slope guard correctly
rejects the model earlier. The test now checks the earlier user-facing error.

## Team Learning

This slice confirms that the hidden q4 registry and reporting scaffolds were
useful, but production q > 2 support still needs explicit pruning of the older
pairwise random-effect paths to avoid fitting the same labelled term twice.

## Known Limitations

This is only the ordinary grouped, intercept-only q=4 path. It does not add
random-slope endpoint blocks, direct q4 profile intervals, q4 `check_drm()`
diagnostics, phylogenetic q=4, spatial q=4, or predictor-dependent
`corpair(...) ~ w` models. The test checks broad behavior and convergence, not
precise recovery of all six correlations under weak-identification settings.

## Next Actions

Add a small parser slice for planned `corpair()` formula syntax with explicit
deferred errors, then decide whether the next implementation slice should
target q4 diagnostics or the univariate/phylogenetic Family B `sd_phylo()` path.
