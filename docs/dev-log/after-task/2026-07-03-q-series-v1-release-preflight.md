# After Task: Q-Series v1 consolidated release preflight

## 1. Goal

Make Q-Series v1.0 release preparation faster by giving contributors one command
that checks the generated ledger/status, public claim guard, and Mission Control
validator without changing statistical support claims.

## 2. Implemented

Added `tools/qseries_v1_release_check.py`. In normal mode,
`python3 tools/qseries_v1_release_check.py --summary` runs the generated
ledger/status check, the public wording claim guard, and Mission Control. It
then prints a compact summary with the current v1.0 row accounting: practical
v1.0 surface, Gaussian core, basic-distribution recovery, exact
`inference_ready` anchors, `supported` authority, and post-v1.0 rows.

The command also has `--skip-mission-control` for nested tests. The focused
`structured-re-conversion-contracts` test uses that mode to check the ledger and
claim guard without recursively launching the full Mission Control validator.
The dashboard README now names the command as the routine Q-Series v1.0
preflight.

## 3a. Decisions and Rejected Alternatives

The new preflight calls the existing tools instead of reimplementing their
logic. `qseries_v1_release_ledger.py` remains the row/status source of truth,
`qseries_v1_claim_guard.py` remains the public wording guard, and
`validate-mission-control.py` remains the dashboard invariant checker.

I did not wire the preflight back into Mission Control, because the preflight
itself calls Mission Control in normal mode. The R test uses the explicit
non-recursive mode to avoid a validator loop.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-03-q-series-v1-release-preflight.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries_v1_release_check.py`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/qseries_v1_release_check.py`: passed.
- `python3 tools/qseries_v1_release_check.py --summary`: passed with `qseries_v1_release_check_ok`, `ledger=ok`, `claim_guard=ok`, and `mission_control=ok`.
- `python3 tools/qseries_v1_release_check.py --skip-mission-control --summary`: passed with `mission_control=skipped`.
- Dashboard JS extraction plus bundled Node `--check /tmp/drmtmb-mission-control-index-r324.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed with `DONE`.

## 6. Tests of the Tests

The new R contract runs `qseries_v1_release_check.py --skip-mission-control
--summary`, checks for the `qseries_v1_release_check_ok` marker, and verifies
that the output includes `ledger=ok`, `claim_guard=ok`,
`mission_control=skipped`, `practical_v1_surface=74/104 (71.2%)`, and
`supported_authority=0/104 (0.0%)`. The full command was also run manually with
Mission Control enabled.

## 7a. Issue Ledger

No GitHub issue or PR action was taken. This is local release-prep tooling for
the active Q-Series v1.0 readiness campaign.

## 8. Consistency Audit

The preflight reports the same generated row accounting as the release-status
file: practical v1.0 surface 74/104 (71.2%), Gaussian core 56/67 (83.6%),
basic-distribution recovery 18/37 (48.6%), exact `inference_ready` anchors
8/104 (7.7%), `supported` authority 0/104 (0.0%), and post-v1.0
validation/design 30/104 (28.8%).

No row was promoted. The command authorizes no compute and no coverage,
q4/q8, REML, AI-REML, broad bridge-support, `supported`, or public-support
claim.

## 9. What Did Not Go Smoothly

The main design wrinkle was avoiding recursion: a release preflight should run
Mission Control in normal use, but tests that already live inside the focused
Mission Control contract need a non-recursive mode. The explicit
`--skip-mission-control` flag keeps that boundary visible.

## 10. Known Residuals

This is not a full package-release check. It covers the Q-Series v1.0
release-prep surface only. Final v1.0 readiness still needs ordinary package
release checks and reviewer approval for any public wording.

## 11. Team Learning

When a release lane accumulates multiple validators, add a small orchestrating
command before the command set becomes another thing to remember. The source
tools should remain independent, but the release preflight should be one
obvious command.
