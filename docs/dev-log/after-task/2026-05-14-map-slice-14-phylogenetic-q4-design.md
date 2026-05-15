# After Task: 35-Map Slice 14 Phylogenetic q4 Design

## Goal

Close the design contract for the constant bivariate phylogenetic q=4 Family A
block before changing the fitted TMB likelihood.

## Implemented

The phylogenetic/spatial common math note now defines the q=4 matrix-normal
contract for `mu1`, `mu2`, `sigma1`, and `sigma2`: endpoint-major `u_phylo`,
four endpoint SDs, six positive-definite endpoint correlations, and the sparse
augmented tree precision. The formula grammar now records labelled
`phylo(1 | p | species, tree = tree)` as planned q4 syntax, and the common math
note explicitly says the current 35-slice route implements phylogenetic q4
before spatial while keeping spatial as a sibling lane.

## Mathematical Contract

For `U = [a_mu1, a_mu2, a_sigma1, a_sigma2]`, with rows over augmented tree
nodes and columns over distributional endpoints:

```text
U ~ MatrixNormal(0, Q_aug^{-1}, Sigma_phylo)
nll = 0.5 * [
  n_node * q * log(2*pi)
  + n_node * log|Sigma_phylo|
  - q * log|Q_aug|
  + tr(Sigma_phylo^{-1} U' Q_aug U)
]
```

Residual `rho12` remains a within-observation correlation and is not part of
`Sigma_phylo`.

## Files Changed

- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/01-formula-grammar.md`
- `tests/testthat/test-phylo-utils.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-map-slice-14-phylogenetic-q4-design.md`

## Checks Run

- `air format docs/design/16-phylo-spatial-common-math.md docs/design/01-formula-grammar.md`:
  passed.
- `air format tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils|phylo-gaussian|package-skeleton", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The first test run failed because the phylogenetic TMB probe helper was stale:
it did not pass the ordinary q>2 covariance parameters now declared by the TMB
template. Curie repaired the helper by adding dummy `u_re_cov`,
`log_sd_re_cov`, and `theta_re_cov` parameters, then reran the targeted tests
successfully. This keeps the dense-vs-sparse phylogenetic algebra checks usable
for Slice 15.

## Consistency Audit

The synchronized status scans were:

```sh
rg -n 'phylo\(1 \| p \| species|35-slice route|family = c\(gaussian\(\), gaussian\(\)\)|spatial.*precedes|constant bivariate phylogenetic q=4' docs/design/16-phylo-spatial-common-math.md docs/design/01-formula-grammar.md
rg -n 'phylogenetic q=4.*Implemented|phylo\(1 \| p \| species.*Implemented|six `corpairs\(level = "phylogenetic"\)` rows.*Implemented|sd_phylo\(species\).*Implemented' README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The first scan confirmed the new design and grammar text. The second scan
returned no matches, confirming the repository does not claim fitted
phylogenetic q4 support yet.

## What Did Not Go Smoothly

Rose found that the first draft introduced labelled phylogenetic syntax without
updating formula grammar, contradicted an older spatial-before-sigma ordering,
and used the older `biv_gaussian()` helper in a future-facing example. Grace
then found the stale phylogenetic TMB probe helper during targeted tests.

## Team Learning

- Ada: keep the 35-slice map number explicit in every closeout until branch
  numbering and map numbering stop diverging.
- Boole: any new formula shape, even design-only, must be mirrored in
  `docs/design/01-formula-grammar.md`.
- Gauss: keep the q=4 TMB work on endpoint-major storage because it matches the
  existing bivariate phylogenetic layout and q-probe algebra.
- Noether: require the matrix-normal expression, R helper, and C++ probe to
  agree before fitting new latent effects.
- Curie: include probe-helper maintenance in algebra-test slices because TMB
  parameter declarations can drift ahead of old tests.
- Fisher: treat phylogenetic scale effects as weak-identification risks until
  species replication, tiny SD, and boundary-correlation diagnostics pass.
- Pat and Darwin: do not show a runnable q4 phylogenetic tutorial until the
  fitted likelihood, recovery, and six reporting rows exist.
- Grace: run `pkgdown::check_pkgdown()` for design slices that affect public
  status, even when no article source changes.
- Rose: audit old sequencing lists, not only the new section being edited.

## Known Limitations

This slice does not fit phylogenetic `sigma1` or `sigma2` terms, does not emit
six q=4 phylogenetic `corpairs()` rows, and does not add a q=4 user-facing
example.

## Next Actions

Slice 15 should add the TMB parameterization scaffold: endpoint-major
`u_phylo` length `4 * n_node`, four `log_sd_phylo` entries, and six q=4
correlation parameters using the existing unstructured-correlation machinery.
