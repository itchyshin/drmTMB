# Q-Series direct-SD univariate target-split smoke

## 1. Goal

Advance the Gaussian low-q special target
`qseries_phylo_direct_sd_univariate` from a pure contract hold to a retained
local target-split smoke, without promoting the support cell to
`inference_ready`, coverage-ready, `supported`, or bridge/public support.

## 2. Implemented

- Added `tools/run-structured-re-gaussian-lowq-direct-sd-univariate-smoke.R`.
- Ran the local n=1 smoke for the two direct univariate phylo SD targets:
  `sd:mu:phylo(1 | species)` and `sd:sigma:phylo(1 | species)`.
- Added dashboard and artifact sidecars:
  `structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv`,
  replicate TSV, seed manifest, `sessionInfo.txt`, and `git-sha.txt`.
- Updated the Gaussian low-q row-selection row for
  `qseries_phylo_direct_sd_univariate` to
  `direct_sd_local_smoke_target_split_review_pending`, with first smoke `n=1`.
- Updated the special-target contract, low-q status audit, support-cell row,
  widget, mission-control validator, and focused R dashboard contract test.
- Kept the support cell at
  `point_fit / interval_feasible / planned`.

## 3a. Decisions and Rejected Alternatives

- Chose a target-split smoke instead of a status promotion. The mu-axis direct
  SD target passed the tiny local smoke, but the sigma-axis direct SD target
  retained a boundary Wald interval and endpoint-profile budget failure.
- Kept raw Wald `small_sample_df=none` and `bias_correct=none` for this smoke.
  The smoke is diagnostic and not a claim about the location-axis default
  correction.
- Did not inherit direct-SD target availability into derived-correlation,
  q2, q4/q8, non-Gaussian, REML, AI-REML, bridge, public support, or
  `supported` wording.
- Kept `qseries_phylo_interaction_q1_mu` on the provider-boundary review path;
  it still lacks an interval route.

## 4. Files Touched

- `tools/run-structured-re-gaussian-lowq-direct-sd-univariate-smoke.R`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-direct-sd-univariate-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-special-target-contract.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-direct-sd-univariate-smoke-local/`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-direct-sd-univariate-target-split-smoke.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-direct-sd-univariate-smoke.R --overwrite=true`:
  passed and wrote two target rows plus two retained replicate rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `/opt/homebrew/bin/air format tools/run-structured-re-gaussian-lowq-direct-sd-univariate-smoke.R tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8610 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true tools/start-mission-control.sh --background`:
  passed and refreshed the served widget bundle to `r149`.
- Browser preview at `http://127.0.0.1:8765/`: rendered the Q-Series board,
  the `Low-q direct SD` summary chip, both direct-SD target rows, and no
  subtitle data-load error.

## 6. Tests of the Tests

The validator now requires the direct-SD smoke dashboard TSV to mirror the raw
artifact summary, requires two retained target rows, and checks the exact
mu-axis pass versus sigma-axis boundary/profile-budget blocker. The focused R
test checks the support cell remains `point_fit/interval_feasible/planned`, the
special-target contract uses the new status, and the replicate artifact retains
the sigma boundary warning and endpoint-profile budget message.

This was not a mutation-test run, but reverting the direct-SD row to the old
`direct_sd_contract_banked_review_pending` status or removing the sigma-axis
blocker text now fails both mission-control and the focused R test.

## 8. Consistency Audit

Checked the support-cell row, low-q audit row, special-target contract,
row-selection source and mirror, direct-SD smoke summary, replicate TSV, seed
manifest, mission-control validator, focused R test, and rendered widget.

The direct-SD row now has target-specific smoke evidence, but all scientific
claim boundaries still say that n=1 is not coverage evidence and that derived
correlations remain separate.

## 10. Known Residuals

- `qseries_phylo_direct_sd_univariate` is not `inference_ready` or
  `supported`.
- The sigma-axis direct SD target is boundary/profile-budget blocked at this
  smoke setting.
- Fisher/Noether/Rose still need to choose a retained denominator, one-sided
  miss policy, interval channel, and derived-correlation exclusion before
  Totoro/FIIA, Nibi/Rorqual, DRAC, or promotion work.
- `qseries_phylo_interaction_q1_mu` remains a q1 pair-level point/extractor row
  with no interval route.
- q2, q4/q8, non-Gaussian, REML, AI-REML, bridge support, public support, and
  support-tier claims remain separate unfinished arcs.

## 11. Team Learning

Direct target availability is still too coarse for Q-Series closure. Even
inside one support-cell row, the mu-axis and sigma-axis direct-SD targets can
have different smoke outcomes, so the widget needs target-level evidence before
host escalation.
