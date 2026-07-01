# After Task: Q-Series q2 Retained-Denominator Repair-Smoke Dispatch

## 1. Goal

Record the five-row q2 retained-denominator repair-smoke command manifest and
Totoro smoke artifacts in a reviewable dashboard sidecar, without promoting any
Q-Series support cell.

## 2. Implemented

Added
`tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R`. The
summarizer reads
`structured-re-q2-retained-denominator-repair-smoke-command.tsv`, preserves the
exact command IDs, providers, repair IDs, seed ranges, expected target counts,
host labels, and selected q2-plus target IDs, then writes
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`.

Generated the dry-run manifest under
`docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-dispatch/`
and generated five manifest-only dispatch rows. The four q2 intercept cells
have three expected repair targets each. The q2-plus-q2 phylo intercept cell has
five expected repair targets and continues to exclude the held
`cor_sigma1_sigma2` target.

Then ran the same five repair-smoke cells on Totoro from the staged
`77b634eda91b` source with five single-threaded R processes. The imported
artifacts live under
`docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro/`.
The dispatch sidecar now records three observed targets for each q2 intercept
cell and five observed targets for the q2-plus-q2 phylo intercept cell.

## 3a. Decisions and Rejected Alternatives

The sidecar records imported smoke artifacts only as diagnostic rows. The four
q2 intercept cells are
`repair_smoke_mcse_gt_0.01_review_required_no_promotion`; the q2-plus-q2 phylo
intercept cell is `repair_smoke_finiteness_review_required_no_promotion`.
Every row remains `promotion_decision = do_not_promote`.

I rejected treating the Totoro smoke as a support-cell promotion because these
are small smoke denominators, not SR475/SR1000 coverage evidence, and the
results still contain MCSE and profile-finiteness blockers.

Totoro is recorded as useful for fast bounded smoke work, with worker caps and a
cleanup obligation. Trillium is now connected, but denominator-sensitive use
still waits for source/root synchronization and an artifact root that can be
reviewed after the run.

## 4. Files Touched

- `tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-dispatch/structured-re-q2-retained-denominator-repair-smoke-command.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro/`
- `docs/dev-log/after-task/2026-06-30-q-series-q2-retained-denominator-repair-smoke-dispatch.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/run-structured-re-q2-retained-denominator-repair-smoke.R --host-class=local_repair_smoke --host-name=local --output-root=docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-dispatch --overwrite=true --write-dashboard=false --dry-run=true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R --manifest=docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-dispatch/structured-re-q2-retained-denominator-repair-smoke-command.tsv --overwrite=true`: passed.
- Minimal sync to Totoro of `tools/run-structured-re-q2-retained-denominator-repair-smoke.R` and `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`: passed.
- Totoro q2 retained-denominator repair smoke: five commands ran in parallel, all status `0`; four q2 intercept cells ran `n_rep = 32`, and q2-plus-q2 ran `n_rep = 16`.
- Local import of Totoro results, metadata, and logs by `rsync`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R --manifest=docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro/structured-re-q2-retained-denominator-repair-smoke-command-local.tsv --overwrite=true --require-artifacts=true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok` and five structured RE q2 retained-denominator repair-smoke dispatch rows.
- `git diff --check -- tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-dispatch/structured-re-q2-retained-denominator-repair-smoke-command.tsv`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10006 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

Mission control now checks for the summarizer text, the dispatch TSV, exact
no-promotion wording, Fisher/Rose/Grace review language, and the five-row
dispatch count. It accepts either manifest-only rows or imported artifact rows,
but imported rows must resolve source summaries, replicate TSVs, seed manifests,
and recorded finite/coverage fields.

The focused R test executes the summarizer on a temporary dry-run manifest,
reads the generated sidecar, and checks exact cell IDs, artifact status,
expected target counts, manifest-only zero observed target rows, and
`do_not_promote`. It also checks the real dashboard sidecar allows only guarded
artifact statuses and does not inherit support-cell status.

## 7a. Issue Ledger

No GitHub issue or PR thread was opened or closed in this slice. The branch
already has a broad Q-Series PR surface; this task only adds local evidence
plumbing and records the no-promotion state for later review.

## 8. Consistency Audit

No support-cell status changed. The sidecar is separate from
`structured-re-q-series-support-cells.tsv` and therefore cannot make a row
`inference_ready` by appearing in the widget. The imported rows all remain
diagnostic-only, point to local Totoro artifacts, and name the required
Fisher/Rose/Grace review before any top-up or status edit.

I reran mission control after adding the validator hook and reran the focused
structured conversion contract tests. I also checked whitespace with
`git diff --check` on the touched files.

## 9. What Did Not Go Smoothly

The focused test run that was live before context compaction did not survive as
a pollable process, so I reran it cleanly and recorded the fresh result. The
first Totoro launch also failed before any smoke command ran because the remote
R process did not inherit the `OUT`, `META`, and `LOG` paths. I relaunched with
those paths exported; the five smoke commands then ran cleanly.

A broad `git diff` is very large on this branch because the Q-Series arc already
has many untracked and modified artifacts; I kept this slice scoped to the new
dispatch/import sidecar and its guards.

## 10. Known Residuals

This promotes exactly no Q-Series row. The Totoro q2 retained-denominator repair
smoke is a small diagnostic smoke only, not SR475/SR1000 coverage evidence.

The four q2 intercept rows still have MCSE above 0.01 at `n_rep = 32`. The
q2-plus-q2 phylo intercept row still has a profile-finiteness issue:
`n_profile_finite_min = 14` across the five imported targets. These rows need
Fisher/Rose/Grace review before any top-up is justified.

Trillium is connected, but source/root synchronization and an artifact root
check are still required before using it for denominator-sensitive Q-Series
work.

## 11. Team Learning

Dispatch readiness, smoke results, and support-cell status should remain three
separate surfaces. Totoro, Nibi, Rorqual, Fir, and Trillium can speed the arc,
but the status table should only move after raw artifacts, denominator rules,
one-sided misses, and reviewer sign-off are all present.
