# After Task: Slice 292 Phase 18 Comprehensive Blueprint

## Goal

Start the comprehensive Phase 18 simulation design after the Slice 291 gate,
while keeping planned or blocked model lanes out of fitted grids.

## Implemented

`docs/design/41-phase-18-simulation-programme.md` now has a Slice 292
comprehensive design map. The map covers continuous, proportion, count,
ordinal, meta-analysis, bivariate, random-slope, shape, phylogenetic, spatial,
`animal()`, and `relmat()` lanes. Each lane is assigned to admitted grid,
fixed-effect design target, opt-in stress cell, or failure ledger before new
DGP files are added.

`inst/sim/README.md` now points simulation contributors to that map before they
add new DGP files. NEWS and ROADMAP record that Slice 292 is done locally as a
blueprint, not as a full simulation run.

## Mathematical Contract

No likelihood, formula grammar, simulation code, fitted model, extractor,
interval method, or test fixture changed. This slice changes the simulation
design contract: admitted lanes need one-page ADEMP sheets before code, while
planned or blocked lanes remain failure-ledger rows.

## Files Changed

- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-223344-codex-checkpoint.md`

## Checks Run

```sh
air format docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n "Slice 292|comprehensive design map|one-page ADEMP|failure-ledger only|admitted.*animal|admitted.*relmat|skew-normal.*admitted|comprehensive all-feature|NB2.*not yet.*interval|Later waves can add .*ordinal" docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
rg -n "fixed-effect ordinal|ordinal mixed|cumulative_logit\\(\\)|shape/skew extensions|zero-inflation or hurdle random effects|focused first slice" docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n "Slice 292|comprehensive design map|one-page ADEMP|failure-ledger only|NB2.*not yet.*interval|full smoke runner/interval|comprehensive all-feature" docs/design/41-phase-18-simulation-programme.md inst/sim/README.md NEWS.md ROADMAP.md
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 292 Phase 18 comprehensive blueprint" --next "stage, commit, push, and open draft PR"
```

All checks passed. The first overclaim scan caught an older ROADMAP sentence
that said NB2 lacked the smoke runner and interval-coverage surface; this slice
updated that sentence to match the current Poisson/NB2 smoke evidence.

## Tests Of The Tests

No executable tests changed. The useful closeout checks are the overclaim
scans: they would have flagged new fitted-grid claims for `animal()` or
`relmat()`, admitted skew-family grids, a comprehensive all-feature claim, or
stale NB2 interval wording.

## Consistency Audit

The new map follows the Slice 291 evidence-ledger gate and the ADEMP structure
already named in the Phase 18 blueprint. Continuous, proportion, count,
ordinal, meta-analysis, bivariate, random-slope, shape, phylogenetic, and
spatial lanes are separated rather than collapsed into one grid. `animal()` and
`relmat()` remain failure-ledger only because no fitted likelihood exists.

## What Did Not Go Smoothly

The old DGP section still treated ordinal and NB2 as if the newer readiness
slices had not landed. The readback pass fixed that: fixed-effect ordinal can
receive a small DGP sheet, while ordinal mixed models stay blocked, and NB2 is
now described as a focused first slice with existing smoke and interval
evidence rather than as an unfinished interval surface.

## Team Learning

Ada kept the work at blueprint level. Curie enforced the simulation-design
sequence: one-page ADEMP sheet before new code. Fisher checked that admitted
means evidence-backed, not merely interesting. Rose checked overclaim and stale
roadmap wording. Pat and Darwin checked that future report writers can see what
to simulate and what to report only as failure-ledger context. Grace confirmed
formatting, pkgdown, and whitespace checks. No spawned subagents were used.

## Known Limitations

No DGP, runner, report, result schema, or simulation output was added. The next
implementation slice should choose one admitted lane and write its one-page
ADEMP sheet before adding code.

## Next Actions

Start the first post-blueprint implementation with an admitted lane that already
has smoke infrastructure, such as Gaussian location-scale, paired Poisson/NB2
`mu` random effects, `meta_V(V = V)`, or coordinate spatial Gaussian `mu`.
