# After Task: Q-Series q1 sigma intercept route contract

## 1. Goal

Replace the vague Gaussian low-q q1 `sigma` intercept hold with an exact
route contract for the four provider rows, without running compute and without
promoting any Q-Series support-cell status.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian low-q q1
`sigma`-intercept route-contract channel, with a local n=5 direct sigma-SD
smoke planned and all attempted rows retained. It does not claim
`interval_status`, `coverage_status`, `inference_ready`, `supported`, the
location-axis bias+t correction, q1 `mu`, matched `mu+sigma`, q2, q4/q8,
non-Gaussian intervals, REML, AI-REML, broad bridge support, or public support.

Added
`docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv`
with one route row for each q1 `sigma` intercept support cell:

- `qseries_phylo_q1_sigma_intercept`;
- `qseries_spatial_q1_sigma_intercept`;
- `qseries_animal_q1_sigma_intercept`;
- `qseries_relmat_q1_sigma_intercept`.

The contract pins the candidate first interval channel to direct structured-SD
targets under raw uncorrected log-SD Wald-z intervals with
`small_sample_df = "none"` and `bias_correct = "none"`. Endpoint profiles are
diagnostic-only boundary triage. The direct targets are:

- `sd:sigma:phylo(1 | species)`;
- `sd:sigma:spatial(1 | site)`;
- `sd:sigma:animal(1 | id)`;
- `sd:sigma:relmat(1 | id)`.

Regenerated the Gaussian low-q row-selection sidecar and artifact mirror so the
four rows now point at this route contract and wait for a local n=5 direct
sigma-SD smoke before Totoro/FIIA, Nibi/Rorqual, denominator, or status work.
The linked support cells remain `point_fit/planned/planned`.

Updated mission-control validation and the widget to show a "Low-q sigma route"
summary card, row-level `sigma route` links, and a compact contract table.
Dashboard version is now `r138`.

## 3a. Decisions and Rejected Alternatives

Decision: do not reuse the location-axis small-sample bias+t correction. The
sigma route is raw log-SD Wald-z first, with endpoint profiles retained as a
diagnostic channel.

Decision: do not borrow the matched `mu+sigma` smoke. The sigma-only route
keeps only the direct sigma SD target for each provider; matched `mu+sigma`
correlations remain separate.

Decision: keep Nibi/Rorqual/DRAC blocked for this lane. The next executable
step is a local n=5 route smoke with all attempted rows retained.

Rejected alternatives:

- Do not call the route contract interval evidence.
- Do not change any support-cell `interval_status` or `coverage_status`.
- Do not use sigma one-slope `inference_ready` evidence as an intercept-row
  promotion.
- Do not use finite-subset coverage after boundary censoring as retained
  coverage.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-intercept-route-contract.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed; wrote 23 Gaussian low-q row-selection rows and the matching artifact
  mirror.
- `/opt/homebrew/bin/air format
  tools/summarize-structured-re-gaussian-lowq-row-selection.R
  tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-intercept-route-contract.md')"`:
  passed with `after-task structure check passed`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed with 8302 PASS / 0 FAIL /
  0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 5 inference-evidence summary rows, and 4
  Gaussian low-q sigma-intercept route-contract rows.
- `git diff --check`: passed.

## 6. Tests of the Tests

Mission control now requires exactly four sigma-intercept route-contract rows,
exact provider/cell/target linkage, linked support cells at
`point_fit/planned/planned`, row-selection status
`route_contract_ready_local_smoke_pending`, raw log-SD Wald channel wording,
endpoint-profile diagnostic wording, retained boundary/finite-subset
denominator language, and no-promotion claim boundaries.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control contract update for the active Q-Series board.

## 8. Consistency Audit

Checked the support-cell TSV, Gaussian low-q row-selection sidecar, sigma
one-slope inference evidence, spatial sigma boundary diagnostic, dashboard
renderer, dashboard README, and validator patterns before editing.

The board remains 104 rows. The five current `inference_ready` rows remain
unchanged. The four q1 `sigma` intercept rows remain
`point_fit/planned/planned`.

## 9. What Did Not Go Smoothly

Rose could not be launched as a separate subagent because the thread limit was
full. I performed the systems-audit guard locally and kept Rose as
`manual_audit_required_before_status_claim` in the sidecar instead of pretending
there was a standing status sign-off.

## 10. Known Residuals

The next executable slice is a local n=5 direct sigma-SD smoke runner or
adaptation that records fit, convergence, `pdHess`, target inventory, Wald
status, endpoint-profile status, boundary flags, one-sided misses, warnings,
seed manifest, session information, and git SHA.

Totoro/FIIA, Nibi/Rorqual, retained-denominator grids, and any status promotion
remain blocked until the local smoke exists and Fisher/Gauss/Rose review it.

## 11. Team Learning

A route contract is useful progress only when it is visibly not a status claim.
For scale-side rows, the safest dashboard signal is separate from
`interval_status` and `coverage_status`, with the no-bias-correction decision
encoded in both the sidecar and the validator.
