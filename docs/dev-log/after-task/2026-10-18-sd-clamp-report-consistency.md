# After-task report: effective log-SD report consistency

## 1. Goal

Make TMB-reported group log SD, group SD, and public predictions agree when
the configured soft clamp is active.

## 2. Implemented

The general SD-regression worktree already contained the TMB change that stores
the soft-clamped log SD in `log_sd_mu_group` and exponentiates that same value
in five affected branches. The ZIP regression had demonstrated the original
failure before that change: the report returned 4.00 while the effective value
was 3.75. This follow-up adds a direct response-scale prediction assertion to
the existing clamp-active test. That test now compares the effective value
against the reported log SD, reported SD, link prediction, and response
prediction.

## 3a. Decisions and Rejected Alternatives

The test file passed lane preflight and was edited. Lane preflight found 61
refs with changes to `src/drmTMB.cpp` that are absent from this checkout. I did
not edit that shared file further. Its comment at line 42 still describes raw
predictor reporting and requires correction after path reconciliation. I did
not change the likelihood, model admission, or programme capability claims.

## 4. Files Touched

- `tests/testthat/test-zi-poisson-sd-regression.R`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-18-sd-clamp-report-consistency.md`
- This report

The TMB source changes described above pre-existed this follow-up in the
worktree and are not attributed to this test-only edit.

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-poisson-sd")'`
passed 33 expectations: 15 integration and 18 regression, with 0 failures,
warnings, or skips, in 62.2 seconds. No live Julia tests ran. The test checks
the ZIP pathway only and does not establish family-wide clamp consistency.

## 6. Tests of the Tests

The earlier clamp-active test was observed to fail before the TMB reporting
change: it expected the effective clamped log SD but received the raw value
4.00 instead of 3.75. The new response-scale assertion would fail if public
response prediction stopped matching the reported effective SD. The full
focused suite passes after the assertion was added.

## 7a. Issue Ledger

- Open: correct the stale TMB comment after reconciling the 61 missing refs
  reported by lane preflight.
- Open: audit clamp/report/prediction consistency across all SD-enabled family
  branches with targeted tests.
- Open: Bernoulli uncertainty calibration and all general-programme gates.

## 8. Consistency Audit

The focused ZIP test now checks both public prediction scales against the
effective value reported by TMB. The change does not alter the estimator or
the model's support boundary. The overarching programme ledger remains open
at G0 through G8; this report closes only the additional ZIP response-scale
assertion.

## 9. What Did Not Go Smoothly

The first lane-preflight invocation mishandled the repository path containing
spaces. After correcting the quoting, the test path was clear, while the C++
source path surfaced 61 missing refs. I left the shared C++ file untouched and
recorded the comment correction as owed.

## 10. Known Residuals

The stale comment at `src/drmTMB.cpp:42` remains. The focused test filter
exercises no live Julia engine. No full package suite, full family audit,
coverage calibration, or programme closeout is claimed.

## 11. Team Learning

For a report consistency repair, verify every public scale from the same
effective parameter and include an assertion on both link and response
prediction. Before editing a heavily shared source file, use path-level lane
preflight and reconcile missing refs rather than assuming the current checkout
is the only owner.

## 12. Cross-Product Coverage

This slice covers the native TMB zero-inflated Poisson random-effect SD report
and prediction consistency test. It does NOT cover other response families,
the Julia engine, structured effects, or interval calibration.

## Prose assessment

Naturalness assessment: the local slop checker found 0 hits in 603 words.
Scientific gate: this report makes no new scientific claim. Factual gate: the
test counts, duration, and pre-fix values are tied to retained local evidence.
Reference gate: no external references are used.
