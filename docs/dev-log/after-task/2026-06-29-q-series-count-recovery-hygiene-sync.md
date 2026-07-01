# After Task: Q-Series count recovery hygiene sync

## 1. Goal

Sync the current Q-Series design narrative with the existing non-Gaussian count
recovery evidence without promoting any row beyond recovery-only status.

## 2. Implemented

This promotes exactly no Q-Series row under the non-Gaussian count recovery
hygiene channel, with existing 80-rep recovery sidecars and planned-coverage
denominator accounting, and does not claim interval reliability, coverage,
`inference_ready`, `supported`, bridge support, q2/q4 count covariance, REML,
AI-REML, structured count scale routes, zero-inflated structured effects, or
public support.

Updated `docs/design/218-structured-q-series-completion-map.md` so the current
count one-slope paragraph no longer says calibrated recovery is
`designed_not_run` after the local 80-rep recovery sidecar was banked. The
paragraph now separates the earlier execution-contract sidecars from the
executed local micro-shards and 80-rep recovery grid.

## 3a. Decisions and Rejected Alternatives

Decision: leave the historical check-log and fixture/recovery contract sidecar
language intact where it records the earlier state. Those entries were true
when written and are superseded by later sidecars, dashboard README text, and
this design-map correction.

Rejected alternatives:

- Do not relabel non-Gaussian recovery evidence as interval or coverage
  evidence.
- Do not promote the fixed-covariance spatial NB2 row to a clean-Hessian claim;
  it retains the 2/80 `pdHess = FALSE` Hessian caveat.
- Do not spend Totoro, Nibi, Rorqual, or FIIA on count interval coverage from
  this hygiene edit.

## 3b. Mathematical Contract

No likelihood, estimator, formula grammar, TMB parameterization, interval
channel, or coverage denominator changed. The synced rows remain q1
non-Gaussian structured `mu` one-slope recovery rows for Poisson and NB2
providers. Recovery means point-fit convergence, finite estimates, and SD
bias/RMSE summaries only.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-recovery-hygiene-sync.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series
  cells, 18 structured RE non-Gaussian recovery-rollup rows, and 8 structured
  RE count-slope recovery-results rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 7199 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- `git diff --check`: passed.
- ``rg -n 'calibrated recovery remains `designed_not_run`|count.*recovery.*designed_not_run|native_fixture_banked.*designed_not_run'
  docs/design/218-structured-q-series-completion-map.md
  docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md vignettes R
  tests``: no matches in current status surfaces.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-count-recovery-hygiene-sync.md')"`:
  passed after the required section names were synced.

## 6. Tests of the Tests

No new test file was needed. The existing structured-RE conversion contract test
already checks that a recovery row with positive `pdhess_false` cannot claim
`pdHess clean`, and that the clean rows keep their row-specific clean-Hessian
claim explicit.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
documentation/status hygiene sync inside the active Q-Series evidence board.

## 8. Consistency Audit

The dashboard README, count recovery sidecar, non-Gaussian recovery rollup,
mission-control validator, and focused test agree on the current boundary:
count recovery is recovery-only evidence. The spatial NB2 one-slope row has
80/80 fit_ok and finite estimates but 2/80 `pdHess = FALSE`, so it carries a
Hessian caveat rather than a clean-Hessian claim.

The stale-wording scan found historical `designed_not_run` language in older
check-log/report entries and in the fixture/recovery contract sidecar. Those
surfaces document earlier execution-contract state and were not rewritten.

## 9. What Did Not Go Smoothly

The current design map had one sentence that blended the old
fixture/recovery-contract state with the later executed 80-rep grid. The fix was
small, but it is exactly the kind of status drift that can make the widget look
more complete or less complete than it really is.

One stale-wording scan was first run with shell-interpreted backticks and failed
before searching. It was rerun with safe quoting and found no current-surface
matches.

## 10. Known Residuals

The non-Gaussian count rows remain recovery-only. They do not support intervals,
coverage, q2/q4 count covariance, REML, AI-REML, structured count scale routes,
zero-inflated structured effects, bridge parity, or public support.

## 11. Team Learning

Rose's rule applies well here: when a recovery sidecar graduates from contract
to executed evidence, the current design map needs a follow-up pass even if the
dashboard and validator are already correct.

## 12. Next Actions

Continue Q-Series completion through exact row-level gates. Use Totoro/FIIA only
for rehearsal and reserve Nibi/Rorqual/DRAC runs for stable denominators with
raw replicate artifacts, seed manifests, scheduler logs, and a predeclared
claim boundary.
