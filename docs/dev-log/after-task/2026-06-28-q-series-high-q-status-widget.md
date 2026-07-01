# Q-Series high-q status widget

## 1. Goal

Surface all 24 q4/q6/q8 Q-Series rows on the mission-control widget as
high-q status rows without promoting any of them to `inference_ready`.

## 2. Implemented

Added `structured-re-high-q-status-audit.tsv`, a 24-row dashboard sidecar that
joins to every q4, q6, and q8 support cell. The widget now shows
`high_q_gate_required` for q4 fixture rows, `q8_stability_blocked` for ordinary
and structured q8-shaped rows with stability blockers, `high_q_diagnostic` for
ordinary/direct-SD high-q comparator rows, and `high_q_planned` for broader q6
and q8 future-design rows. The validator reads the sidecar and enforces row
coverage, widget-state counts, linked support-cell status parity, evidence
paths, and no-promotion language.

## 3a. Decisions and Rejected Alternatives

I rejected treating q4 point/fixture parity as inference readiness. Those rows
still need denominator policy, direct-SD interval rules, derived-correlation
interval machinery, and calibrated coverage before any promotion.

I rejected treating q8 as coverage-ready. The ordinary q8 audit records weak
Hessian behaviour and no usable Wald intervals, while structured q8-shaped rows
have point/fixture evidence but not stable interval denominators.

I kept q6 rows as planned or diagnostic rather than assigning them q4 evidence
by analogy.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-high-q-status-widget.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells and 24 high-q status-audit rows.
- `tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r69`.
- `curl -fsS http://127.0.0.1:8765/structured-re-high-q-status-audit.tsv | wc -l`: returned 25 lines, meaning header plus 24 audit rows.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: Q-Series board rendered the `High-q gate`, `q8 stability`, `High-q diagnostic`, and `High-q planned` summary cards plus representative q4/q8 cell IDs.
- `git diff --check`: no whitespace errors.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-28-q-series-high-q-status-widget.md')"`: after-task structure check passed.

## 6. Tests of the Tests

The validator now fails if the high-q sidecar omits any q4/q6/q8 support cell,
adds a non-high-q cell, changes the expected widget-state counts, drifts from
the linked support-cell fit/interval/coverage statuses, marks a row for
promotion, or loses the local evidence path.

## 7a. Issue Ledger

- q4 fixture rows: point and same-target fixture evidence exist, but interval
  and coverage gates remain unpassed.
- q8-shaped rows: point/fixture evidence exists for the shared-label all-four
  one-slope cells, but Hessian and lower-bound geometry block inference.
- q6 and broader q8 rows: planned rows remain future design work.

## 8. Consistency Audit

Checked the 104-row support-cell TSV, q4/q6/q8 row counts, the high-q sidecar,
widget state ordering, dashboard README wording, mission-control validator, and
the q8 diagnostic audit cited by the ordinary q8 row. The only rows with
interval plus coverage `inference_ready` remain the two q1 sigma and two q2
location-slope rows.

## 9. What Did Not Go Smoothly

The existing admission overlay assumed every blocker sidecar had a
`wald_finite_summary` field. The q2 and high-q sidecars need different summary
fields, so the widget renderer now falls back across the sidecar-specific
summary columns.

## 10. Known Residuals

This is not a q4 or q8 numerical fix. The next scientific work is still q4
denominator admission, derived-correlation interval machinery, q4 calibrated
coverage after the denominator rules pass, and q8 stability before any coverage
grid.

## 11. Team Learning

High-dimensional rows need their own board vocabulary. A single `planned` or
`tried` label hides the difference between q4 fixture gates, q8 stability
blockers, ordinary diagnostic comparators, and true future-design rows.
