# After Task: Q-Series Tranche 47 q4 relmat Boundary-Hessian Inspection Result

Supersession note (2026-07-01): Tranche 48 parks this failed relmat q4
admission route in
`docs/dev-log/dashboard/structured-re-q4-location-tranche48-relmat-parking-decision.tsv`.
Tranche 47 remains the artifact-only inspection result and did not itself park
the route or move support-cell status.

## 1. Goal

Run the Tranche 46 artifact-only inspection from existing local files and decide
what the relmat q4 `mu1` direct-SD blocker actually is before any replay,
top-up, coverage, denominator admission, or support-cell movement.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche47-relmat-boundary-hessian-inspection-result.tsv`
as an eight-row Mission Control sidecar. Mission Control build `r241` now loads
and renders it.

The result reads the imported Tranche 44 Totoro shard-13 replicate TSV, summary
TSV, log, `sessionInfo.txt`, host provenance, and source provenance. It does not
run a model, replay Totoro, submit to DRAC, fetch remote files, or reconstruct a
fit object.

## 3a. Decisions and Rejected Alternatives

The inspection result confirms exact coupling among the main blockers: the 38
boundary rows are exactly the 38 `pdHess = FALSE` rows and exactly the 38
Wald-nonfinite rows. The single profile failure is replicate 119 / seed 980118,
inside that same boundary class. The imported artifact tree lacks raw Hessian or
eigenstructure files, so deeper geometry would require a new instrumentation
contract.

Rejected denominator admission, q4 coverage authorization, shards 14-16, DRAC
submission, Totoro replay, top-up, optimizer changes, start-map changes,
formula-grammar changes, profile-target changes, reparameterization, raw-Hessian
claims, `inference_ready`, `supported`, q4 REML, REML, AI-REML, q8 inference,
derived-correlation interval claims, broad bridge support, and public support.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche47-relmat-boundary-hessian-inspection-result.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche47-q4-relmat-boundary-hessian-inspection-result.md`

## 5. Checks Run

- Tranche 47 TSV shape check: 9 lines including header, 37 columns, no
  bad-width rows.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Tranche 47 boundary-Hessian
  inspection-result rows, and 225 member-discussion rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "Sys.setenv(OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1',
  MKL_NUM_THREADS='1'); devtools::test(filter =
  'structured-re-conversion-contracts', reporter = 'summary')"`: passed.
- Final invariant scan passed: 104 Q-Series cells, 8 interval
  `inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured
  `supported` rows, 0 q4 coverage-authorized rows, and all 8 Tranche 47 rows
  retain no-compute, no-coverage, no-promotion decisions with the expected
  112/38 `pdHess`/boundary/Wald split.
- Served-dashboard probe at `http://127.0.0.1:8766/docs/dev-log/dashboard/`
  passed: `version.txt` returned `r241`, the Tranche 47 TSV had 9 lines and 37
  columns, and `index.html` contained the build id, summary card, detail label,
  and TSV loader.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche47-q4-relmat-boundary-hessian-inspection-result.md')"`:
  passed with `after-task structure check passed`.
- Recovery checkpoint written:
  `docs/dev-log/recovery-checkpoints/2026-07-01-214430-codex-checkpoint.md`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused R test reads the Tranche 47 sidecar, checks schema and source links
to Tranche 46, Tranche 45, and Tranche 44, recomputes the retained-denominator
counts from the raw imported replicate TSV, verifies exact `pdHess` / boundary /
Wald coupling, checks the replicate 119 profile failure, counts optimizer and
`NaN` message occurrences, verifies no raw geometry filenames exist in the
imported artifact tree, checks unchanged relmat q4 support-cell status, and
checks the SC391 member-board rows.

The Python validator independently checks the Tranche 47 render/load wiring,
sidecar schema, row count, exact result scopes, source lineage, artifact paths,
claim-boundary phrases, raw replicate counts, profile-failure identity, absence
of raw geometry artifact filenames, unchanged support-cell status, and
member-board rows.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche records internal Mission
Control inspection evidence only. It does not change public APIs, formula
grammar, package behavior, user-facing support status, or release text.

## 8. Consistency Audit

The relmat q4 support cell remains unchanged. Tranche 47 carries
`compute_decision = no_compute_in_tranche47`,
`coverage_decision = coverage_not_authorized`, and
`promotion_decision = do_not_promote` on every row.

Mission Control still reports 104 Q-Series support cells, 8 interval
`inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured-provider
rows with any `supported` status, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed by Tranche 47.

## 9. What Did Not Go Smoothly

The TSV drafting pass had one typo in Curie's review field. It was corrected
before validator and focused-test checks. The first focused R test also caught
that raw TSV fields parsed as integer/logical values rather than strings; the
test expectations were corrected to compare the artifact in its actual R-parsed
types. No compute ran and no raw Hessian eigenstructure result is claimed.

## 10. Known Residuals

The existing artifacts are sufficient to classify the Tranche 44 relmat q4
blocker, but not to inspect raw Hessian eigenstructure. The next tranche should
either park relmat q4 or write a separate design/instrumentation contract. It
must not run a model, fetch remote files, submit to DRAC, replay Totoro, change
optimizers, change formula grammar, change profile targets, admit a denominator,
authorize coverage, or move support-cell status.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Rose kept the result from becoming a status claim. Fisher kept the retained
denominator gate closed. Gauss reduced the blocker to exact boundary /
`pdHess` / Wald coupling plus a missing raw-geometry artifact. Noether kept the
scope on the direct-SD relmat q4 `mu1` target. Grace kept Totoro provenance
local and unpooled. Curie kept simulation deferred until the next question is a
design, not a rerun.
