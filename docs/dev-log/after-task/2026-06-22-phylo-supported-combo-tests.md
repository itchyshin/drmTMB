# After Task: Phylo Supported Combo Tests

## Goal

Bank S023 by adding focused test coverage for a currently supported
location/scale `phylo()` combination exposed by the S022 balance inventory.

## Implemented

Updated `tests/testthat/test-phylo-gaussian.R` with a dedicated native TMB ML
test for the univariate Gaussian `sigma`-only phylogenetic row:

```r
bf(
  y ~ x,
  sigma ~ phylo(1 | species, tree = tree)
)
```

The test checks convergence, the internal structured-effect dpar contract
(`sigma`), the `sdpars$sigma` name, absence of a latent correlation row,
conditional `sigma` prediction on the link scale, and the direct
`sd:sigma:phylo(1 | species)` profile target.

Updated the S022 `phylo-balance-inventory.tsv` row
`uni_sigma_phylo_native_ml` from partial/local-smoke status to covered focused
test status.

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
git diff --check
```

Result: focused `phylo-gaussian` tests passed. `git diff --check` was clean.

## Consistency Audit

This is a focused test slice. It does not change model behavior, formula
grammar, REML support, bridge support, q4 support, interval coverage,
non-Gaussian REML wording, HSquared AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S024 to keep unsupported neighbouring combinations as early informative
errors, especially native REML scale-side structured effects and unsupported
partial q4 blocks.
