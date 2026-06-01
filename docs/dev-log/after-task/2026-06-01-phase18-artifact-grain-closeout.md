# Phase 18 Artifact-Grain Closeout

## Goal

Close the current #255 artifact-grain contract while preserving a separate
follow-up lane for future simulation galleries.

## Implemented

`docs/design/150-phase-18-artifact-grain-closeout.md` now records the current
guarantee: first-wave report staging and the count-pilot gallery choose
cloud-style geometry only from replicate-ready artifacts. Aggregate-only rows
remain point, bar, MCSE, or interval-range evidence.

The table-bundle tests now cover `gaussian_ls_grid`, `meta_v_grid`,
`count_mu_random_effect_grid`, `proportion_fixed_effect_grid`, and
`biv_rho12_grid` under the grain-status classifier. The future-gallery hygiene
lane is #461.

## Mathematical Contract

No likelihood, formula grammar, or model parameterization changed. The contract
is a reporting invariant:

- `artifact_grain = "replicate"` means rows are eligible for replicate-error
  clouds when the required plotting columns exist;
- `artifact_grain = "aggregate"` means rows must stay on aggregate geometry;
- missing, empty, mixed-grain, or missing-grain artifacts require table-only
  audit or repair before any cloud-style display.

## Files Changed

- `tests/testthat/test-phase18-first-wave-table-bundle.R`
- `docs/design/150-phase-18-artifact-grain-closeout.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-phase18-first-wave-table-bundle.R docs/design/150-phase-18-artifact-grain-closeout.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-phase18-artifact-grain-closeout.md
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-(table-bundle|summary-report|summary-render-helper)$|^phase18-count-gallery-template$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "artifact-grain closeout|artifact_grain = \"replicate\"|replicate_cloud_allowed|replicate_cloud_gate|fake.*cloud|aggregate-only|Phase 18 artifact-grain|#255|#461|Slice 1832|1832|gaussian_ls_grid|meta_v_grid|count_mu_random_effect_grid|proportion_fixed_effect_grid|biv_rho12_grid" inst/sim README.md ROADMAP.md NEWS.md docs vignettes tests/testthat
git diff --check
```

Outcome:

- Focused first-wave table-bundle, first-wave summary-report,
  first-wave summary-render-helper, and count-gallery template tests passed.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The artifact-grain closeout scan found the current gate wording, historical
  notes, #255/#461 references, and the new ROADMAP/design entries.
- `git diff --check` passed.

## Tests Of The Tests

The new test uses synthetic first-wave grid outputs for the five current grid
surface names that satisfy the #255 surface check. It verifies that every
aggregate CSV is classified as `aggregate_only` with
`aggregate_points_bars_mcse_only`, and every replicate CSV is classified as
`replicate_ready` with `replicate_clouds_allowed`.

## Consistency Audit

The Phase 18 design note, simulation README, ROADMAP, and check log now state
the same closeout: current report staging has a grain gate, the count gallery
has a rendered aggregate-grain negative smoke, and future galleries belong to
#461 rather than reopening #255.

## GitHub Issue Maintenance

Opened #461 for future simulation-gallery grain gates. After this PR merges,
#255 can be closed with a note pointing to #458, #459, #460, and this closeout.

## What Did Not Go Smoothly

The closeout needed a follow-up issue first. Without #461, #255 would have
remained an unbounded future-gallery reminder rather than a closeable current
contract.

## Team Learning

Close broad figure-contract issues by separating current guarantees from
future-gallery hygiene. The repository should carry the invariant in tests,
not only in issue comments.

## Known Limitations

This is reporting-contract evidence only. It does not dispatch a simulation
grid, add a new model surface, or claim recovery, coverage, or power.

## Next Actions

Close #255 after merge. Use #461 whenever a future Phase 18 report adds
cloud-style, dot-density, empirical-quantile, or replicate-level failure
geometry.
