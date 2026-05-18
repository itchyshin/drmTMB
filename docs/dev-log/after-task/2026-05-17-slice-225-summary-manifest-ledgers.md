# Slice 225 Summary Manifest Ledgers

## Goal

Keep run-status evidence next to Phase 18 aggregate summary-smoke outputs.

## What Changed

- Updated `phase18_summarise_gaussian_ls_smoke()` to return `manifest` and
  `failures` beside `run` and `aggregate`.
- Updated `phase18_summarise_meta_v_smoke()` in the same way for vector and
  dense `meta_V(V = V)` cells.
- Added tests that check the manifest denominator and warning/error ledger
  rows match the underlying replicate results.

## Checks

- `air format inst/sim/run/sim_summary_gaussian_ls_smoke.R inst/sim/run/sim_summary_meta_v_smoke.R tests/testthat/test-phase18-gaussian-ls-summary-smoke.R tests/testthat/test-phase18-meta-v-summary-smoke.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-225-summary-manifest-ledgers.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-ls-summary-smoke|phase18-meta-v-summary-smoke', reporter = 'summary')"`
- `git diff --check`

## Limitations

The summary helpers now expose run-status tables, but they do not yet render a
report or calculate interval coverage. Coverage remains a separate slice that
needs explicit interval columns.

## Standing Roles

Fisher kept the summary denominator visible. Grace and Rose wanted warnings and
errors beside the aggregate output. Pat wanted the object shape to be obvious
for report templates. Curie added focused checks for both Gaussian
location-scale and `meta_V(V = V)` smoke surfaces. Ada kept the slice as a
small attachment rather than a report rewrite.
