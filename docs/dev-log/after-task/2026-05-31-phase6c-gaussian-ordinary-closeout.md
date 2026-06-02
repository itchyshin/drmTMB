# After Task: Phase 6c Gaussian Ordinary Random-Slope Closeout

## Goal

Close #439 by making the ordinary Gaussian random-slope evidence explicit
before larger Phase 18 power simulations use the random-slope matrix.

## Implemented

- `README.md`, `vignettes/model-map.Rmd`, `ROADMAP.md`, and
  `docs/dev-log/known-limitations.md` now say that ordinary Gaussian `mu`
  random intercepts, independent slopes, one-slope correlated blocks, and q > 2
  numeric multi-slope blocks are fitted, while larger q blocks remain advanced
  and sample-size hungry.
- The same status rows now say Gaussian `sigma` random intercepts and
  independent numeric slopes are fitted on log-`sigma`, while correlated
  residual-scale slope blocks and labelled residual-scale slope covariance
  remain planned.
- `docs/design/33-phase-6c-core-random-effects.md` now names the q=3 recovery,
  q=4 output-contract, extractor, `corpairs()`, `summary()$covariance`,
  `profile_targets()`, and Phase 18 grid-writer evidence handles for the
  ordinary Gaussian rows.
- The Phase 6c core design note no longer preserves the stale sentence saying
  phylogenetic slopes have no fitted route; it now matches the #438 support
  matrix and leaves the fuller structured one-slope audit to #442.

## Boundary

No likelihood, parser, TMB, extractor, simulation-runner, or formula-grammar
code changed. This is a status and evidence-link closeout for already-fitted
ordinary Gaussian surfaces.

## Mathematical Contract

The ordinary Gaussian `mu` q > 2 contract remains a grouped random-effect
vector with unstructured covariance. If the block has `q` coefficients, the
model estimates `q` SDs and `q * (q - 1) / 2` constant correlations. The
Gaussian `sigma` random-slope contract remains independent random effects on
the log-`sigma` linear predictor unless a future slice implements a correlated
residual-scale covariance block.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-gaussian-ordinary-closeout.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/model-map.Rmd`

## Checks Run

Recorded in `docs/dev-log/check-log.md` under the 2026-05-31 Phase 6c Gaussian
ordinary random-slope closeout entry.

## Tests Of The Tests

This closeout reuses the focused tests that already proved the fitted surface:
`test-gaussian-random-intercepts.R` for q=3/q=4 ordinary `mu`, extractor,
`corpairs()`, summary, profile-target, and log-`sigma` slope status;
`test-phase18-gaussian-mu-random-slope.R` for the q=3 smoke surface; and
`test-phase18-random-slope-grid-writers.R` for the Gaussian random-slope
artifact writers. The new work is evidence linkage and stale-wording removal,
so source and rendered text scans are the failure-path checks.

## Consistency Audit

The closeout keeps ordinary Gaussian `mu` multi-slope support separate from
residual-scale covariance, slope-specific `sd()` models, bivariate q=6/q=8
endpoints, structured slope correlations, and non-Gaussian correlated slopes.
It also keeps q > 2 SD profile targets separate from q > 2 derived
correlations, which remain unavailable for direct profile intervals.

## GitHub Issue Maintenance

#439 is the owning issue. #442 remains open for the fuller structured Gaussian
one-slope audit; this slice only removed a stale structured-slope sentence that
conflicted with the already-merged #438 matrix.

## What Did Not Go Smoothly

The first source audit found one stale structured-slope line in the Phase 6c
core note. It was outside the strict ordinary-Gaussian row, but leaving it would
make the random-slope status table internally inconsistent.

## Team Learning

Rose: ordinary closeouts should still scan neighbouring rows in the same
support table, because stale structured wording can undermine the evidence
matrix. Fisher: keep the q > 2 SD and q > 2 correlation interval stories
separate in user-facing text.

## Known Limitations

This closeout does not promote correlated residual-scale slope blocks, labelled
residual-scale slope covariance, slope-level `mu`/`sigma` covariance,
coefficient-specific `sd()` slope models, q=6/q=8 bivariate endpoints,
structured slope correlations, or correlated non-Gaussian slopes.

## Next Actions

Use this ordinary Gaussian closeout as a stable input for #446, the
random-slope simulation power, accuracy, and coverage plan.
