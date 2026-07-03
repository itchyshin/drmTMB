# After Task: Q-Series v1 release claim guard

## 1. Goal

Make Q-Series v1.0 public/status wording cheaper to audit and harder to
overstate while preparing drmTMB v1.0 around implemented/basic-working Gaussian
rows and basic-distribution recovery.

## 2. Implemented

Added `tools/qseries_v1_claim_guard.py`, a standalone standard-library Python
guard that checks the generated Q-Series v1.0 release-status file and the four
public/status files that cite it: README, ROADMAP, NEWS, and known limitations.
The guard verifies that the generated status file contains the release-planning,
row-accounting, and no-claim boundary phrases, and it scans public/status lines
for obvious positive Q-Series completion, support, coverage-ready, REML,
AI-REML, and public-support wording without boundary language.

Mission Control now calls the same guard from
`tools/validate-mission-control.py`. The focused
`structured-re-conversion-contracts` test runs the guard when `python3` is
available. The dashboard README now names the command as the release-prep guard
for Q-Series v1.0 wording.

## 3a. Decisions and Rejected Alternatives

I kept the guard conservative and line-based. It is meant to catch obvious
claim inflation in the v1.0 status path, not to parse every historical design
note or rewrite old after-task records.

I did not add new compute, alter support-cell statuses, or widen any statistical
claim. This is a release-wording safety check only.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-03-q-series-v1-claim-guard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`: passed.
- `python3 tools/qseries_v1_claim_guard.py --summary`: passed with `qseries_v1_claim_guard_ok`.
- Dashboard JS extraction plus bundled Node `--check /tmp/drmtmb-mission-control-index-r324.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed with `DONE`.

## 6. Tests of the Tests

The standalone guard checks both required boundary phrases and forbidden
positive-claim patterns. The Mission Control validator calls the guard directly,
so a failure becomes part of the normal dashboard validation surface. The
focused R contract executes the same command when Python is available and checks
for the `qseries_v1_claim_guard_ok` success marker.

## 7a. Issue Ledger

No GitHub issue or PR action was taken. This is local release-prep tooling for
the active Q-Series v1.0 readiness campaign.

## 8. Consistency Audit

The guard covers README, ROADMAP, NEWS, known limitations, and the generated
Q-Series v1.0 release-status file. It keeps the current boundary explicit:
implemented/basic-working Gaussian rows and basic-distribution recovery may
feed v1.0 wording, while full `inference_ready`, `supported`, coverage, q4/q8,
REML, AI-REML, broad bridge support, and public support remain unpromoted unless
a later row-specific gate proves them.

## 9. What Did Not Go Smoothly

The public Q-Series wording is intentionally full of negative boundaries, so the
guard needed to distinguish positive inflated claims from lines that say a claim
is not authorized. I kept the first version conservative to avoid false alarms
from historical design text.

## 10. Known Residuals

The guard is not a natural-language theorem prover. It catches obvious
release-path claim inflation and missing boundary links, but final v1.0 release
wording still needs Rose/Fisher review before it becomes public.

## 11. Team Learning

Release wording needs its own validator, not just a dashboard row count. A small
line-based claim guard is enough to make routine status edits safer and faster.
