# After Task: Sparse Fixed-Effect Design

## Goal

Create a concrete design contract for future sparse fixed-effect matrices so
large factor-heavy models have a clear implementation path.

## Implemented

- Added `docs/design/26-sparse-fixed-effect-matrices.md`.
- Linked it from `docs/design/23-large-data-memory.md`.
- Added a roadmap pointer under Phase 5b.
- Scoped the first target to univariate Gaussian fixed-effect location models.
- Required dense-versus-sparse parity tests before sparse fixed effects support
  any public performance claim.

## Mathematical Contract

No likelihood or formula grammar changed. The design preserves the same linear
predictor equation, `eta = X beta`; only the storage and multiplication path
would change in a future implementation.

## Files Changed

- `docs/design/26-sparse-fixed-effect-matrices.md`
- `docs/design/23-large-data-memory.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-sparse-fixed-effect-design.md`

## Checks Run

- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "implemented yet|planned until|performance claim|O'Dea/Nakagawa|Nakagawa" docs/design/26-sparse-fixed-effect-matrices.md docs/design/23-large-data-memory.md ROADMAP.md docs/dev-log/after-task/2026-05-10-sparse-fixed-effect-design.md`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`

The pkgdown checks and local site build completed cleanly.

## Consistency Audit

The new design note keeps sparse fixed effects separate from the existing
phylogenetic sparse precision path. It also avoids claiming that the
factor-heavy benchmark has converged cleanly.

## Known Limitations

No sparse fixed-effect matrices are implemented yet. This task defines the
path and required tests.

## Next Actions

1. Prototype sparse Gaussian `mu` fixed effects behind an explicit control.
2. Add dense-versus-sparse parity tests before exposing the path in examples.
