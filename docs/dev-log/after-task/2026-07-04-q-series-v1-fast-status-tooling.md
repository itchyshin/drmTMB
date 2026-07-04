# After Task: Q-Series v1 Fast-Status Tooling

## 1. Goal

Make the Q-Series v1.0 row-accounting snapshot cheap to query during release
planning without turning that shortcut into validation, support, coverage, or
public wording evidence.

## 2. Implemented

`tools/qseries_v1_release_check.py` now accepts `--fast-status`. The mode reads
the checked-in release status and generated v1 release ledger, builds the same
candidate review queue used by the validated preflight, prints a compact
`qseries_v1_fast_status` line, and exits before ledger regeneration, the public
claim guard, or Mission Control.

The dashboard README and generated preflight report now document the fast mode.
The focused conversion-contract test checks both the row-accounting values and
the explicit skipped-validation boundary.

## 3. Mathematical Contract

No model, likelihood, formula grammar, or estimand changed. The only contract is
row accounting: the fast snapshot reports the current 74/104 practical v1.0
surface, 56/67 Gaussian core, 18/37 basic-distribution recovery, 8/104 exact
`inference_ready` anchors, 0/104 `supported` authority, and 30/104 post-v1.0
rows from checked-in release artifacts.

## 3a. Decisions and Rejected Alternatives

Decision: add an explicit `--fast-status` mode rather than making `--summary`
silently cheaper.

Rationale: the routine summary is already an evidence-banking command because it
runs the ledger generator, claim guard, and Mission Control. The fast path needs
different wording so users can ask "where are we?" quickly without creating a
false validation claim.

Rejected alternative: skip Mission Control automatically whenever `--summary`
is requested. That would make the routine preflight ambiguous and could weaken
the release gate.

## 4. Files Touched

- `tools/qseries_v1_release_check.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-04-q-series-v1-fast-status-tooling.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --fast-status`
- `python3 tools/qseries_v1_release_check.py --summary --write-report --write-candidates`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"`
- `git diff --check`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`

## 6. Tests of the Tests

The focused test now runs `--fast-status`, requires
`qseries_v1_fast_status`, `validation=skipped`, `ledger=not_run`,
`claim_guard=not_run`, `mission_control=not_run`, the current row-accounting
values, the first-four candidate IDs, and
`boundary=ledger_only_no_validation_no_promotion`. It also asserts the fast
output does not contain the validated `qseries_v1_release_check_ok` marker.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This is local release-prep tooling
for the existing Q-Series v1.0 reset.

## 8. Consistency Audit

This slice changes no R API, formula grammar, likelihood, TMB code,
support-cell status, README claim, NEWS claim, roadmap claim, coverage decision,
`inference_ready`, or `supported` authority. The generated preflight still names
the routine validated command for evidence, and the fast command is fenced as a
planning snapshot only.

## 9. What Did Not Go Smoothly

The first parse command used bare `Rscript`, which is not on this shell's PATH.
Rerunning with `/usr/local/bin/Rscript` matched the existing check-log pattern
and passed.

## 10. Known Residuals

`--fast-status` can become stale if the checked-in release status or ledger is
stale. It does not rerun the ledger generator, claim guard, Mission Control, R
tests, support-cell validation, or any compute. It authorizes no row movement,
coverage, `inference_ready`, `supported`, q4/q8, REML, AI-REML, bridge, or
public-support claim.

## 11. Team Learning

Ada: fast release planning needs an explicit no-validation mode, not a hidden
shortcut through the full preflight.

Rose: the fast line must say what it skipped before it says any percentages.

Grace: the routine command remains the only evidence-banking command; the fast
mode is for operator ergonomics.

## 12. Next Actions

Use `--fast-status` for quick "where are we?" checks during v1.0 planning. Use
`--summary --check-report --check-candidates` before banking evidence, editing
public wording, or proposing any support-cell movement.
