# Q-Series q1 sigma row-selection generator sync

## 1. Goal

Make the active Gaussian low-q row-selection generator, dashboard TSV, artifact
mirror, validator, and focused tests agree that animal/relmat q1
`sigma:(Intercept)` are blocked by the imported SR150 raw-Wald route result,
while support cells remain `point_fit/planned/planned`.

## 2. Implemented

- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` to use
  the current 24-row low-q gate universe and 20-row active selection universe.
- Regenerated both row-selection TSVs from the generator and verified the
  dashboard copy matches the artifact mirror with `cmp`.
- Changed animal/relmat q1 sigma-intercept active row-selection status to
  `sigma_sr150_raw_wald_route_blocked_harden_before_topup`.
- Kept phylo/spatial q1 sigma-intercept rows at
  `sigma_smoke_diagnostic_blocked`.
- Preserved q1 mu and q2 imported Nibi smoke overlays in the generator so
  reruns do not revert them to "ready" or local-smoke states.
- Updated mission-control validation and focused conversion-contract tests to
  require the current split.
- Bumped the dashboard widget build from `r173` to `r174`.

## 3a. Decisions and Rejected Alternatives

The active row-selection status now treats animal/relmat SR150 as a hard
negative for the current raw log-SD Wald interval route, not evidence that the
model cells are unsupported. The rejected alternative was leaving
`sigma_smoke_route_passed_denominator_review_hold`, because the imported SR150
pregrid superseded the local n=5 smoke and showed 115/150 usable intervals plus
118/150 warning replicates.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/after-task/2026-06-30-q-series-q1-sigma-pregrid-blocker-status-sync.md`
- `docs/dev-log/after-task/2026-06-30-q-series-q1-sigma-row-selection-generator-sync.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file
  tools/summarize-structured-re-gaussian-lowq-row-selection.R
  --overwrite=true`: passed and wrote 20 rows.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv
  docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9607 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## 6. Tests of the Tests

Before the generator repair, `tools/validate-mission-control.py` failed because
the generator-created TSV required stale route-pass wording and stale local
q1/q2 smoke overlays. The focused test then failed once on the q2
smoke-substitution wording, proving the test checked generated prose and not
only row counts. After the generator and test expectations were synchronized,
the same focused test passed.

## 7a. Issue Ledger

`gh issue list --search "q1 sigma Q-Series" --limit 10 --json
number,title,state,url` returned an empty list, so no issue was updated or
opened for this generator sync.

## 8. Consistency Audit

Searches run:

- `rg -n "sigma_smoke_route_passed_denominator_review_hold|fisher_gauss_rose_denominator_review_before_host|route-passed denominator-review-hold animal/relmat|sigma_sr150_raw_wald_route_blocked_harden_before_topup" docs/dev-log/dashboard docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local tools tests docs/dev-log/check-log.md`
- `rg -n "const BUILD|r173" docs/dev-log/dashboard/index.html docs/dev-log/dashboard/version.txt`

The stale route-pass token now appears only in historical check-log entries.
Current generator, dashboard TSV, artifact mirror, validator, and focused tests
use the SR150 route-blocked token for animal/relmat.

## 9. What Did Not Go Smoothly

The first TSV rewrite partially updated only the dashboard copy before the
artifact mirror. Then rerunning the generator exposed older q1 mu and q2
overlay drift. Rose correctly identified this as a generator/source-of-truth
problem rather than a one-row wording patch.

## 10. Known Residuals

This sync promotes no Q-Series row. Animal/relmat q1 `sigma:(Intercept)` still
need a hardened or replacement sigma interval route before SR475/SR1000,
denominator escalation, `inference_ready`, or support claims. The older
denominator-contract artifact remains historical evidence that the SR150
pregrid was allowed; the active row-selection now points to the imported SR150
blocker.

## 11. Team Learning

Generated dashboard TSVs need generator-level overlays for imported cluster
reviews. Hand-edited rows are too fragile once a later agent reruns a summary
script.
