# After Task: Q-Series Tranche 46 q4 relmat Boundary-Hessian Inspection Contract

Supersession note (2026-07-01): Tranche 47 executed this contract as an
artifact-only inspection result in
`docs/dev-log/dashboard/structured-re-q4-location-tranche47-relmat-boundary-hessian-inspection-result.tsv`.
Tranche 46 remains the contract record and did not itself claim an inspection
result.

## 1. Goal

Choose one no-compute failure-class contract after Tranche 45 and define the
artifact-only inspection needed to understand the relmat q4 boundary,
`pdHess`, and Wald-finiteness blocker before any replay, top-up, coverage, or
status movement.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche46-relmat-boundary-hessian-inspection-contract.tsv`
as a seven-row Mission Control sidecar. Mission Control build `r240` now loads
and renders it.

The contract selects the boundary/pdHess geometry route from Tranche 45. It
does not run the inspection. The rows define artifact-only checks for:
boundary-row inventory, `pdHess`/Wald coupling, optimizer fallback and `NaN`
messages, replicate 119 / seed 980118 as the single profile exception, raw
Hessian artifact availability, direct-SD scale patterns, and a summary stop
rule.

## 3a. Decisions and Rejected Alternatives

The tranche decision is `no_compute_in_tranche46`. All seven rows retain
`coverage_decision = coverage_not_authorized` and
`promotion_decision = do_not_promote`.

Rejected running model refits, optimizer reruns, profile reruns, remote file
fetches, Totoro commands, DRAC submission, shards 14-16, top-up, coverage
scaling, formula grammar changes, profile-target changes, or reparameterization
from this contract. Rejected calling the contract an inspection result.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche46-relmat-boundary-hessian-inspection-contract.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche45-q4-relmat-after-deps-route-hold-failure-taxonomy.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche46-q4-relmat-boundary-hessian-inspection-contract.md`

## 5. Checks Run

- Tranche 46 TSV shape check: 8 lines including header, 32 columns, no
  bad-width rows.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r240.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 7 Tranche 46 boundary-Hessian
  inspection-contract rows, and 218 member-discussion rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "Sys.setenv(OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1',
  MKL_NUM_THREADS='1'); devtools::test(filter =
  'structured-re-conversion-contracts', reporter = 'summary')"`: passed.
- Final invariant scan passed: 104 Q-Series cells, 8 interval
  `inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured
  `supported` rows, 0 q4 coverage-authorized rows, and all 7 Tranche 46 rows
  retain no-compute, no-coverage, no-promotion decisions.
- Served-dashboard probe at `http://127.0.0.1:8766/docs/dev-log/dashboard/`
  passed: `version.txt` returned `r240`, the Tranche 46 TSV had 8 lines and 32
  columns, and `index.html` contained the build id, summary card, detail label,
  and TSV loader.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche46-q4-relmat-boundary-hessian-inspection-contract.md')"`:
  passed with `after-task structure check passed`.
- Recovery checkpoint written:
  `docs/dev-log/recovery-checkpoints/2026-07-01-212723-codex-checkpoint.md`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused R test reads the Tranche 46 sidecar, checks schema and source links
to Tranche 45 and Tranche 44, verifies all rows are no-compute, no-coverage,
and no-promotion, checks allowed and forbidden actions, checks unchanged relmat
q4 support-cell status, and verifies the SC390 member-board rows with blocking
and advisory stances separated.

The Python validator independently checks the Tranche 46 render/load wiring,
sidecar schema, row count, exact contract scopes, source lineage, evidence
paths, claim-boundary phrases, unchanged support-cell status, and member-board
rows.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche records internal Mission
Control contract evidence only. It does not change public APIs, formula
grammar, package behavior, user-facing support status, or release text.

## 8. Consistency Audit

The relmat q4 support cell remains unchanged. Tranche 46 carries
`compute_decision = no_compute_in_tranche46`,
`coverage_decision = coverage_not_authorized`, and
`promotion_decision = do_not_promote` on every row.

Mission Control still reports 104 Q-Series support cells, 8 interval
`inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured-provider
rows with any `supported` status, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed by Tranche 46.

## 9. What Did Not Go Smoothly

One contract row initially had a malformed replicate-TSV path while drafting.
It was corrected before validation. The first focused R test rerun also caught
that the test accepted several no-compute forbidden-action anchors but omitted
the contract's `no_topup` anchor for the `pdHess`/Wald-coupling row; the test
was tightened to match the validated sidecar. No compute ran and no artifact
inspection result is claimed.

## 10. Known Residuals

The boundary/Hessian inspection has not run. The next tranche may execute the
artifact-only inspection from existing files, or explicitly park relmat q4. It
must not run a model, fetch remote files, submit to DRAC, replay Totoro, change
optimizers, change formula grammar, change profile targets, admit a
denominator, or authorize coverage.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Rose kept a contract from becoming an inspection result. Fisher kept the failed
admission gate closed. Gauss narrowed the next question to boundary/Hessian
geometry. Noether kept the scope on the direct-SD relmat q4 `mu1` target.
Grace required existing local artifact inventory before any host action. Curie
kept simulation design deferred until the artifact-only inspection exists.
