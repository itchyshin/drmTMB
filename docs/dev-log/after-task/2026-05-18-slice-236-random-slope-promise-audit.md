# Slice 236 Random-Slope Promise Audit

## Goal

Reconcile the pre-simulation random-slope promise so Phase 18 does not simulate
surfaces that are still planned, and does not understate the ordinary Gaussian
`mu` multi-slope path that is already fitted.

## Implemented

- Corrected stale roadmap wording that still said ordinary Gaussian `mu` did
  not fit arbitrary numeric multi-slope covariance blocks.
- Updated the correlated random-effect block design note to state that
  univariate Gaussian `mu` accepts q > 2 numeric grouped covariance blocks, with
  q=3 recovery evidence and direct-SD profile targets.
- Added a Slice 236 pre-simulation boundary to the Phase 6c random-effect
  design note and the Phase 18 simulation programme.

## Mathematical Contract

For an ordinary grouped location block with `q` coefficients, `drmTMB`
estimates `q` SDs and `q * (q - 1) / 2` constant block correlations. The q > 2
correlations are reported as derived quantities from a positive-definite
covariance parameterization, so direct correlation profile intervals remain
unavailable until a dedicated derived-interval method exists.

## Files Changed

- `ROADMAP.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format ROADMAP.md docs/design/17-correlated-random-effect-blocks.md docs/design/33-phase-6c-core-random-effects.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-236-random-slope-promise-audit.md`
- `rg -n "does not yet fit arbitrary numeric|univariate q > 2 blocks" ROADMAP.md docs/design`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|spatial-gaussian|phylo-gaussian|biv-gaussian|comparators', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

This is a documentation and consistency slice. The targeted tests were not new,
but they cover the implementation evidence named by the audit: ordinary q > 2
Gaussian `mu`, coordinate-spatial one-slope support, phylogenetic slope
rejection, bivariate slope boundaries, and comparator overlap.

## Consistency Audit

The stale ordinary q > 2 wording was in the early Phase 4 roadmap and the older
correlated-block design note. The later Slice 177-188 roadmap table and
`docs/design/33-phase-6c-core-random-effects.md` already had the current status.
This slice makes those documents agree.

## What Did Not Go Smoothly

The project had become internally inconsistent because the implementation moved
faster than the older design contract. Rose flagged this as a memory failure:
the correct status existed in one part of the roadmap, but an older paragraph
still contradicted it.

## Team Learning

Ada kept the work as a boundary audit rather than a new feature. Rose checked
for stale claims. Fisher kept the inference status precise: q > 2 SD profiles
are direct, while q > 2 correlation intervals are derived-unavailable. Pat kept
the reader-facing rule short enough to answer the user's question. Grace kept
the slice documentation-only and validation-light.

## Known Limitations

This slice does not implement phylogenetic slopes, bivariate slopes, correlated
Gaussian `sigma` slope blocks, slope-level `mu`/`sigma` covariance, or
non-Gaussian scale/shape random effects. Those remain separate gates before
they can enter the comprehensive simulation.

## Next Actions

Move to Slice 237 by checking whether ordinary Gaussian `mu` q > 2 has enough
diagnostics, failure messages, and simulation summary hooks for Phase 18, then
continue the same boundary audit for Gaussian `sigma`, structured effects, and
non-Gaussian random effects.
