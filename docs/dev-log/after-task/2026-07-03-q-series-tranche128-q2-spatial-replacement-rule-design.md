# After Task: Q-Series Tranche 128 q2 Spatial Replacement-Rule Design

## 1. Goal

Bank a no-compute q2 row-blocker design slice after the T127 compute gate, so the Q-Series campaign can keep moving without running the gated q1 `mu` one-slope Rorqual smoke.

## 2. Implemented

- Added `structured-re-q2-slope-tranche128-spatial-replacement-rule-design.tsv` with seven rows: spatial source review, spatial `mu2:x` tail-balance blocker, spatial direct-correlation blocker, future g32 route shape, animal fixed-8 hold, no-compute boundary, and tranche summary.
- Appended SC448 member-board rows for Ada, Rose, Fisher, Gauss, Noether, Grace, Curie, Boole, and Emmy. Rose/Fisher/Gauss/Noether/Grace remain blocking for any T129 execution or status claim.
- Wired Mission Control build `r321` to load, count, render, and validate the T128 sidecar while preserving the Q-Series board argument order.
- Updated the q2 spatial/animal row-blocker queue so the next action is Tranche 129 contract drafting only.
- Updated the dashboard README, Q-Series completion map, validator, and focused conversion-contract tests.

## 3a. Decisions and Rejected Alternatives

T127 was left untouched because the current checkpoint says it must not run until Rose/Fisher/Gauss/Noether/Grace approve the exact host-separated Rorqual model-smoke command. T128 instead selects the cheaper q2 design lane: draft a future spatial-only g32 retained-denominator profile/Wald/bias+t comparison contract before spending any compute.

Animal q2 is explicitly held out. The fixed-8 pedigree row does not inherit spatial g32 evidence and needs an animal-specific calibration route later. No q2 coverage grid, SR475/SR1000 top-up, status edit, REML, AI-REML, bridge support, or public support was authorized.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-slope-tranche128-spatial-replacement-rule-design.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-q-series-tranche128-q2-spatial-replacement-rule-design.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py` passed.
- Dashboard JavaScript extracted to `/tmp/drmtmb-mission-control-index-r321.js`; `/Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node --check /tmp/drmtmb-mission-control-index-r321.js` passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py` passed with `104 structured RE q-series cells`, `8 structured RE q-series inference-evidence summary rows`, and `7 structured RE q2 slope Tranche 128 spatial replacement-rule design rows`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'` passed.
- Invariant scan passed: 104 Q-Series cells, 8 rows with both interval and coverage `inference_ready`, 0 structured `supported` rows, and 0 q4 coverage-authorized rows.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-03-q-series-tranche128-q2-spatial-replacement-rule-design.md')"` passed.
- `git diff --check` passed.

## 6. Tests of the Tests

The validator first failed because the T128 route-shape row did not spell out the no-host-command/no-model-run boundary and because two SC448 blocking reviewer next gates did not say `contract`. Those failures proved the new guards check the intended claim boundary rather than only row presence.

The focused R test now reads the T128 sidecar, q-series support cells, campaign queue, and member discussions. It would fail if T128 created compute, authorized coverage, promoted a support cell, dropped the animal hold, lost SC448 blocking reviewers, or moved the queue away from T129 contract drafting.

## 7a. Issue Ledger

No GitHub issue was opened or updated in this slice. This was a local Mission Control tranche ledger and validator update only.

## 8. Consistency Audit

The dashboard load path, render argument order, KPI count, sidecar note, validator read path, validator success summary, member-board allowlist, focused R tests, queue row, README, and completion map all now name the T128 sidecar. The q2 spatial and animal one-slope support cells remain `point_fit/extractor_ready/fixture_parity/planned/planned`, and T128 does not change public APIs, formula grammar, `R/`, `src/`, README, NEWS, pkgdown, or support-cell statuses.

## 9. What Did Not Go Smoothly

The first partial dashboard wiring had a quiet argument-order risk: T128 was passed to `renderQSeriesBoard()` but the parameter list had not been updated, which would have shifted later q2 diagnostic sidecars. The validator now checks the row-gate -> T128 -> g32 ordering string to catch that class of drift.

## 10. Known Residuals

T128 is route-design evidence only. No T129 contract has been written, no command has been approved, no model has been run, no retained denominator exists, and no q2 spatial or animal row has moved toward `inference_ready` or `supported`. T127 also remains compute-gated and untouched.

## 11. Team Learning

When adding a new Mission Control sidecar to an already long render call, validate the argument order as well as the TSV load and KPI count. A sidecar that renders in the wrong slot is worse than a missing sidecar because it can make the dashboard look coherent while carrying the wrong evidence.
