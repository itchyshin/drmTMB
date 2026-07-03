# After-task: Q-Series v1 readiness reset and tooling speedup

## 1. Goal

Reframe the active Q-Series campaign for v1.0: keep the exact Mission Control evidence boundaries, but stop treating universal `inference_ready` or `supported` validation as a v1.0 blocker. Bank the already prepared q2 Tranche 129 contract, add a v1 readiness ledger, and start a small scaffold tool so future no-compute tranches do not require as much manual wiring.

## 2. Implemented

Added the q2 Tranche 129 spatial g=32 executable-contract sidecar and fail-closed wrapper contract. Added `structured-re-q-series-v1-readiness-reset.tsv` with eight rows that separate v1.0 implemented/basic-working scope from exact `inference_ready` and post-v1.0 `supported` validation. Mission Control build `r323` now renders the T129 contract and v1 readiness reset, and the validator checks both against live support-cell counts. Added `tools/qseries-tranche-scaffold.py`, a stdout-only scaffold for future no-compute tranche packets.

## 3a. Decisions and Rejected Alternatives

The tranche remains no-compute. I rejected running Totoro/DRAC smoke work inside this step because the user changed the goal toward v1.0 readiness and tooling speed, not more denominator evidence. I also rejected weakening `supported`: the reset keeps exactly zero structured supported rows and treats recovery-only non-Gaussian evidence as implementation/basic-distribution evidence only.

## 4. Files Touched

Key new files: `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`, `docs/dev-log/dashboard/structured-re-q2-slope-tranche129-spatial-g32-executable-contract.tsv`, `tools/run-q2-slope-tranche129-spatial-g32-comparison.sh`, `tools/qseries-tranche-scaffold.py`, and the T129 simulation-artifact contract files.

Key updated files: `docs/dev-log/dashboard/index.html`, `docs/dev-log/dashboard/version.txt`, `tools/validate-mission-control.py`, `tests/testthat/test-structured-re-conversion-contracts.R`, `docs/dev-log/dashboard/README.md`, `docs/design/218-structured-q-series-completion-map.md`, `docs/dev-log/dashboard/member-discussions.tsv`, and `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`.

## 5. Checks Run

Passed: `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py`.

Passed: extracted dashboard JavaScript and ran `node --check /tmp/drmtmb-mission-control-index-r323.js`.

Passed: `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`, including 104 Q-Series cells, 8 inference-evidence rows, 8 v1 readiness-reset rows, 10 T129 rows, and 938 member-discussion rows.

Passed: `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`.

Passed: `python3 tools/qseries-tranche-scaffold.py --help` and a T130 sample scaffold.

Passed invariant scan: 104 Q-Series cells, 8 exact `inference_ready` rows, 0 structured supported authority rows, 0 q4 coverage-authorized rows, 67 Gaussian rows, 37 non-Gaussian rows, 56 Gaussian basic-working candidates, and 18 non-Gaussian recovery/basic candidates.

Passed: after-task structure checker for this report.

Passed: `git diff --check`.

Recovery checkpoint written: `docs/dev-log/recovery-checkpoints/2026-07-03-111851-codex-checkpoint.md`.

## 6. Tests of the Tests

The first focused R run failed because two T129 claim-boundary rows used equivalent but non-exact wording for `no coverage` and `no host command`. I tightened the TSV wording rather than loosening the test, then reran the focused R test successfully.

## 7a. Issue Ledger

No GitHub issue or PR was opened in this step. The durable local issue is now the v1.0 lane split: implemented/basic-working documentation can move toward v1.0, while full retained-denominator coverage and `supported` grids remain post-v1.0 work.

## 8. Consistency Audit

Rose/Fisher/Gauss/Noether/Grace remain blocking for any future compute or status claim. T129 authorizes no execution, no denominator, no coverage, no top-up, no admission, no q4/q8 expansion, no REML, no AI-REML, and no public support. The v1 reset changes planning priority only; it does not alter public APIs, formula grammar, package runtime, support-cell statuses, README/NEWS claims, or pkgdown.

## 9. What Did Not Go Smoothly

Manual sidecar wiring is still slow and brittle. The validator caught missing exact boundary phrases, which confirms the checks are useful but also shows why this process needs scaffolding.

## 10. Known Residuals

The scaffold tool only prints a draft; it does not yet generate dashboard, validator, test, check-log, or after-task snippets from one source spec. T129 remains a banked command contract only. Totoro/DRAC execution, if still useful, needs a separate checkpointed approval and terminal-review tranche.

## 11. Team Learning

For v1.0, the useful percentage should be computed against honest shipped/basic-working scope, not against universal `inference_ready` or `supported` coverage. The faster path is to scaffold no-compute tranches and reserve expensive host work for decisions that change the v1.0 story.
