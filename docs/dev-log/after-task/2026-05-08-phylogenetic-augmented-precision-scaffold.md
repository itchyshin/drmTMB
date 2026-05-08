# After Task: Phylogenetic Augmented Precision Scaffold

## Goal

Add the next internal algebra layer for phylogenetic models: a sparse
augmented Brownian precision that can later feed the TMB likelihood for
`phylo(1 | species, tree = tree)`.

## Implemented

- Added `drm_phylo_augmented_precision()` as an internal helper.
- The helper builds a sparse precision over all non-root tree nodes.
- The root is fixed at zero and excluded from the latent state.
- The default precision is on the correlation scale, matching
  `z ~ MVN(0, sigma_phylo^2 A)`.
- The helper returns node labels, tip-node indices, species-level mapping, and
  row-level observation-to-species mapping.
- Added algebraic tests for sparse precision, log determinant, tip marginal
  covariance, species mapping, edge-order invariance, polytomies, and
  positive-branch-length validation.

## Mathematical Contract

For every edge from parent `p` to child `c` with branch length `l`, the
Brownian increment contributes:

```text
(x_c - x_p)^2 / l
```

If `p` is not the root:

```text
Q_cc = Q_cc + 1 / l
Q_pp = Q_pp + 1 / l
Q_cp = Q_cp - 1 / l
Q_pc = Q_pc - 1 / l
```

If `p` is the root, `x_p = 0`, so only `Q_cc = Q_cc + 1 / l` is added. For an
ultrametric tree of height `H`, the correlation-scale precision is:

```text
Q_A = H Q_raw
```

The defining test invariant is:

```text
solve(Q_A)[tips, tips] = A
```

where `A` is the dense Brownian phylogenetic correlation matrix produced by
the internal comparator.

## Files Changed

- `R/phylo-utils.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`: 39 passed.
- `Rscript -e "devtools::test()"`: 459 passed.
- `git diff --check`: passed.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no
  problems found; site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The tiny tree has an exact raw augmented precision:

```text
        sp_a sp_b sp_c node4
sp_a       1    0  0.0    -1
sp_b       0    1  0.0    -1
sp_c       0    0  0.5     0
node4     -1   -1  0.0     3
```

- On the correlation scale, the precision is multiplied by tree height `H = 2`.
- The test solves the augmented precision and selects the tip rows; it does
  not compare the tip block of the precision to a marginal inverse.
- A reordered edge table gives the same precision after aligning node labels.
- A three-tip polytomy is accepted and gives an identity precision on the
  correlation scale.
- Zero branch lengths are accepted by the validator only as tree structure but
  rejected by the precision helper because `1 / l` is undefined.

## Consistency Audit

- The design note now records the same edge-increment equations as the helper.
- Known limitations now say the sparse augmented precision helper exists but
  fitted `phylo()` terms still do not.
- The public formula grammar is unchanged.
- No user-facing function was exported, so no roxygen or `_pkgdown.yml` update
  was needed.
- `NEWS.md` was not updated because this is internal numerical scaffolding.

## What Did Not Go Smoothly

The first subagent test proposal compared a dense tip precision directly. That
would be wrong for the augmented-node construction because the tip block of a
precision is conditional, not marginal. Locke caught this, and the implemented
tests now solve the augmented system before comparing tip covariances.

## Team Learning

- Ada should keep invoking numerical reviewers before any TMB likelihood path
  changes; small algebraic misunderstandings are cheap to fix here and
  expensive later.
- Gauss and Noether need the same equation in code, tests, and docs for every
  structured-effect block.
- Pasteur's exact tiny-tree tests are the right pattern for the next sparse
  prior contribution test.
- Rose should continue checking that internal support is not advertised as
  user-facing model support.

## Known Limitations

- No TMB likelihood was changed.
- No model fitting uses the new precision yet.
- The helper only covers rooted ultrametric Brownian trees.
- Zero-length branch collapse is not implemented.
- No compatibility comparison against `ape`, `MCMCglmm`, or `gllvmTMB` has
  been added yet.

## Next Actions

1. Add a pure-R sparse-prior contribution helper and compare it with the dense
   Gaussian prior for tiny trees.
2. Add the corresponding C++/TMB structured-effect prior block.
3. Wire one univariate Gaussian `mu` structured random intercept into the
   model builder.
4. Add simulation recovery for `phylo(1 | species, tree = tree)` before
   exposing fitted phylogenetic models as supported.
