# Arc 1a REML reference fit no longer ends on L-BFGS-B code 52

## 1. Goal

Stop `test-reml-structured-location.R` failing on Linux with
`reference$convergence` equal to 52 (issue #1592). The failing side is the
independent reference fit in `arc1a_reml_reference()`, not the drmTMB fit.

## 2. Implemented

The reference fit still starts with `stats::optim(method = "L-BFGS-B")`. When
that returns a non-zero code, it is polished from where it stopped with
`stats::nlminb()` under the same bounds. The polished result is used only if its
objective is no worse than the L-BFGS-B value, so the reference cannot move away
from the restricted-likelihood optimum.

## 3a. Decisions and Rejected Alternatives

Reproduced by switching the container to OpenBLAS with
`OPENBLAS_NUM_THREADS=1`: the spatial one-slope fixture then returns code 52,
while the objective (118.416415197) and the SDs match the passing runs. So the
optimum is right and only the line search ends abnormally. The drmTMB
expectations were not loosened and no assertion was dropped. Tighter `factr`
or `pgtol` were not tried: they would not change how the line search ends.

## 4. Files Touched

`tests/testthat/test-reml-structured-location.R` only (reference helper and one
new test). No package code.

## 5. Checks Run

Single-threaded OpenBLAS, R 4.3.3: the new test fails before the change (code 52,
spatial one_slope) and passes after (12 expectations). The whole file passes with
`NOT_CRAN=true`, including the TMB-versus-reference comparisons. With four BLAS
threads and with the reference BLAS the reference fit returned code 0 before and
after.

## 6. Tests of the Tests

The new test is not gated by `skip_fragile_recovery()` and does not fit a TMB
model, so it runs on CI.

## 7a. Issue Ledger

Closes #1592.

## Supplemental Closeout (2026-10-22)

### Goal

Complete the repository closeout record for merged PR #1604 and issue #1592.

### Implemented

Added the missing append-only check-log entry and this supplement. No package
source or test code changed in this follow-up.

### Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-20-reml-reference-lbfgsb-code52.md`

### Checks Run

- Verified PR #1604 head `d4885b8ad50f4847c8f3970b7fbad37235f1ab8f`, merge
  commit `7820315cc904358edbf3635515ebd3a73dbb7f31`, and closure of issue
  #1592 through GitHub metadata.
- Verified exact-head run 39356960210 completed successfully: OS matrix,
  source-tree blind-spot job, and Ubuntu release shards 1/4 through 4/4.
- Verified post-merge `receipt-staleness` run 39817151100 was pending at the
  time of this check.
- `git diff --check` passed. The current clone has no after-task report
  checker, so the required sections were checked manually against
  `docs/design/10-after-task-protocol.md`. No package tests were rerun here;
  the historical test results remain attributed to the original PR.

### Tests Of The Tests

The original PR report states that the new test reproduces code 52 under
single-threaded OpenBLAS before the change and passes after it, is not behind
`skip_fragile_recovery()`, and does not fit a TMB model. This supplement did not
rerun that test; the source-tree and release checks above are exact-head CI
receipts, not independent statistical validation.

### Consistency Audit

Compared the task report with current repository instructions and the merged PR
metadata. The report distinguishes the independent reference optimizer from the
drmTMB fit, keeps test evidence attributed to its recorded environment, and
does not claim that the pending post-merge workflow passed. No README, NEWS,
vignette, generated site, model contract, or package behavior changed, so no
user-facing documentation or capability inventory update applies. The design
record itself is updated by this supplement and the check-log entry; pkgdown
navigation and content do not need updating.

### What Did Not Go Smoothly

The original PR was merged without the required `docs/dev-log/check-log.md`
entry, and its after-task report did not cover the complete closeout checklist.
This follow-up repairs the record after merge.

### Team Learning

For the next PR batch, require each completed R PR to include its check-log
entry and a report that distinguishes exact-head CI, local targeted tests, and
post-merge checks before marking it ready.

### Design and pkgdown Updates

No design contract or pkgdown page changed because the implementation and
user-facing behavior are unchanged. This report and the append-only check log
are the appropriate record updates.

### GitHub Issue Maintenance

Issue #1592 was closed by PR #1604. No new issue or comment is needed for this
record-only follow-up.

### Known Limitations

The post-merge receipt-staleness workflow was pending when checked. This
follow-up changes documentation only and provides no new package test,
recovery, interval, or release evidence.

### Next Actions

Check run 39817151100 on `main` before treating the post-merge receipt gate as
settled. Issue #1592 is already closed by #1604; no issue edit is needed.
