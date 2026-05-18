# Slice 219 Meta-V Summary Smoke

## Goal

Wire the `meta_V(V = V)` smoke runner to the Phase 18 aggregation and MCSE
helpers.

## What Changed

- Added `inst/sim/run/sim_summary_meta_v_smoke.R`.
- Added `phase18_summarise_meta_v_smoke()` to run vector and dense
  `meta_V(V = V)` smoke cells, aggregate parameter summaries, and attach
  bias/RMSE MCSEs.
- Added tests for a two-replicate vector/dense summary smoke run and the empty
  summary guard.

## Checks

- `air format inst/sim/run/sim_summary_meta_v_smoke.R tests/testthat/test-phase18-meta-v-summary-smoke.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-219-meta-v-summary-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-meta-v-summary-smoke', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

This remains a tiny smoke run. It reports bias and RMSE summaries with MCSEs
but does not add interval construction, interval coverage, dense-`V`
scalability claims, `metafor` comparators, power, plots, parallel execution, or
rendered reports.

## Standing Roles

Ada kept this parallel to the Gaussian summary smoke. Fisher kept known `V` as
input-only and MCSE as simulation uncertainty, not model uncertainty. Noether
kept fitted `sigma` distinct from sampling covariance. Curie checked vector and
dense paths. Grace kept the smoke grid small. Pat and Darwin kept the output
ready for a readable meta-analysis report. Rose kept scalability and coverage
claims out of scope.
