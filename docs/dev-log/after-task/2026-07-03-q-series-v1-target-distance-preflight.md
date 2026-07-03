# After Task: Q-Series v1 Target-Distance Preflight

## Goal

Make the Q-Series v1.0 preflight answer the next percentage question directly:
how many additional practical-surface rows are needed to reach the next
row-accounting targets, without turning that counter into a support claim.

## Implemented

`tools/qseries_v1_release_check.py` now derives target gaps from the generated
release-status progress row. The one-line summary reports `rows_to_75`,
`rows_to_80`, `rows_to_90`, and `rows_to_100`, and the generated preflight
report records the same values in a distance-to-target table.

## Mathematical Contract

The target gap is a row-count calculation only: for each target percentage,
required rows are `ceiling(total_rows * target_percent / 100)`, and rows still
needed are `max(required_rows - current_practical_surface_rows, 0)`. With the
current 74/104 practical surface, the counters are 4 rows to 75%, 10 rows to
80%, 20 rows to 90%, and 30 rows to 100%.

## Files Changed

- `tools/qseries_v1_release_check.py`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --summary --write-report`
- `python3 tools/qseries_v1_release_check.py --summary --check-report`
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py | tail -n 1`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## Tests Of The Tests

The focused conversion-contract test now checks both surfaces: the CLI summary
must contain the four `rows_to_*` counters, and the generated Markdown report
must contain the distance-to-target table plus the planning-only boundary text.
If the report drifts from the generator, `--check-report` fails before the R
test treats the preflight as current.

## Consistency Audit

The dashboard README describes the target counters as planning aids only. The
generated report keeps the same boundary as the release ledger: no row movement,
coverage job, public release claim, `inference_ready`, or `supported` status is
authorized by these counters. No formula grammar, R API, TMB likelihood,
pkgdown navigation, README release wording, NEWS release wording, or support
cell status changed.

## GitHub Issue Maintenance

No GitHub issue was opened or commented on. This was a local release-prep
tooling speedup that changes no public behavior and creates no new external
claim.

## What Did Not Go Smoothly

The main risk was wording: target percentages are easy to read as completion
claims. The report and README therefore name them as row-accounting planning
aids, and the test asserts that boundary.

## Team Learning

Kim's economy rule benefits from small generated summaries. A cheap row-gap
counter reduces repeated manual interpretation of the ledger and helps the team
choose the next target without spending compute or weakening Rose's claim
boundary.

## Known Limitations

These percentages are not package-release completion, statistical support, or
coverage evidence. Reaching 75%, 80%, 90%, or 100% would still require exact
row-local evidence before any support-cell status, `inference_ready`,
`supported`, q4/q8, REML, AI-REML, bridge, or public-support claim moved.

## Next Actions

Use `python3 tools/qseries_v1_release_check.py --summary --check-report` as the
routine v1.0 Q-Series preflight. If the next campaign slice tries to reach 75%
or 80%, choose rows that already have cheap implementation or recovery evidence
and keep full inference/support validation deferred until a row-specific gate
earns it.
