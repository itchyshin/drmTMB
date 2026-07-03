# After Task: Q-Series v1 Release Ledger Speedup

## 1. Goal

Add a row-level Q-Series v1.0 release-readiness surface so the v1.0 campaign can
prioritize implemented/basic-working Gaussian rows and basic-distribution
recovery without re-opening full `inference_ready` or `supported` validation.

## 2. Implemented

Added `tools/qseries_v1_release_ledger.py`, which derives
`docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` from the
104-row support-cell table. The generated ledger assigns every support cell one
v1 role: Gaussian inference anchor, Gaussian basic-working row,
basic-distribution recovery row, Gaussian post-v1.0 validation row, or
basic-distribution post-v1.0 design row.

Mission Control now loads and renders a compact v1 release-ledger rollup, and
the validator checks copied support-cell fields, row classification, track
counts, no-claim boundaries, and the 104-row invariant.

## 3a. Decisions and Rejected Alternatives

The ledger is generated from `structured-re-q-series-support-cells.tsv` rather
than hand-curated. That keeps the support-cell table as the source of truth and
turns future v1 role refreshes into one command.

I did not promote any row, authorize compute, or change package APIs. The
release ledger is a planning and audit surface only.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-07-03-q-series-v1-release-ledger-speedup.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/dashboard/version.txt`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries-tranche-scaffold.py`
- `tools/qseries_v1_release_ledger.py`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py tools/qseries_v1_release_ledger.py`: passed.
- `python3 tools/qseries_v1_release_ledger.py --check --summary`: passed with 104 rows.
- Dashboard JS extraction plus bundled Node `--check /tmp/drmtmb-mission-control-index-r324.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells, 8 v1 readiness-reset rows, and 104 v1 release-ledger rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed with `DONE`.

## 6. Tests of the Tests

The Python validator recomputes the expected v1 track for every support-cell
row and compares the generated ledger against copied source fields and expected
classification text. The focused R test independently recomputes the same
classification from the support-cell TSV and checks that the ledger has the
same 104 rows and the same track split.

## 7a. Issue Ledger

No GitHub issue action was taken. This is an internal Q-Series dashboard and
release-readiness speedup, not a public API or user-facing feature change.

## 8. Consistency Audit

The dashboard README and completion map now name the release ledger and its
generator. Mission Control build/version moved to `r324`. The scaffold checklist
now reminds future tranche authors to regenerate the v1 release ledger when
support-cell roles can change.

The no-claim boundary was checked in both Python and R: the ledger does not
authorize coverage, support-cell promotion, `inference_ready`, `supported`,
REML, AI-REML, q4/q8 expansion, or public support.

## 9. What Did Not Go Smoothly

The shell did not have `node` on `PATH`, so the dashboard JS check used the
bundled Codex runtime Node path instead. The earlier Python and R checks were
otherwise direct.

## 10. Known Residuals

This does not finish the v1.0 release campaign. It makes the Q-Series v1.0
status cheaper and safer to review, but package-facing release wording and any
actual row promotions remain separate future work.

## 11. Team Learning

For v1.0 readiness work, keep the 104-cell support table authoritative and
generate release cuts from it. A generated row-level ledger is cheaper and less
error-prone than another hand-maintained summary table.
