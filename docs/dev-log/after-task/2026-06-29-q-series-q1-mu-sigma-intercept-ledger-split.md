# Q-Series q1 mu+sigma intercept ledger split

## 1. Goal

Split the four Gaussian low-q q1 `mu+sigma` intercept rows by their actual
local target-smoke evidence, without promoting any row to interval readiness,
coverage readiness, `inference_ready`, or `supported`.

## 2. Implemented

- Regenerated the Gaussian low-q row-selection sidecar after reading the q1
  `mu+sigma` intercept local target-smoke evidence.
- Marked the `phylo` q1 `mu+sigma` intercept row as
  `mu_sigma_smoke_diagnostic_blocked` because the local smoke has a nonusable
  boundary/correlation interval and warnings on all three targets.
- Marked `spatial`, `animal`, and `relmat` q1 `mu+sigma` intercept rows as
  `mu_sigma_smoke_fixture_review_pending` because their local target-smoke
  intervals were usable with no warning targets.
- Kept all four linked support cells at `point_fit/planned/planned`.
- Updated the mission-control validator and focused R test so the
  provider-specific split is enforced.
- Bumped the local dashboard build from `r146` to `r147`.

## 3a. Decisions and Rejected Alternatives

- Chose a provider-specific split instead of the old shared
  `local_smoke_completed_review_pending` bucket. The smoke evidence is not
  equivalent: `phylo` has a retained boundary/correlation blocker, while the
  other three providers have fixture-only passes.
- Did not promote the fixture-only rows. A local n=1 target smoke is not a
  replicated denominator, MCSE, or coverage grid.
- Kept direct `sd_mu`, direct `sd_sigma`, and `mu-sigma` correlation targets
  separate. The matched `mu+sigma` rows do not inherit q1 `mu`, q1 `sigma`, q2,
  q4/q8, non-Gaussian, REML, AI-REML, bridge, or public-support evidence.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-intercept-ledger-split.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- Row-selection status audit: 1 `mu_sigma_smoke_diagnostic_blocked`, 3
  `mu_sigma_smoke_fixture_review_pending`, 2
  `sigma_smoke_diagnostic_blocked`, 2
  `sigma_smoke_route_review_pending`, 4
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
  passed with 8544 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check -- tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `gh issue list --state open --search "q-series mu sigma" --limit 20`:
  passed and returned no open issues.
- `gh issue list --state open --search "Q-Series" --limit 20`: passed and
  returned no open issues.

## 6. Tests of the Tests

The validator now stores provider-specific expected status/run-mode pairs for
the four q1 `mu+sigma` intercept rows and checks the linked smoke sidecar
against the same split. If the row-selection TSV drifts back to the old shared
`local_smoke_completed_review_pending` bucket, mission control fails.

The focused R test now orders the four rows explicitly and checks the expected
status vector, run-mode vector, evidence URL, host gates, and claim-boundary
phrases. This was not a full mutation-test run, but the new assertions cover the
old failure class directly.

## 7a. Issue Ledger

- Fixed stale q1 `mu+sigma` row-selection wording that treated all four
  providers as one review bucket.
- No linked support cell was promoted; all four stay
  `point_fit/planned/planned`.
- `gh issue list --state open --search "q-series mu sigma" --limit 20`
  returned no open matching issue.
- `gh issue list --state open --search "Q-Series" --limit 20` returned no open
  matching issue requiring a comment for this bookkeeping slice.

## 8. Consistency Audit

Checked q1 `mu+sigma` rows across the row-selection sidecar, artifact mirror,
local smoke sidecar, support-cell links, mission-control validator, and focused
tests. The old single status is still allowed for other row classes, but no q1
`mu+sigma` intercept row uses it now.

Ran:

```sh
rg -n "local_smoke_completed_review_pending|mu_sigma_smoke_diagnostic_blocked|mu_sigma_smoke_fixture_review_pending|fisher_noether_rose_review_before_endpoint_denominator|fisher_noether_rose_boundary_correlation_review|fisher_noether_rose_endpoint_denominator_review|phylo nonusable boundary/correlation|spatial/animal/relmat fixture-only pass" \
  tools/validate-mission-control.py \
  tests/testthat/test-structured-re-conversion-contracts.R \
  tools/summarize-structured-re-gaussian-lowq-row-selection.R \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv \
  docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv
```

The remaining `local_smoke_completed_review_pending` hits are generic defaults
or neighbouring non-`mu+sigma` row classes, not the four q1 `mu+sigma`
intercept rows.

## 9. What Did Not Go Smoothly

The browser preview's page text contains many `r###` strings from dashboard
content, so a body-text scrape misread the build as `r475`. The authoritative
version file showed the served widget was `r146`; this patch bumps that file and
the HTML constant to `r147`.

## 10. Known Residuals

- No q1 `mu+sigma` intercept row is `inference_ready` or `supported`.
- The `phylo` q1 `mu+sigma` intercept row remains diagnostic-blocked pending
  Fisher/Noether/Rose review of the boundary/correlation interval.
- `spatial`, `animal`, and `relmat` q1 `mu+sigma` intercept rows remain
  fixture-review pending. They need endpoint-specific denominator and blocker
  rules before Totoro/FIIA, Nibi/Rorqual, or DRAC work.
- q1 `mu`, q1 `sigma`, q2, q4/q8, non-Gaussian intervals, REML, AI-REML, and
  support-tier claims remain separate unfinished arcs.

## 11. Team Learning

Matched endpoint rows need target-level evidence labels. A clean direct-SD
fixture smoke beside a nonusable correlation target should not collapse into one
generic "review pending" state; the next reviewer needs to see the blocker
shape immediately in the board.
