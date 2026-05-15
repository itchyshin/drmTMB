# After Task: Phase 5b Slice 43 Sparse Fixed-Effect Parity Scaffold

## Goal

Create a tested internal scaffold for sparse fixed-effect matrices before
exposing a public `sparse_fixed` control or changing TMB inputs. The claim is:
`drmTMB` now has internal helpers that build dense and sparse fixed-effect
design matrices from the same terms and verify that they produce the same
matrix entries and linear predictor on small data.

## Implemented

- Added `drm_fixed_effect_matrix()` for dense or sparse construction from the
  same `terms` and data.
- Added `drm_sparse_fixed_parity()` to compare dense and sparse shapes,
  dimnames, entries, and test linear predictors.
- Added tests for factors with unused levels and interaction terms.
- Added a test that `fixed_effect_design_summary()` records sparse matrix
  density using `Matrix::nnzero()`.
- Added a snapshot for malformed `beta` length in the parity helper.
- Updated `docs/design/26-sparse-fixed-effect-matrices.md` and `ROADMAP.md`.

## Mathematical Contract

No fitted model uses the sparse matrix path yet. The parity helper checks the
same fixed-effect statement in two storage forms:

```text
eta_dense = X_dense beta
eta_sparse = X_sparse beta
```

The required first invariant is `eta_dense == eta_sparse` up to numerical
tolerance for the same model terms, data, and coefficient vector.

## Files Changed

- `R/sparse-fixed.R`
- `tests/testthat/test-sparse-fixed-effects.R`
- `tests/testthat/_snaps/sparse-fixed-effects.md`
- `docs/design/26-sparse-fixed-effect-matrices.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "sparse-fixed-effects", reporter = "summary")'`:
  passed on rerun after accepting the new snapshot.
- `Rscript -e 'devtools::test(filter = "sparse-fixed-effects|check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The parity test would fail if `Matrix::sparse.model.matrix()` produced a
different column set, column order, or linear predictor than
`stats::model.matrix()` for the chosen factor and interaction design. The
snapshot covers the main malformed-input guard.

## Consistency Audit

The roadmap and sparse fixed-effect design note both state that this is an
internal scaffold, not implemented sparse fitting. No public documentation
claims that users can request sparse fixed-effect matrices in `drmTMB()` yet.

## What Did Not Go Smoothly

The first run created the expected new snapshot. A second run was needed to
confirm the snapshot is now stable and warning-free.

## Team Learning

- Ada should continue separating scaffolds from fitted feature claims.
- Boole should keep `sparse_fixed` out of the public API until the first
  `drmTMB()` fit path actually uses sparse matrices.
- Gauss should decide the C++ contract next: parallel sparse fields or a common
  linear-predictor helper.
- Noether should treat column-name and `eta` parity as non-negotiable before
  likelihood parity.
- Curie should add the first sparse-vs-dense fitted likelihood test before any
  benchmark.
- Fisher should not interpret this as performance evidence.
- Pat should not see this in tutorials as an available user option yet.
- Grace should keep the scaffold out of CRAN-time heavy benchmarks.
- Rose should keep policing wording around "planned" versus "implemented".

## Known Limitations

- `drmTMB()` still fits with dense fixed-effect matrices.
- No sparse TMB data branch exists yet.
- No public `drm_control(sparse_fixed = TRUE)` argument exists yet.

## Next Actions

The next Phase 5b slice should choose the first actual sparse fit target and
write the dense-versus-sparse fitted likelihood parity test before touching the
C++ template.
