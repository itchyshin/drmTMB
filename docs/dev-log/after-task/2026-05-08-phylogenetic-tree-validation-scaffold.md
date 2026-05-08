# After Task: Phylogenetic Tree Validation Scaffold

## Goal

Create the first internal phylogenetic utility layer before fitting
`phylo()` model terms: validate branch-length trees and build a tiny dense
Brownian comparator for later sparse A-inverse tests.

## Implemented

- Added `validate_phylo_tree()` for internal `phylo` object validation.
- Added `validate_phylo_species()` for observed species-to-tip matching.
- Added `drm_phylo_tip_covariance()` as a dense Brownian covariance or
  correlation comparator for tiny trees.
- Added tests for valid ultrametric trees, observed-species ordering, expected
  Brownian shared-history matrices, and malformed tree/species inputs.
- Updated the phylogenetic/spatial math note and known limitations.

## Mathematical Contract

For a rooted ultrametric branch-length tree, let `d(v)` be the root-to-node
distance and `mrca(a, b)` be the most recent common ancestor of tips `a` and
`b`. The dense Brownian comparator uses:

```text
A_ab = d(mrca(a, b))
R_ab = A_ab / H
```

where `H` is the shared root-to-tip height. This is an internal comparator for
tests and teaching. The large-tree fitting path remains the planned sparse
A-inverse route from `phylo(1 | species, tree = tree)`.

## Files Changed

- `R/phylo-utils.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: 18 passed.
- `Rscript -e "devtools::test()"`: 438 passed.
- `git diff --check`: passed.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The dense comparator test uses a hand-built three-tip ultrametric tree where
the expected Brownian correlation matrix is:

```text
      sp_a sp_b sp_c
sp_a   1.0  0.5  0.0
sp_b   0.5  1.0  0.0
sp_c   0.0  0.0  1.0
```

The malformed-input tests cover no branch lengths, non-ultrametric trees,
duplicated tip labels, tip nodes incorrectly used as parents, duplicated child
nodes, missing species labels, and observed species absent from the tree.

## Consistency Audit

- The math note now records the same dense Brownian covariance equation used
  by the tests.
- Known limitations say internal phylogenetic validation exists but fitted
  `phylo()` model terms do not.
- No user-facing function was exported, so no roxygen or `_pkgdown.yml`
  reference entry was needed.
- `NEWS.md` was not updated because this is internal scaffolding, not a new
  user-facing feature.
- The existing public grammar remains unchanged: `phylo(1 | species,
  tree = tree)` is still planned and rejected by fitting code.

## What Did Not Go Smoothly

The first implementation had to stay disciplined about scope. It would be
tempting to fit a dense phylogenetic random intercept immediately, but that
would conflict with the project decision that the real public tree path should
lead to sparse A-inverse machinery.

## Team Learning

- Ada should keep separating "internal comparator" from "public supported
  syntax" in docs and status updates.
- Goodall's `gllvmTMB` source map confirms that dense tree matrices are best
  treated as validation scaffolding, while the production path should use
  sparse A-inverse objects.
- Zeno's test plan now has a concrete comparator helper to build on before
  simulation recovery tests.
- Rose's after-task protocol caught the need to update known limitations even
  though no exported API changed.

## Known Limitations

- No fitted phylogenetic likelihood was implemented.
- No A-inverse sparse precision is built yet.
- No spatial validation or SPDE mesh validation was implemented.
- The helper assumes a rooted ultrametric tree with branch lengths and
  Brownian-motion covariance.
- The helper does not yet expose provenance or compatibility checks against
  `ape`, `MCMCglmm`, or `gllvmTMB`.

## Next Actions

1. Add a sparse A-inverse builder or adapter for `phylo` trees.
2. Compare sparse prior calculations against the dense Brownian comparator on
   tiny trees.
3. Wire one univariate Gaussian `mu` structured random intercept into the TMB
   likelihood.
4. Add a CRAN-safe simulation recovery test for
   `phylo(1 | species, tree = tree)`.
