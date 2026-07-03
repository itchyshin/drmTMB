# Q-Series Tranche 75 q1 mu one-slope spatial host-smoke terminal review

Date: 2026-07-02

## Purpose

Tranche 75 records the single reviewed Totoro n=5 smoke attempt for the spatial
q1 `mu` one-slope direct-SD row after the T74 runner-path gate. The purpose is
to bank the host evidence honestly, not to promote a support cell or authorize
coverage.

## Evidence

- Sidecar:
  `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche75-spatial-host-smoke-terminal-review.tsv`
- Imported artifacts:
  `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche75-spatial-host-smoke-totoro/`
- Runner and wrapper:
  `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R` and
  `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.sh`
- Source snapshot:
  `/home/snakagaw/codex/drmTMB-q1mu-slope-tranche73-clean-source-56add7f0-20260702T123451Z`
- Run root:
  `/home/snakagaw/drmtmb-qseries/q1-mu-slope-spatial-tranche73-clean-source-20260702T123451Z`

## Result

Exactly one Totoro command was dispatched through the T74 wrapper with
`DRMTMB_Q1MU_SLOPE_T74_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace`. The
remote runner loaded the exact T73 source snapshot and wrote the results,
summary, run-log, host-provenance, and hash artifacts.

All 10 result rows failed before fitting because
`phase18_assert_one_row_data_frame` was not available to the sourced runner
environment. The two target summaries each record `n_attempted=5`,
`n_fit_ok=0`, `n_pdhess=0`, and `n_finite_interval=0`.

The local exit-code capture failed after the remote artifacts were written
because `status` is read-only in zsh. This is recorded in
`t75-local-exit-capture-note.txt`; the smoke must not be rerun merely to repair
that local artifact.

## Claim Boundary

T75 is not fit evidence, `pdHess` evidence, Wald/profile interval evidence,
admission evidence, a retained denominator, a coverage denominator, a coverage
result, a top-up authorization, or a support-cell status move. Every T75 row
keeps `coverage_not_authorized`, `do_not_promote`, and
`unchanged_point_fit_planned_planned`.

No `inference_ready`, no `supported`, no q1 `sigma`, no q2, no q4/q8, no
non-Gaussian interval, no REML, no AI-REML, no bridge support, no public
support, and no denominator pooling is claimed.

## Review

Rose, Fisher, Gauss, Noether, and Grace are blocking for any status, admission,
or compute interpretation. Ada, Curie, Boole, and Emmy are advisory. SC415
member-board rows are recorded in
`docs/dev-log/dashboard/member-discussions.tsv`.

## Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`
- TSV shape check for the T75 sidecar, `member-discussions.tsv`, and
  `structured-re-q-series-next-campaign-queue.tsv`
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tests/testthat/test-structured-re-conversion-contracts.R"); parse("tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R")'`
- Extracted the dashboard JavaScript from `docs/dev-log/dashboard/index.html`
  and ran `node --check /tmp/drmtmb-mission-control-index-r269.js`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`
- Q-Series invariant scan: 104 support cells, 8 `interval_status ==
  "inference_ready"` rows, 8 `coverage_status == "inference_ready"` rows, 0
  structured `supported` rows, and 0 q4 coverage-authorized rows.
- `git diff --check`

## Tests Of The Tests

The focused conversion-contract test now checks the T75 row schema, the nine
review IDs, the no-promotion/no-coverage status, imported results and summary
counts, remote hashes, host provenance, the missing-helper message, the
absence of a local exit-code file, and the SC415 member-board stances. The
first run failed on type-conversion and literal backtick expectations, which
confirmed the new assertions were being exercised; the corrected test then
passed.

## Consistency Audit

Updated files that tell the Q-Series story together:

- Mission Control HTML and version: `docs/dev-log/dashboard/index.html`,
  `docs/dev-log/dashboard/version.txt`
- Dashboard sidecars and member board:
  `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche75-spatial-host-smoke-terminal-review.tsv`,
  `docs/dev-log/dashboard/member-discussions.tsv`,
  `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- Narrative docs: `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`,
  `docs/dev-log/check-log.md`
- Validator and focused tests: `tools/validate-mission-control.py`,
  `tests/testthat/test-structured-re-conversion-contracts.R`

The relevant stale-claim patterns checked by validator/test invariants are
`inference_ready`, `supported`, q4 coverage authorization, retained-denominator
promotion, REML, AI-REML, and denominator pooling. No public README, formula
grammar, exported API, pkgdown navigation, `R/`, `src/`, or NEWS status changed.

## GitHub Issue Maintenance

No GitHub issue was opened or closed in this tranche. This is a local
dashboard/validation evidence update that ends in a T76 source-map review gate,
not a user-facing feature or public support change.

## What Did Not Go Smoothly

The local shell wrapper tried to assign the variable name `status` in zsh after
the remote command returned. Because `status` is read-only in zsh, no local
`t75-totoro-command.exitcode` file was written even though the remote artifacts
were produced. That caveat is now recorded explicitly and must not trigger a
repeat smoke by itself.

## Team Learning

The runner-source map needs to be reviewed before the next compute spend. A
clean source snapshot and successful package load are not enough if the smoke
runner manually sources a subset of `inst/sim/R` helpers.

## Known Limitations

T75 does not distinguish model failure from runner-source failure beyond the
pre-fit missing-helper taxonomy. It gives no Hessian, Wald, profile, admission,
coverage, or support evidence.

## Next Gate

Write Tranche 76 as a source-map/runner-source review before any rerun. Inspect
why `phase18_assert_one_row_data_frame` from `inst/sim/R/sim_runner.R` was not
sourced by the T74 runner, record the proposed source-list repair, and require
Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint before any
compute.
