# After Task: Q-Series evidence-link hygiene

## 1. Goal

Fix row-level evidence-link drift for promoted Q-Series rows and make the newest
check-log state discoverable from the file tail, without changing any support
cell status.

## 2. Implemented

This promotes exactly no Q-Series row under the evidence-link hygiene channel,
with source-of-truth support-cell and inference-summary URL consistency
checking, and does not claim new interval reliability, coverage,
`inference_ready`, `supported`, q4/q8 readiness, REML, AI-REML, bridge support,
non-Gaussian intervals, or public support.

Updated the two q2 `inference_ready` support-cell rows,
`qseries_phylo_q2_mu1_mu2_one_slope` and
`qseries_relmat_q2_mu1_mu2_one_slope`, so their primary `evidence_url` points
to `docs/design/219-structured-re-small-sample-bias-correction.md` instead of
the q2 parity-fixture sidecar. The row still records fixture parity in the
bridge column; the evidence link now matches the interval/coverage basis of
the promoted status.

Added a validator guard requiring every support-cell row with a matching
`structured-re-q-series-inference-evidence-summary.tsv` row to use the same
primary evidence URL as that inference summary. Updated the focused
structured-RE conversion tests accordingly.

## 3a. Decisions and Rejected Alternatives

Decision: keep the q2 support-cell `denominator_policy` as
`fixture_not_coverage`. The promoted q2 rows still combine exact point/fixture
evidence with the separate small-sample interval calibration evidence; they are
not generic coverage sidecar rows and they are still not `supported`.

Rejected alternatives:

- Do not promote spatial q2 or animal q2 by analogy.
- Do not move any q4/q8 row from diagnostic/planned/stability-blocked status.
- Do not use DRAC, Totoro, FIIA, Nibi, or Rorqual for this hygiene task.
- Do not rewrite historical check-log entries that were true when written.

## 3b. Mathematical Contract

No likelihood, estimator, interval formula, TMB parameterization, denominator,
or simulation result changed. The default location-axis bias+t correction and
its claim boundary remain the same as documented in design note 219.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-evidence-link-hygiene.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format
  tests/testthat/test-structured-re-conversion-contracts.R
  tools/validate-mission-control.py`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 structured RE q-series cells and 5
  structured RE q-series inference-evidence summary rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 7199 PASS / 0 FAIL / 0 WARN /
  0 SKIP after updating the second q2 parity-fixture expectation.
- `git diff --check`: passed.
- Promoted-row URL audit: all five rows with
  `interval_status = coverage_status = inference_ready` matched their
  `structured-re-q-series-inference-evidence-summary.tsv` evidence URLs.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-evidence-link-hygiene.md')"`:
  passed.
- Removed the `tools/__pycache__` directory created by `py_compile`; a follow-up
  `find . -type d -name '__pycache__' -print` returned no paths.

## 6. Tests of the Tests

The first focused test run failed in the older q2 parity-fixture expectation
because it still expected promoted phylo/relmat q2 rows to point to the parity
fixture. Updating that expectation made the test exercise the intended drift
guard rather than merely matching the stale URL.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was local
mission-control ledger hygiene inside the active Q-Series evidence board.

## 8. Consistency Audit

The five current `inference_ready` support-cell rows now point at the same
primary evidence URLs as the five-row inference evidence summary: sigma rows
point to `structured-re-sigma-slope-inference-evidence.tsv`, and q2 rows point
to design note 219. The q2 bridge status remains `fixture_parity`; only the
primary row evidence link changed.

The check-log now has a tail-visible checkpoint that records this hygiene pass
and repeats the current no-compute boundary for q4/q8, Gaussian q1 `mu`
one-slope, spatial sigma, and non-Gaussian rows.

## 9. What Did Not Go Smoothly

The first focused test run exposed a second stale q2 URL expectation deeper in
the parity-fixture test. That was useful: it confirmed the test suite was still
capable of catching row-level evidence-link drift.

## 10. Known Residuals

Q-Series remains evidence-incomplete. The board still has exactly five
`inference_ready` rows and no `supported` structured row. Gaussian q1 `mu`
one-slope rows remain blocked by interval-shape and upper-tail miss issues,
spatial q1 `sigma` remains finite-Wald boundary blocked, q4/q8 remain
diagnostic/planned/stability-blocked, and non-Gaussian rows remain
recovery-only, rejected, or planned.

## 11. Team Learning

For promoted status rows, the support-cell evidence URL should point at the
evidence that justifies the promotion, while fit/bridge evidence stays visible
through separate sidecars. Rose's tail-check also caught a practical workflow
issue: a future agent should be able to run `tail docs/dev-log/check-log.md`
and see the latest checkpoint.

## 12. Next Actions

Follow Fisher's recommendation: do not launch a broad DRAC/Totoro promotion
campaign now. The next scientific tranche is local interval-shape diagnostics
for Gaussian q1 `mu` one-slope rows, especially phylo, spatial, and relmat
where SR475 MCSE is already adequate but one-sided misses remain blocked.
