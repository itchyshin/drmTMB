# After Task: Q-Series q2 row-gate synthesis

## 1. Goal

Make the remaining spatial/animal q2 `mu1+mu2` one-slope blockers visible near
the top of the Q-Series widget without changing either linked support-cell
status.

## 2. Implemented

This promotes exactly no q-series row under the `default_bias_t_location_wald`
interval channel with retained SR1000 SD-endpoint evidence and does not claim
spatial q2, animal q2, correlation targets, q4/q8, REML, AI-REML, bridge
support, `supported`, or public support.

Added `structured-re-q2-slope-row-gate-synthesis.tsv`, a two-row gate table for
the spatial and animal q2 `mu1+mu2` one-slope rows. The table summarizes the
SR1000 default bias+t SD endpoint results, retained one-sided tail imbalance,
unresolved correlation target, missing g=32 profile/Wald comparison, linked
planned/planned status, and `do_not_promote` decision.

## 3a. Decisions and Rejected Alternatives

The gate table is a status-synthesis artifact, not a new simulation result. It
uses the SR1000 result sidecar from the Rorqual top-up and the existing
admission audit to make the row-level blockers explicit.

Rejected alternatives:

- Do not promote spatial q2 or animal q2 from SD-endpoint MCSE alone.
- Do not treat SD endpoint evidence as correlation-target evidence.
- Do not treat the q2 default bias+t correction as a q4/q8, REML, AI-REML, or
  bridge claim.
- Do not hide the blocked rows in prose only; the widget now renders them as a
  compact table above the 104-row ledger.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-slope-row-gate-synthesis.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-row-gate-synthesis.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-q2-slope-row-gate-synthesis.tsv
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-row-gate-synthesis.md')"
```

Results: formatting passed; Python compilation passed; mission control passed
with 104 structured RE q-series cells, 5 q-series inference-evidence summary
rows, and 2 q2 slope row-gate synthesis rows; the focused
structured-RE conversion contract test passed with 6548 PASS / 0 FAIL / 0 WARN
/ 0 SKIP; `git diff --check` passed; the served dashboard returned `r97` and
served the new row-gate TSV; this after-task report passed the structure check.

## 6. Tests of the Tests

The validator checks the two exact row ids, linked support-cell ids, endpoint
scope, linked planned/planned statuses, `do_not_promote` decision, evidence URL,
SR1000 endpoint text, required tail/correlation/g=32 blockers, and forbidden
claim boundaries. It also verifies that the linked support-cell rows remain
point-fit/extractor-ready/fixture-parity rows with planned interval and
coverage statuses.

## 7a. Issue Ledger

No GitHub issue action was taken. This is local mission-control evidence
infrastructure for the Q-Series board.

## 8. Consistency Audit

The spatial q2 and animal q2 support cells remain `interval_status = planned`
and `coverage_status = planned`. The widget now shows a two-row q2 gate table
above the full support-cell ledger, and each affected support-cell row links to
the same gate evidence.

## 9. What Did Not Go Smoothly

The implementation was straightforward. The only correction was to patch the
README against its current wrapped text rather than the earlier snippet.

## 10. Known Residuals

The remaining q2 work is still scientific work: resolve spatial and animal
`mu2:x` tail balance, add or reject correlation-target coverage under retained
denominators, run the g=32 profile/Wald comparison, and get Fisher/Rose review
before any status edit.

## 11. Team Learning

When a row is close but blocked, the dashboard needs a compact gate table in
addition to the full support-cell ledger. This makes the next action visible
without making “tried” look like `inference_ready`.

## 12. Next Actions

Use the q2 row-gate synthesis as the next workbench: choose whether the next
slice is tail-shape diagnosis, correlation-target denominator repair, or the
g=32 profile/Wald comparison.
