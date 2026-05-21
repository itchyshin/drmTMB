# After Task: `sd*()`/p8 Plan and Poisson Phylogenetic q=1 Gate

## Goal

Complete the next four post-map slices without drifting into a broad feature
claim: publish the map reconciliation, write the generic `sd*()` compatibility
plan, write the p8/q8 endpoint plan, and fit only the first ordinary Poisson
q=1 phylogenetic `mu` intercept.

## Implemented

Ordinary non-zero-inflated Poisson now accepts:

```r
bf(count ~ x + phylo(1 | species, tree = tree))
```

The structured effect enters the log-mean predictor as a q=1 phylogenetic
species intercept. Nearby richer requests are rejected: Poisson phylogenetic
slopes, labelled structured count blocks, zero-inflated Poisson phylogeny, and
ordinary plus phylogenetic count random effects in the same first gate.

The public maps now say exactly that. They no longer say all non-Gaussian
structured dependence is planned, but they also do not imply NB2, spatial,
animal, `relmat()`, zero-inflated, or structured-slope count parity.

## Mathematical Contract

The fitted slice is:

```text
count_i | a ~ Poisson(mu_i)
log(mu_i) = offset_i + X_i beta + a_species[i]
a ~ Normal(0, sd_phylo^2 A)
```

`A` is the tree-implied phylogenetic covariance. The TMB branch uses the sparse
precision `Q_phylo`, latent `u_phylo`, and direct SD target `log_sd_phylo`.
Because this is q=1, there is no latent correlation row for `corpairs()`.

## User Value

This helps users with count data and a clear phylogenetic mean-structure
question. It is most useful when the target is among-species phylogenetic
variation in expected counts, not residual overdispersion, extra zeros, spatial
dependence, individual animal relatedness, or count-side covariance among many
distributional parameters.

## Files Changed

- `R/drmTMB.R`, `R/methods.R`, `R/formula-markers.R`, `src/drmTMB.cpp`
- `tests/testthat/test-poisson-mean.R`,
  `tests/testthat/test-nongaussian-structured-boundary.R`
- `man/phylo.Rd`
- `README.md`, `NEWS.md`
- `vignettes/implementation-map.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/source-map.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/distribution-families.Rmd`
- `docs/design/01-formula-grammar.md`,
  `docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/59-structural-slope-and-non-gaussian-map.md`,
  `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/team-improvements.md`

## Checks Run

```sh
air format R/drmTMB.R R/methods.R R/formula-markers.R src/drmTMB.cpp tests/testthat/test-poisson-mean.R tests/testthat/test-nongaussian-structured-boundary.R
git diff --check
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'poisson-mean|nongaussian-structured-boundary|profile-targets|check-drm', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
```

Results: formatting and whitespace checks passed, roxygen regenerated
`man/phylo.Rd`, the focused test set passed, the full test suite passed, and
`pkgdown::check_pkgdown()` reported no problems.

## Consistency Audit

Ada kept the slice bounded and staged. Boole verified the formula boundary.
Gauss and Noether kept the likelihood wording aligned with the precision-prior
implementation. Darwin and Pat checked whether this route answers a real
applied count question. Fisher and Curie kept the status at smoke/ADEMP
planning rather than formal recovery evidence. Emmy checked extractor labels.
Grace tracked roxygen, pkgdown readiness, and PR #294 CI. Rose patched stale
"all non-Gaussian structured dependence is planned" claims in the current maps.

## Known Limitations

This slice does not implement NB2 phylogenetic effects, Poisson phylogenetic
slopes, labelled q=2/q=4 count blocks, spatial/animal/`relmat()` count effects,
zero-inflated structured effects, non-Gaussian scale random effects, public
bootstrap intervals, or p8/q8 covariance.

The `sd*()` work is still a plan. Existing `sd_phylo*()` helpers remain
compatibility paths until a deliberate lifecycle decision and parser tests land.

## Next Actions

1. Add a Poisson phylogenetic q=1 ADEMP sheet and tiny recovery grid before
   treating the route as more than smoke-level.
2. Decide whether the next count-structured slice is NB2 q=1 phylogeny or a
   documentation-only hold until Poisson recovery evidence is stronger.
3. Open generic `sd*()` parser work only after the compatibility and reference
   discoverability checklist is turned into tests.
