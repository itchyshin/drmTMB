# Q-Series q1 sigma smoke ledger split

## 1. Goal

Split the four Gaussian low-q q1 `sigma` intercept rows by their actual local
smoke evidence, without promoting any Q-Series row to interval or coverage
readiness.

## 2. Implemented

- Regenerated the Gaussian low-q row-selection sidecar after the local q1
  `sigma` smoke.
- Marked `phylo` and `spatial` q1 `sigma` intercept rows as
  `sigma_smoke_diagnostic_blocked` because their retained local smoke rows have
  boundary/profile/nonusable-interval signals.
- Marked `animal` and `relmat` q1 `sigma` intercept rows as
  `sigma_smoke_route_review_pending` because their raw-Wald intervals were
  usable in the local smoke but all five replicates retained warnings.
- Updated the support-cell and Gaussian low-q audit wording so the rows point at
  the local q1 `sigma` smoke sidecar and keep `point_fit/planned/planned`.
- Updated mission-control validation and focused R tests so the provider split
  is enforced instead of the stale single `local_smoke_completed_review_pending`
  bucket.
- Bumped the dashboard build from `r145` to `r146`.

## 3a. Decisions and Rejected Alternatives

- Chose a provider-specific split instead of one shared q1 `sigma` status. The
  smoke evidence is different: `phylo`/`spatial` have boundary/profile blockers,
  while `animal`/`relmat` are cleaner but still warning-gated.
- Kept the interval channel as raw log-SD Wald with `small_sample_df=none` and
  `bias_correct=none`; the location-axis bias+t correction was not applied to
  sigma.
- Did not promote `animal` or `relmat` q1 `sigma` to `inference_ready`, because
  the local n=5 smoke is not a denominator or coverage grid.
- Did not use q1 `mu`, q2 slope, q4/q8, or non-Gaussian evidence by analogy.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-smoke-ledger-split.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- Row-selection status audit: 2 `sigma_smoke_diagnostic_blocked`, 2
  `sigma_smoke_route_review_pending`, 4
  `local_smoke_completed_review_pending`, 4
  `interval_diagnostic_completed_review_pending`, 5
  `ready_for_totoro_fiia_smoke`, 4 `totoro_fiia_smoke_operational_hold`, 1
  `direct_sd_contract_banked_review_pending`, and 1
  `phylo_interaction_contract_banked_review_pending`.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8542 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check -- docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/index.html docs/dev-log/dashboard/version.txt`:
  passed.

## 6. Tests of the Tests

Mission control failed before the validator was updated, reporting that the four
q1 `sigma` row-selection rows still had to be
`local_smoke_completed_review_pending` with the stale
`fisher_gauss_rose_review_before_host_escalation` run mode. The new validator
expects the provider-specific split and fails if those rows drift back.

The focused R test now asserts the four q1 `sigma` smoke summaries, linked
support-cell statuses, low-q audit rows, evidence URLs, and provider-specific
row-selection statuses. A first rerun exposed a missing `lowq` fixture read in
the test itself; after fixing that setup bug, the focused file passed.

## 7a. Issue Ledger

- Fixed stale q1 `sigma` row-selection wording that treated all four providers
  as one review bucket.
- Fixed low-q audit wording so all four q1 `sigma` rows say
  `point/fixture evidence only` and no interval/coverage promotion.
- `gh issue list --state open --search "q-series sigma smoke q1" --limit 20`
  returned no open matching issue.
- `gh issue list --state open --search "Q-Series" --limit 20` returned no open
  matching issue requiring a comment for this bookkeeping slice.

## 8. Consistency Audit

Checked q1 `sigma` rows across support cells, Gaussian low-q audit,
row-selection, local smoke sidecar, route-contract sidecar, mission-control
validator, and focused tests. The linked support-cell statuses remain
`point_fit/planned/planned`.

Ran:

```sh
rg -n "local_smoke_completed_review_pending|fisher_gauss_rose_review_before_host_escalation|sigma_smoke_diagnostic_blocked|sigma_smoke_route_review_pending|point/fixture evidence plus local sigma-smoke diagnostics only|r145" \
  tools/validate-mission-control.py \
  tests/testthat/test-structured-re-conversion-contracts.R \
  tools/summarize-structured-re-gaussian-lowq-row-selection.R \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv \
  docs/dev-log/dashboard/index.html \
  docs/dev-log/dashboard/version.txt \
  docs/dev-log/check-log.md
```

The old q1 `sigma` single-bucket labels no longer appear on the q1 `sigma`
rows. Remaining `local_smoke_completed_review_pending` hits belong to other
row classes, and remaining `r145` hits are historical check-log text.

## 9. What Did Not Go Smoothly

The first focused R rerun failed because the new q1 `sigma` assertion block
referenced `lowq` without reading the low-q audit table in that test. The
failure was useful: it showed the test was actually executing the new
cross-table checks.

## 10. Known Residuals

- No q1 `sigma` row is `inference_ready` or `supported`.
- `phylo` and `spatial` q1 `sigma` remain diagnostic-blocked pending
  Fisher/Gauss/Rose review of boundary/profile/warning behavior.
- `animal` and `relmat` q1 `sigma` remain route-review pending; their warning
  replicates need review before any Totoro/FIIA repeat or denominator design.
- Totoro/FIIA smoke, Nibi/Rorqual/DRAC denominator work, q4/q8 inference, and
  non-Gaussian interval work remain separate unfinished Q-Series arcs.

## 11. Team Learning

Local smoke outcomes need provider-specific status labels when blocker shapes
differ. A single "review pending" bucket made the board look cleaner, but it hid
the practical next decision: boundary/profile repair for `phylo`/`spatial`
versus warning-route review for `animal`/`relmat`.
