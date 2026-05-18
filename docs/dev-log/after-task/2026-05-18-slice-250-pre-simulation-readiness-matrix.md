# Slice 250 Pre-Simulation Readiness Matrix

## Goal

Record a reader-facing status matrix before broad Phase 18 reports are written,
so ready simulation surfaces, planned features, and blocked model classes do
not get mixed together.

## Implemented

- Added `docs/design/46-pre-simulation-readiness-matrix.md`.
- Separated fitted status, current evidence, and Phase 18 admission status for
  Gaussian, meta-analysis, spatial, phylogenetic, Poisson, NB2, bivariate,
  shape, inflation, ordinal, animal/`relmat()`, and structured non-Gaussian
  surfaces.
- Updated the Phase 18 blueprint, roadmap, NEWS, and check log.

## Files Changed

- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format docs/design/46-pre-simulation-readiness-matrix.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-250-pre-simulation-readiness-matrix.md`
- `git diff --check`
- Prose-style pass against `docs/design/46-pre-simulation-readiness-matrix.md`
  for reader, claim, and terminology consistency.

## Prose Review

Reader: applied ecology/evolution users and statistical-method contributors who
need to know what can be simulated now. Pat's pass made the matrix start with
the practical question, not implementation history. Rose's pass kept planned
surfaces out of the ready column and made the blocked rows explicit.

## Consistency Audit

The matrix keeps residual `rho12`, ordinary random-effect correlations,
structured dependence, known sampling covariance `V`, and cross-parameter
non-Gaussian covariance as different layers. It also keeps NB2 `mu` random
effects separate from NB2 `sigma`, zero-inflated NB2, and zero-truncated NB2.

## Known Limitations

This is a planning and reporting slice. It does not add a new likelihood,
simulation runner, or interval producer.

## Next Actions

Use this matrix to choose the next narrow slice: either run tiny optional grids
for ready surfaces or return to one blocked class such as zero-truncated NB2
`mu`, ordinal random intercepts, or non-Gaussian `sigma` random effects.
