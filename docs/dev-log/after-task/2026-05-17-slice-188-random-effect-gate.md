# After Task: Slice 188 Random-Effect Gate

## Goal

Publish the one-slope-per-layer status table and remaining Gaussian
double-hierarchical limits before the non-Gaussian revisit.

## Implemented

`ROADMAP.md` now has a Slice 188 one-slope gate table covering ordinary
Gaussian `mu`, Gaussian `sigma`, univariate `mu`/`sigma` covariance,
bivariate ordinary covariance, phylogenetic structured effects, coordinate
spatial structured effects, and non-Gaussian families. The Phase 6c core
random-effects design note carries the same pre-simulation gate in a compact
form.

## Mathematical Contract

The gate separates fitted random-effect layers from planned endpoint surfaces.
It does not change likelihood code. Its purpose is to prevent Phase 18
simulation from treating these as equally mature:

```text
ordinary mu slopes       fitted, q=3 recovery path
sigma slopes             fitted as independent log-sigma terms
mu/sigma covariance      fitted for intercept-level matched blocks
bivariate slopes         planned
phylogenetic slopes      planned
spatial one-slope        fitted for univariate Gaussian mu only
non-Gaussian RE          pre-simulation decision gate
```

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-188-random-effect-gate.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/33-phase-6c-core-random-effects.md`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `rg -n "random slopes.*done|phylo\\(1 \\+ x.*Implemented|bivariate random slopes.*Implemented|spatial.*sigma.*Implemented|q=8.*Implemented|non-Gaussian.*random effects.*Implemented" README.md ROADMAP.md NEWS.md docs/design vignettes --glob '!docs/dev-log/**'`:
  returned no stale implemented-status claims.
- `git diff --check`: passed.

## Tests Of The Tests

This is a documentation and gate-setting slice. It relies on the fitted-surface
tests added or refreshed in Slices 177-187 and does not add new executable
tests.

## Consistency Audit

The one-slope table in `ROADMAP.md` and the compact gate in
`docs/design/33-phase-6c-core-random-effects.md` agree on fitted versus
planned surfaces. Both keep residual `rho12`, group-level correlations,
phylogenetic correlations, and spatial fields separate.

## What Did Not Go Smoothly

The challenge is that several surfaces are partly mature. The table uses
layer-specific wording instead of a single "random slopes done" claim.

## Team Learning

Ada used Slice 188 as a gate rather than another feature slice. Fisher kept the
simulation-readiness column tied to evidence, not aspiration. Curie linked the
table to the tests from Slices 177-187. Pat pushed for one reader-facing table
before the non-Gaussian revisit. Grace kept validation light because no code
changed. Rose recorded the remaining Gaussian limits before Slice 189 closes
boundary wording.

## Known Limitations

This slice does not implement remaining Gaussian double-hierarchical surfaces
or non-Gaussian random effects. It prepares the status map for Slice 189 and
the Slice 190-202 non-Gaussian gate.

## Next Actions

Slice 189 should close any remaining Gaussian double-hierarchical boundary
wording before Slice 190 starts the non-Gaussian `mu` random-effect decision.
