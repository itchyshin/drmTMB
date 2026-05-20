# Slices 789-798: Phase 18 First-Wave Summary Render Helper

## Goal

Ada added the first end-to-end orchestration helper for Phase 18 first-wave
report staging.

## Implemented

`phase18_render_first_wave_summary_report()` takes grid-writer outputs and
then:

1. writes the bound artifact manifest and artifact-status CSVs;
2. writes bundled first-wave artifact tables;
3. optionally renders `phase18-first-wave-summary-report.Rmd` to HTML.

The helper supports `render = FALSE` for staging-only runs and keeps the
summary report path in the returned object when rendering is requested.

## Mathematical Contract

No model, likelihood, DGP, interval method, or operating-characteristic metric
changed. This is orchestration over existing report-staging artifacts.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/run/sim_render_first_wave_summary_report.R`
- `tests/testthat/test-phase18-first-wave-summary-render-helper.R`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-render-helper$')"
air format inst/sim/run/sim_render_first_wave_summary_report.R tests/testthat/test-phase18-first-wave-summary-render-helper.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-render-helper$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-.*|sim-runner|gaussian-ls-grid-writer|meta-v-grid-writer|count-mu-random-effect-grid-writer|random-slope-grid-writers|biv-rho12-grid-writer|student-shape-grid-writer)$')"
```

Result:

- After fixing the fake grid-output fixture, 16 expectations passed with 0
  failures, 0 warnings, and 0 skips before and after formatting.
- The broader first-wave staging and grid-writer bundle passed with 257
  expectations, 0 failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The first run exposed a real fixture mistake: the fake grid output had `paths`
but no `artifact_manifest`, while real grid-writer outputs provide both. The
test now matches the real writer contract. The focused tests cover staging-only
output, rendered HTML output, overwrite protection, parameter handoff, and
input validation.

## Consistency Audit

The README, roadmap, NEWS, and Phase 18 simulation programme now name the
summary-render helper as private report-staging infrastructure.

## What Did Not Go Smoothly

The initial fake fixture was too loose. Ada kept the stricter artifact-status
contract and corrected the fixture instead.

## Team Learning

- Ada: orchestration helpers should preserve the grid-writer object contract
  rather than accepting weaker stand-ins.
- Curie: the test now verifies the same `artifact_manifest` shape real grid
  writers return.
- Pat: one helper now creates the status files, table bundle, and report path a
  user can inspect.
- Grace: `render = FALSE` gives scheduled jobs a way to stage tables without
  requiring Pandoc.
- Rose: this closes the first end-to-end report-staging loop.

## Known Limitations

- The helper does not run simulation grids itself; it consumes grid-writer
  outputs.
- The helper does not validate semantic table correctness.
- The rendered report remains table-first and has no figure layer yet.

## Next Actions

1. Add a broader focused Phase 18 validation run including first-wave staging
   tests and grid-writer tests.
2. Start the Florence-facing figure layer only after the table/report staging
   remains stable under that broader validation.
