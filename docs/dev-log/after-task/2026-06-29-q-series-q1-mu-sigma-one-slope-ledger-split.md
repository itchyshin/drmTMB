# Q-Series q1 mu+sigma one-slope ledger split

## 1. Goal

Split the four Gaussian low-q q1 `mu+sigma` one-slope row-selection states by
their target-level diagnostic evidence, without promoting any row to interval
readiness, coverage readiness, `inference_ready`, or `supported`.

## 2. Implemented

- Regenerated the Gaussian low-q row-selection sidecar after reviewing the
  q1 `mu+sigma` one-slope readiness, interval-diagnostic, and stability-probe
  sidecars.
- Marked `phylo` as `mu_sigma_slope_mixed_interval_review_pending`.
- Marked `spatial` as `mu_sigma_slope_spatial_boundary_blocked`.
- Marked `animal` as `mu_sigma_slope_bootstrap_boundary_blocked`.
- Marked `relmat` as `mu_sigma_slope_profile_failure_review_pending`.
- Kept all four linked support cells at `point_fit/planned/planned`.
- Updated mission-control validation and the focused R dashboard contract test
  so the provider-specific split is enforced.
- Bumped the local dashboard build from `r147` to `r148`.

## 3a. Decisions and Rejected Alternatives

- Chose four row-specific statuses instead of the shared
  `interval_diagnostic_completed_review_pending` bucket. The evidence shape is
  different by provider: `spatial` has a strong-probe boundary/nonfinite
  blocker, `animal` has all four diagnostic targets as bootstrap-only boundary
  rows, `relmat` has a profile-failure target, and `phylo` is mixed
  finite/bootstrap-boundary.
- Did not treat the target-level diagnostic sidecars as coverage evidence.
- Did not use q1 `mu`, q1 `sigma`, q2, q4/q8, non-Gaussian, REML, AI-REML, or
  bridge evidence by analogy.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-one-slope-ledger-split.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- Row-selection status audit: 1
  `mu_sigma_slope_bootstrap_boundary_blocked`, 1
  `mu_sigma_slope_mixed_interval_review_pending`, 1
  `mu_sigma_slope_profile_failure_review_pending`, 1
  `mu_sigma_slope_spatial_boundary_blocked`, 1
  `mu_sigma_smoke_diagnostic_blocked`, 3
  `mu_sigma_smoke_fixture_review_pending`, 2
  `sigma_smoke_diagnostic_blocked`, 2
  `sigma_smoke_route_review_pending`, 5 `ready_for_totoro_fiia_smoke`, 4
  `totoro_fiia_smoke_operational_hold`, 1
  `direct_sd_contract_banked_review_pending`, and 1
  `phylo_interaction_contract_banked_review_pending`.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8547 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check -- tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `gh issue list --state open --search "q-series mu sigma one slope" --limit 20`:
  passed and returned no open issues.
- `gh issue list --state open --search "mu sigma slope" --limit 20`: passed
  and returned broad slope/capability issues, but none requiring a
  bookkeeping comment for this ledger split.

## 6. Tests of the Tests

The validator now stores provider-specific expected status/run-mode pairs for
the four q1 `mu+sigma` one-slope rows. The focused R test orders the four rows
explicitly and checks their status vector, run-mode vector, evidence URL, host
gates, target names, and claim-boundary phrases. If the row-selection TSV drifts
back to `interval_diagnostic_completed_review_pending`, both gates fail.

This was not a full mutation-test run, but the assertions cover the exact stale
single-bucket failure this slice fixed.

## 7a. Issue Ledger

- Fixed stale q1 `mu+sigma` one-slope row-selection wording that treated all
  four providers as one diagnostic-review bucket.
- No linked support cell was promoted; all four stay
  `point_fit/planned/planned`.
- `gh issue list --state open --search "q-series mu sigma one slope" --limit 20`
  returned no open matching issue.
- `gh issue list --state open --search "mu sigma slope" --limit 20` found
  broader issues, including #33, but this bookkeeping slice did not need an
  issue comment.

## 8. Consistency Audit

Checked q1 `mu+sigma` one-slope rows across row-selection, artifact mirror,
readiness, interval-diagnostic, stability-probe, support-cell links,
mission-control validation, and focused tests. The shared
`interval_diagnostic_completed_review_pending` status no longer applies to the
four q1 `mu+sigma` one-slope rows.

Ran:

```sh
rg -n "interval_diagnostic_completed_review_pending|mu_sigma_slope_mixed_interval_review_pending|mu_sigma_slope_spatial_boundary_blocked|mu_sigma_slope_bootstrap_boundary_blocked|mu_sigma_slope_profile_failure_review_pending" \
  tools/validate-mission-control.py \
  tests/testthat/test-structured-re-conversion-contracts.R \
  tools/summarize-structured-re-gaussian-lowq-row-selection.R \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv
```

Remaining `interval_diagnostic_completed_review_pending` hits belong to other
historical or neighbouring rows, not the four q1 `mu+sigma` one-slope rows.

## 9. What Did Not Go Smoothly

The first row-selection split exposed that the next generic bucket had the same
problem: a single tidy status was hiding provider-specific blocker shapes. The
extra audit was worthwhile, but it meant a second focused test and dashboard
build bump.

## 10. Known Residuals

- No q1 `mu+sigma` one-slope row is `inference_ready` or `supported`.
- `spatial` remains boundary-blocked before any replicated smoke or cluster
  denominator work.
- `animal` needs Fisher/Noether/Rose review of the all-bootstrap-boundary target
  pattern before any smoke design.
- `phylo` and `relmat` need mixed-target review before interval-channel or
  denominator decisions.
- Totoro/FIIA, Nibi/Rorqual, DRAC, q2, q4/q8, non-Gaussian intervals, REML,
  AI-REML, and support-tier claims remain separate unfinished arcs.

## 11. Team Learning

Every "diagnostic review pending" bucket should be treated as suspicious once
target-level sidecars exist. The support-cell board is more useful when it names
the blocker shape directly: boundary, bootstrap-only, profile failure, or mixed
target review.
