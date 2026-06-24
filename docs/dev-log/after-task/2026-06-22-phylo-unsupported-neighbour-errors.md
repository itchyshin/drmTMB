# After Task: Phylo Unsupported Neighbour Errors

## Goal

Bank S024 by pinning an unsupported neighbouring `phylo()` cell with an early,
informative native REML error.

## Implemented

Updated `tests/testthat/test-reml-phylo-location.R` so native TMB REML rejects
the univariate Gaussian `sigma`-only phylogenetic row:

```r
bf(
  y ~ x,
  sigma ~ phylo(1 | species, tree = tree)
)
```

The existing matched `mu + sigma` REML rejection remains in the same test. The
balance inventory now includes `uni_sigma_phylo_native_reml` as an explicit
unsupported neighbour, while `uni_sigma_phylo_native_ml` remains covered for ML.

## Checks Run

```sh
Rscript -e 'devtools::test(filter = "reml-phylo-location", reporter = "summary")'
git diff --check
```

Result: focused `reml-phylo-location` tests passed. `git diff --check` was
clean.

## Consistency Audit

This is a guard/test slice. It does not change ML support, REML support, bridge
support, q4 support, interval coverage, non-Gaussian REML wording, HSquared
AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S025 to expand scale-side phylo clamp/identifiability diagnostics without
turning them into interval-coverage or broad support claims.
