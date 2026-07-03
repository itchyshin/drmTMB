# Q-Series Tranche 74 q1 mu one-slope spatial runner-path gate

## 1. Goal

Bank the Tranche 74 fail-closed runner-path gate for the Gaussian q1 `mu` one-slope spatial row. The goal was to update the stale T70 exact-path contract from the T68 source/run-root paths to the T73 clean-source snapshot and qseries run root, while spending no model compute and keeping all support-cell claims unchanged.

## 2. Implemented

- Added `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche74-spatial-runner-path-gate.tsv` with 8 runner-path gate rows.
- Added `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R` and `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.sh`.
- Banked local dry-run/refusal artifacts under `docs/dev-log/simulation-artifacts/2026-07-02-gaussian-mu-slope-tranche74-spatial-runner-path-gate-local/`.
- Appended SC414 member-board rows for Ada, Rose, Fisher, Gauss, Noether, Grace, Curie, Boole, and Emmy.
- Updated Mission Control build `r268`, `tools/validate-mission-control.py`, the focused conversion-contract test, the queue row, dashboard README, completion map, and check-log.

## 3a. Decisions and Rejected Alternatives

T74 is a runner-path gate, not execution. It does not load the R package, call `devtools::load_all()`, execute a model command, create a fit, create a retained denominator, or authorize coverage. The next executable gate is T75, at most one Totoro n=5 smoke through the T74 wrapper after Rose/Fisher/Gauss/Noether/Grace plus validator review and checkpoint.

Rejected alternatives:

- Do not rerun the stale T70 wrapper against the T73 paths.
- Do not count T74 dry-run manifest rows as attempted or retained replicates.
- Do not promote `qseries_spatial_q1_mu_one_slope`.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche74-spatial-runner-path-gate.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R`
- `tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.sh`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- TSV shape checks for T74, member discussions, and queue rows.
- R parse checks for the T74 runner and focused conversion-contract test.
- Shell syntax check for the T74 wrapper.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
- Extracted dashboard JavaScript to `/tmp/drmtmb-mission-control-index-r268.js`; `node --check /tmp/drmtmb-mission-control-index-r268.js`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`
- Parsed support-cell invariant scan.
- Served Mission Control probe.

## 6. Tests of the Tests

The focused conversion-contract test now parses the T74 sidecar, verifies exact T73 source and run-root paths, checks the dry-run manifest, verifies direct execute and wrapper refusal exit codes, checks refusal stderr, checks recorded hashes, confirms SC414 member-board rows, and rechecks that `qseries_spatial_q1_mu_one_slope` remains `point_fit`, `extractor_ready`, `fixture_parity`, `planned`, `planned`, `source`.

## 7a. Issue Ledger

- T74 proves path/refusal behavior only; it is not admission evidence.
- The T75 command still needs a fresh review and checkpoint before any smoke.
- The q1 `mu` one-slope bucket remains blocked by interval-shape and tail-balance evidence outside this spatial runner-path gate.

## 8. Consistency Audit

Rose/Fisher/Gauss/Noether/Grace remain blocking. Every T74 row says `coverage_not_authorized`, `do_not_promote`, and `unchanged_point_fit_planned_planned`. Mission Control must still report 104 Q-Series cells, 8 `interval_status == inference_ready`, 8 `coverage_status == inference_ready`, 0 exact structured-provider `supported` rows, and 0 parsed q4 `coverage_authorized` rows.

## 9. What Did Not Go Smoothly

The sidecar patch was large enough that the first landing had to be checked for shape before wiring the dashboard and validator. The queue row is a single long TSV record, so it was updated with a structured TSV rewrite to avoid breaking the row.

## 10. Known Residuals

Tranche 75 is still required before any smoke evidence exists. No q1 `mu` one-slope support-cell status moved, and phylo, animal, and relmat remain in rule-design hold. No q4 coverage, q8, non-Gaussian interval, REML, AI-REML, bridge support, or public support claim is authorized by this tranche.

## 11. Team Learning

Runner-path updates should be banked as their own fail-closed tranche when a previous executable contract names exact source/run-root paths. The dry-run/refusal layer makes the next smoke command cheaper to review without pretending that a denominator exists.
