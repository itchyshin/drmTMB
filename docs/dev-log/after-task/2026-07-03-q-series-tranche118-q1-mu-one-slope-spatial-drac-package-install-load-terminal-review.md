# Q-Series Tranche 118: q1 mu one-slope spatial DRAC package-install/load terminal review

## 1. Goal

Bank the terminal review for the one permitted no-model Rorqual package-install/load proof after T117, without turning a failed source-SHA guard into package-install, package-load, model, denominator, coverage, admission, or support-cell evidence.

## 2. Implemented

- Added the T118 Mission Control sidecar:
  `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche118-spatial-drac-package-install-load-terminal-review.tsv`.
- Added terminal-review artifacts under
  `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche118-spatial-drac-package-install-load-proof/`.
- Updated Mission Control build `r312`, the q1 `mu` one-slope queue, member-discussion rows, the strict validator, focused conversion-contract tests, dashboard README, completion map, and check-log.

## 3a. Decisions and Rejected Alternatives

T118 is a terminal review of exactly one allocation-safe no-model Rorqual job, `15108138`. The job allocated on `rc32123` and failed with exit `128:0` after five seconds at the source-SHA guard because the packet used `git rev-parse` inside a staged source snapshot that is not a git checkout. I did not submit a replacement job, broaden compute, run a smoke runner, pool denominators, or promote the support cell.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche118-spatial-drac-package-install-load-terminal-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche118-spatial-drac-package-install-load-proof/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

Final validation is recorded in `docs/dev-log/check-log.md`. The required checks are TSV width scan, Python compile, R parse of the focused conversion-contract test file, dashboard JavaScript `node --check`, Mission Control validation, focused conversion-contract tests, support-cell invariant scan, served dashboard version check, after-task checker, and `git diff --check`.

## 6. Tests of the Tests

The focused conversion-contract test now has a dedicated T118 block that checks row identity, exact failed-before-install statuses, Slurm job `15108138`, `sacct` failure on `rc32123`, `scontrol` submission provenance, Slurm stderr, empty remote proof directory, queue latest-evidence routing, member-board review, and unchanged support-cell status.

## 7a. Issue Ledger

- T118 is not package-install success and is not `library(drmTMB)` success.
- T118 produced zero completed model replicates, zero retained denominators, and zero interval or coverage observations.
- The failure taxonomy is source-provenance handling: future packets must read `SOURCE-PROVENANCE.tsv` when git metadata are absent.

## 8. Consistency Audit

Rose audit boundary: no `inference_ready`, no `supported`, no q4/q8 claim, no coverage, no public support, no REML/AI-REML claim, and no denominator pooling. Fisher boundary: the denominator remains zero because the job stopped before any model command. Gauss boundary: the next packet must fail closed around source provenance before attempting `R CMD INSTALL`. Grace boundary: host provenance stays separated as submission host `rorqual2`, allocation host `rc32123`, and job `15108138`.

## 9. What Did Not Go Smoothly

The T117 packet assumed the staged source directory was a git checkout. On Rorqual it is a source snapshot, so `git rev-parse` failed before the packet could write structured proof files or reach `R CMD INSTALL`. That is why the next tranche is a no-compute packet review, not another allocation.

## 10. Known Residuals

The q1 `mu` one-slope spatial support cell remains `point_fit/planned/planned`. The next meaningful task is T119 no-compute source-provenance fallback packet review. T119 must patch the future package-install/load packet to read `SOURCE-PROVENANCE.tsv` when git metadata are absent and still stop before any smoke runner, model formula, model fit, retained denominator, coverage, top-up, or support-cell status edit.

## 11. Team Learning

Snapshot provenance and git-checkout provenance need separate guards. A cheap source-provenance fallback review can prevent repeated allocation failures while preserving Kim's rule: spend only the compute needed to make the next decision honest.
