# After Task: Q-Series v1 release status sync

## 1. Goal

Make the Q-Series v1.0 release boundary easy to cite from package-facing status
files without changing support-cell statuses, public APIs, formula grammar, TMB
code, or inference claims.

## 2. Implemented

Extended `tools/qseries_v1_release_ledger.py` so the generated v1 ledger can also
write and check
`docs/dev-log/release-audits/q-series-v1-release-status.md`. The status summary
turns the 104-row support-cell ledger into release-facing wording: 8 exact
Gaussian `inference_ready` anchors, 48 additional Gaussian basic-working rows,
18 basic-distribution recovery rows, and 30 post-v1.0 validation/design rows.

Linked that generated status file from README, ROADMAP, NEWS, and known
limitations. Updated the Mission Control validator and the focused
conversion-contract test so those public/status files keep citing the generated
status boundary.

## 3a. Decisions and Rejected Alternatives

The status summary is generated, not hand-written. That keeps the 104-row
support-cell table and release ledger as the source of truth.

I did not change the Mission Control dashboard build, package runtime, public
API, formula grammar, support-cell statuses, or coverage state. The status file
is a release-planning boundary only.

## 4. Files Touched

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries_v1_release_ledger.py`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py tools/qseries_v1_release_ledger.py`: passed.
- `python3 tools/qseries_v1_release_ledger.py --check --check-status --summary`: passed with 104 rows and the expected five-track split.
- Dashboard JS extraction plus bundled Node `--check /tmp/drmtmb-mission-control-index-r324.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells, 104 v1 release-ledger rows, and the generated release-status boundary.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed with `DONE`.

## 6. Tests of the Tests

The first focused R rerun failed because the new status and public-file reads
used paths relative to the test working directory. I fixed the test to use the
existing repo-root artifact helper, then reran the focused test successfully.

The validator and R test independently check the same boundary phrases:
release planning only, no support promotion, no coverage or q4 coverage, no
`inference_ready` or `supported` promotion, no REML or AI-REML, and no public
support.

## 7a. Issue Ledger

No GitHub issue or PR action was taken. This is a local release-readiness and
dashboard-validation slice inside the active Q-Series campaign.

## 8. Consistency Audit

README, ROADMAP, NEWS, and known limitations all cite
`docs/dev-log/release-audits/q-series-v1-release-status.md`. The generated
status summary keeps the v1.0 surface separate from exact row-local
`inference_ready` evidence and from post-v1.0 `supported` validation.

No coverage, q4 coverage, q8 expansion, derived-correlation interval,
non-Gaussian structured-covariance support, broad bridge support, REML,
AI-REML, or public support claim was added.

## 9. What Did Not Go Smoothly

The R test path bug cost one full focused-test rerun. The failure was useful:
it confirmed the new test really reads the generated status file and public
status files instead of silently passing on missing evidence.

## 10. Known Residuals

This does not make drmTMB v1.0 complete. It makes the Q-Series release boundary
cheaper to cite and validate while keeping full `inference_ready` and
`supported` validation as post-v1.0 work unless separately promoted.

## 11. Team Learning

For release-facing Q-Series wording, generate the status summary from the
ledger and test every public link back to that generated source. That is faster
and safer than copying the same percentages and no-claim boundary by hand.
