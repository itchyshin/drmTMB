# After Task: Q-Series Tranche 6 Relmat Q4 Location Admission Review

## 1. Goal

Review the Tranche 5 host-separated relmat repeat without launching coverage,
and decide whether relmat q4 location direct-SD targets are ready for a separate
coverage-design tranche.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-admission-tranche6-relmat-review.tsv`,
a six-row Rose/Fisher/Grace admission-review ledger for relmat q4 location
direct-SD targets. Each target row links to the matching Tranche 4 local smoke
row and Tranche 5 Totoro repeat row.

The ledger records that local and Totoro evidence both meet the retained
`pdHess`, Wald-finite, and profile-finite direct-SD gate at 5/5 for every
target. It admits relmat only for coverage-design discussion. It authorizes no
coverage execution, moves no support-cell status, and makes no interval
reliability or support claim.

## 3a. Decisions and Rejected Alternatives

The reviewed targets remain the four direct-SD q4 location profile targets:
`sd:mu:mu1:relmat(1 | p | id)`,
`sd:mu:mu1:relmat(0 + x | p | id)`,
`sd:mu:mu2:relmat(1 | p | id)`, and
`sd:mu:mu2:relmat(0 + x | p | id)`. Derived q4 correlations, q8 targets, REML,
AI-REML, and bridge support remain outside this tranche.

The admission gate is retained-denominator `pdHess`, Wald-finite, and
profile-finite direct-SD rates of at least 0.95. For the local and Totoro
`n = 5` evidence streams, that is 5/5. The streams remain separate and are not
pooled.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-admission-tranche6-relmat-review.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Q-Series inference-evidence summary
  rows, 6 q4 location Tranche 5 relmat-repeat rows, and 6 q4 location Tranche
  6 relmat-review rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche6-relmat-q4-location-admission-review.md')"`:
  passed.
- `git diff --check`: passed.
- `sh tools/start-mission-control.sh --background &&
  curl -fsS http://127.0.0.1:8765/version.txt &&
  curl -fsS
  http://127.0.0.1:8765/structured-re-q4-location-admission-tranche6-relmat-review.tsv
  | wc -l`: passed; served Mission Control reports `r200`, and the Tranche 6
  sidecar serves seven lines including its header.

## 6. Tests of the Tests

The new focused test links every Tranche 6 target row to the matching local
smoke row and Totoro repeat row, verifies separate retained-denominator rates,
checks the 16/20 retained diagnostic counts on summary rows, and confirms that
the linked support cell is not `inference_ready` or `supported`.

## 7a. Issue Ledger

No GitHub issue action was taken. This is a local Mission Control tranche and
does not change public API, formula grammar, or package support.

## 8. Consistency Audit

Rose: the ledger says admission review only and does not move status.

Fisher: the admission gate is met for relmat direct-SD coverage-design
discussion, but coverage still requires a separate design contract.

Grace: local and Totoro denominators remain separate, with source SHA, dirty
flag, host label, and artifact provenance inherited from Tranche 5.

Gauss: gradient and profile diagnostics remain visible; the passing gate does
not erase diagnostic flags.

Noether: the tranche is direct-SD only and does not claim derived-correlation
intervals.

## 9. What Did Not Go Smoothly

The dashboard validator had exact-string guards for the q4 admission sidecar
argument list. Adding the Tranche 6 sidecar required updating both duplicate
signature guards before the validator could check the new data contract.

## 10. Known Residuals

- No q4 coverage pregrid has been designed yet.
- No q4 coverage job has been authorized or run.
- No support-cell status changed.
- No derived-correlation interval, q8, REML, AI-REML, bridge, or public-support
  claim moved.

## 11. Team Learning

Admission review and coverage design should stay separate. A passing
retained-denominator admission gate is enough to justify writing a coverage
pregrid design, but not enough to execute coverage or move `inference_ready`.

## Next Actions

Write a relmat-only q4 location coverage pregrid design contract. It should
retain failed fits and interval failures in the denominator, keep local/Totoro
evidence separate from any new host evidence, and require Rose/Fisher/Grace
approval before execution.
