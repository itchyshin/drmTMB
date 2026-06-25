# After Task: Phylo Interaction Count Q1 Support-Cell Split

## 1. Goal

Make the q-series support-cell ledger exact for non-Gaussian q1
`phylo_interaction()` `mu` intercept evidence by separating Poisson and NB2
rows instead of carrying one collapsed count row.

## 2. Implemented

- Replaced the old `qseries_phylo_interaction_q1_count_mu` row with exact
  `qseries_phylo_interaction_poisson_q1_mu` and
  `qseries_phylo_interaction_nbinom2_q1_mu` rows.
- Marked both rows as native TMB ML/Laplace point-fit and extractor evidence
  backed by `tests/testthat/test-phylo-interaction.R`.
- Added both row IDs to `tools/validate-mission-control.py` and the
  `test-structured-re-conversion-contracts.R` required q-series cell set.
- Added a focused R dashboard contract that rejects the stale collapsed row
  and checks the family, provider, endpoint, estimator, evidence URL, and
  conservative claim boundaries for the two exact rows.
- Updated the dashboard README and q-series completion map so
  `phylo_interaction()` count intercept evidence is not confused with the
  ordinary-provider count one-slope cells.

## 3a. Decisions and Rejected Alternatives

- Kept this slice as a ledger/test/docs correction. The runtime tests already
  fit Poisson and NB2 q1 `phylo_interaction()` intercept models, so changing
  model code here would have widened a bookkeeping fix into an implementation
  slice without new evidence need.
- Rejected a shared count row with `family = poisson()/nbinom2()`. The
  q-series plan treats family, route, estimator, and evidence as exact
  support-cell fields; collapsing these families would recreate the drift this
  task is meant to remove.
- Kept `bridge_status = unsupported`, `interval_status = unsupported`, and
  `coverage_status = planned`. The existing runtime fits do not prove bridge
  parity, interval reliability, coverage, REML, AI-REML, slopes, q2/q4 endpoint
  covariance, binary incidence, additive partner-main effects, structured
  count scale routes, or public support.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/after-task/2026-06-25-phylo-interaction-count-cell-split.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 tools/validate-mission-control.py` passed with 86 structured RE
  q-series cells.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- One-off Python TSV guard passed with
  `phylo_interaction_count_cells_ok: 2`.
- `git diff --check` passed.
- `gh issue list --repo itchyshin/drmTMB --search "phylo_interaction count q1 NB2 support cell" --limit 20 --json number,title,state,url,labels`
  returned `[]`.
- `Rscript --vanilla -e "devtools::test(filter = 'phylo-interaction|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  did not run because `devtools` is not visible in the current local R library.
  Non-vanilla startup currently forces an old
  `~/R/x86_64-pc-linux-gnu-library/4.4` path into arm64 R 4.6, and package
  availability probes can segfault while loading compiled packages. Remote
  R-CMD-check on the stacked PR is the planned R execution proof for this
  slice.

## 6. Tests of the Tests

The new dashboard contract checks that the stale
`qseries_phylo_interaction_q1_count_mu` row is absent and that the two exact
replacement rows have distinct `family` values, ML/Laplace effective
estimators, native TMB routes, extractor-ready point-fit status, unsupported
bridge and interval status, planned coverage status, and the
`tests/testthat/test-phylo-interaction.R` evidence URL. Reintroducing the old
collapsed row or dropping either family-specific row will fail the contract and
the mission-control required-cell set.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "phylo_interaction count q1 NB2 support cell" --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this is a narrow
stacked-PR bookkeeping correction tied to the q-series support-cell ledger.

## 8. Consistency Audit

- Checked `tests/testthat/test-phylo-interaction.R`; it already contains
  Gaussian, Poisson, and NB2 q1 `phylo_interaction()` intercept fit tests.
- Searched nearby q-series prose in
  `docs/dev-log/dashboard/README.md` and
  `docs/design/218-structured-q-series-completion-map.md`; both now separate
  ordinary-provider count one-slope rows from `phylo_interaction()` count
  intercept rows.
- Re-ran mission-control validation so the dashboard required-cell set agrees
  with the TSV table.
- Kept NEWS and roxygen unchanged because this slice does not add user-facing
  runtime behavior or public API documentation.

## 9. What Did Not Go Smoothly

Local R execution was blocked by the current R startup/library mismatch:
arm64 R 4.6 is being pointed at an old `x86_64-pc-linux-gnu-library/4.4`
library by startup configuration. Using `--no-environ --no-init-file` avoids
the bad library but also exposes an arm64 library that lacks `devtools` and
`testthat`. I avoided editing the global startup files and left R execution to
the remote workflow for this slice.

## 10. Known Residuals

- The two `phylo_interaction()` count rows remain q1 intercept-only evidence.
- No slope, q2, q4, bridge parity, interval, coverage, REML, AI-REML, binary
  incidence, additive partner-main, structured count scale, or public-support
  claim is added.
- Local R tests still need a clean arm64 R library setup or remote CI evidence.

## 11. Team Learning

When a family class has more than one concrete likelihood, the support-cell row
must split by exact `family` instead of using a coarse count placeholder. This
keeps future q-neighbour and family-neighbour claims from leaking across cells.
