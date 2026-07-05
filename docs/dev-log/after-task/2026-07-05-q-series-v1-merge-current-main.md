# After Task: Q-Series v1 Merge Current Main

## 1. Goal

Bring `drmtmb/fix-family-conventions` up to current `origin/main` so the
Q-Series v1 work is reviewable on the latest mainline package state.

## 2. Implemented

Ran a non-destructive merge preview first:

```sh
git merge-tree --write-tree --messages HEAD origin/main
```

The preview reported no conflicts. Then `origin/main` was merged into
`drmtmb/fix-family-conventions` with `git merge --no-edit origin/main`.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Merge current `origin/main` into the feature branch rather than continuing to
  add Q-Series work on a stale base.
- Validate the Q-Series release tooling and focused Q-Series tests after the
  merge.
- Treat the merge as branch-integration work only.

Rejected alternatives:

- Do not force-push or rewrite the branch.
- Do not change Q-Series support-cell status as part of the merge.
- Do not run coverage grids or host compute; the merge needed integration
  validation, not new evidence.

## 3b. Mathematical Contract

This task changed no likelihood, covariance, estimator, or interval rule. The
Q-Series row accounting remains:

```text
Practical v1.0 surface: 91/104 (87.5%)
Rows to 90%: 3
Exact inference_ready anchors: 8/104
Supported authority: 0/104
```

## 4. Files Touched

The merge imported the current `origin/main` changes into the branch. The
local audit update touched:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-05-q-series-v1-merge-current-main.md`

## 5. Checks Run

- `git merge-tree --write-tree --messages HEAD origin/main`: reported no
  conflicts.
- `python3 -m py_compile tools/qseries_v1_release_check.py
  tools/validate-mission-control.py tools/qseries_v1_claim_guard.py`: passed.
- `python3 tools/qseries_v1_release_check.py --summary --check-report
  --check-candidates`: passed with practical v1.0 surface 91/104 (87.5%),
  `rows_to_90=3`, and `ninety_economy_rows=3`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'count-structured-mu', reporter = 'summary')"`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'nongaussian-structured-boundary', reporter =
  'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true
  /Library/Frameworks/R.framework/Resources/bin/Rscript --no-init-file -e
  "Sys.setenv(NOT_CRAN='true', OMP_NUM_THREADS='1',
  OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1');
  devtools::test(filter = 'structured-re-conversion-contracts', reporter =
  'summary')"`: passed.
- `git diff --check HEAD^..HEAD`: passed.

## 6. Tests of the Tests

The focused tests cover the Q-Series release ledger/checker, Mission Control
contracts, count structured-`mu` routes, and the non-Gaussian structured
boundary smoke. These are the row-accounting and boundary surfaces most likely
to break during a merge with current main.

## 7a. Issue Ledger

No GitHub issue was opened, commented on, or closed in this slice. This was a
local branch-integration step.

## 8. Consistency Audit

Rose audit: the merge did not change Q-Series support-cell status, practical
surface counts, `inference_ready`, or `supported` authority.

Fisher audit: no coverage jobs or interval promotions were authorized.

Gauss audit: current-main TMB changes merged without conflicts, and the focused
count/non-Gaussian tests still pass.

Noether audit: row accounting and claim boundaries remain generated from the
same support-cell and ledger sources.

Grace audit: after the merge, `git rev-list --left-right --count
origin/main...HEAD` reports `0 20`, so the feature branch is current with
main and 20 commits ahead.

## 9. What Did Not Go Smoothly

The first merge-preview command used an unsupported `git merge-base --short`
form on this Git build. It changed no files. Rerunning the preview with
supported commands gave the needed no-conflict signal.

## 10. Known Residuals

- The feature branch still needs PR creation or update after push.
- Practical surface remains 91/104, not 90%.
- The next three rows to 90% still need design or route work before movement.

## 11. Team Learning

For this branch, merge-preview first was worth the few seconds: the feature
branch touched many of the same core files as current main, but the actual
merge was clean and the Q-Series validation suite stayed green.
