# After-task — sparse Quaas A-inverse for `animal()` pedigrees (#740)

Date: 2026-09-24
Lane: Cursor, `cursor/sparse-quaas-ainv-20260924`, worktree off `origin/main` `7f7293f2d`
Reader: anyone fitting `animal(1 | id, pedigree = ped)` on a pedigree of more than a
few hundred individuals, and anyone auditing the claim that this slice makes
those fits cheaper.

## What changed

`drm_pedigree_relatedness_precision()` previously built the additive
relationship matrix `A` densely and inverted it with `chol2inv(chol(A))`.
The result is sparse in *format* and dense in *content*: `Matrix::drop0()`
removes only exact zeros, and a numerical inverse has almost none, so TMB
received a matrix with about `n^2` stored nonzeros and refactorised all of
them on every inner iteration.

This slice assembles `A^-1` directly from the Henderson (1976) / Quaas (1976)
recursion instead. Each individual contributes its Mendelian sampling variance
`d_i` on the diagonal and the `-0.5` / `+0.25` parent cross-terms;
`Matrix::sparseMatrix()` sums the duplicated `(i, j)` triplets. The assembly is
vectorised over the pedigree rather than looped per individual.

`A` itself is still formed densely, because the inbreeding coefficients `F`
that set `d_i` are read off its diagonal. That is the same compromise
`gllvmTMB` makes. Replacing it needs the Meuwissen-Luo (1992) O(n) inbreeding
recursion, which is a separate slice.

## Evidence

Simulated pedigrees, 20 founders, every later individual assigned two distinct
randomly sampled earlier parents. Measured on this machine, absolute seconds,
whole construction path including `A`:

| n | stored nonzeros, before | stored nonzeros, after | construct before (s) | construct after (s) | of which dense `A` (s) |
|---|---|---|---|---|---|
| 1000 | 998,006 | 6,840 | 1.53 | 0.59 | 1.47 |
| 2000 | 4,000,000 | 13,834 | 3.02 | 2.32 | 2.62 |
| 4000 | 16,000,000 | 27,830 | 10.84 | 9.44 | 9.72 |

The nonzero count is the number that matters: it is what TMB factorises on
*every* iteration, whereas construction happens once. Construction time is not
worse, but it is now dominated by the dense `A` that both routes build.

No speed claim is made about end-to-end fit wall time here. The published
drmTMB TMB walls sit at 0.013-0.113 s on the benchmarked cells, which are far
too small for this lever to show; a fit-level claim needs a large-`n` animal
cell and has not been measured.

Correctness: `max|A^-1_sparse - chol2inv(chol(A))| < 1e-6` at n in
{250, 500, 1000, 2000, 4000}, and `log|A^-1| = -log|A|` to the same tolerance.

Before the change, the dense route also *aborted* on the 4000-individual cell
with "the leading minor is not positive definite" out of `chol()`. So this was
not only a cost problem; it was a user-facing failure at scale.

## Contract preserved

`drm_known_relatedness_precision()` gained an internal `reported_matrix_type`
argument. The `animal()` surface must keep reporting `matrix_type=covariance`
(pinned at `tests/testthat/test-animal-relmat-gaussian.R:615`) because the user
supplied a pedigree, not a precision matrix; the new path validates as a
precision matrix but reports as before. `relmat()` continues to report
`matrix_type=precision` (line 489). Neither pin moved.

## Provenance

The sparse assembly mirrors `gllvmTMB`'s `.gllvm_pedigree_precision()`
(`R/pedigree-precision.R`). That function's own header records that its
pedigree standardisation, parent normalisation, topological ordering and dense
tabular `A` came from drmTMB, so this is a co-opt back across the twins rather
than a new import. Noted in the source comment; `inst/COPYRIGHTS` already
covers the sister-package relationship.

## Checks run

```
testthat::test_file("tests/testthat/test-pedigree-sparse-ainv.R")   # 6 pass, 0 fail
testthat::test_file("tests/testthat/test-animal-relmat-gaussian.R") # 479 pass, 0 fail
```

## Follow-up

1. Meuwissen-Luo O(n) inbreeding, removing the dense `A` entirely. This is the
   remaining `n^2` term and now the dominant one.
2. A large-`n` animal fit cell, so an end-to-end wall-time statement can be
   made with evidence instead of inference.
