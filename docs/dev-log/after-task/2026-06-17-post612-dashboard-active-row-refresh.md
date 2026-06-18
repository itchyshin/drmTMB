# Post-#612 Dashboard Active-Row Refresh

## Goal

Refresh mission-control current-state text after PR #612 merged, so the live
dashboard names the actual active finish-board row and records the current
post-merge evidence.

## Implemented

- Updated `docs/dev-log/dashboard/status.json` to `2026-06-17 19:55 MDT`.
- Replaced stale active-work text that still pointed to post-#611 evidence and
  a vague cross-team or Phase 2 choice.
- Named `drmTMB#59` numerical-guard sensitivity as the one active finish-board
  row.
- Kept the Phase 2 `engine_control` slice queued rather than implying bridge
  control work had started.
- Updated `docs/dev-log/dashboard/sweep.json` with the same current-state
  summary.
- Recorded post-#612 `main` R-CMD-check and pkgdown evidence for `6386eb8`.

## Mathematical Contract

No model, likelihood, estimator, simulation result, or interval method changed.
The numerical-guard row remains active because only the first fixed-effect
Gaussian `log(sigma)` clamp pilot and ADEMP/Williams design are banked; broader
guard classes, interval coverage, random or structured routes, bivariate scale
routes, and release claims remain planned.

## Files Changed

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-post612-dashboard-active-row-refresh.md`

## Checks Run

- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `sh tools/start-mission-control.sh --background`
- `curl -fsS http://127.0.0.1:8765/status.json | jq '{updated, metrics, active_work}'`

## Tests Of The Tests

The mission-control validator is the relevant test because this slice changes
dashboard state, not package behavior. It checks that dashboard counts,
finish-board rows, Julia registry artifacts, and public-claim wiring remain
internally consistent. The live `curl` check verifies that the served dashboard
uses the edited source state.

## Consistency Audit

The refreshed text now separates three statuses that were easy to conflate:
Phase 1 is verified, the Phase 2 `engine_control` row is queued, and the active
finish-board row is `drmTMB#59` numerical-guard sensitivity. It also replaces
the older post-#611 evidence with the post-#612 `main` checks for `6386eb8`.

## GitHub Issue Maintenance

No new issue was opened. `drmTMB#59` remains the active numerical-guard
simulation umbrella. This report records the dashboard alignment; the next
guard-class artifact lane should update `drmTMB#59` with new evidence when it
actually produces simulation results.

## What Did Not Go Smoothly

The dashboard metrics had already moved to one active row, but the active-work
prose still described the next queue as a cross-team or Phase 2 choice. That
was not a validator failure because the validator checks schema and count
consistency, not whether prose names the active row.

## Team Learning

When `metrics.active` is nonzero, the active-work text should name the active
finish-board row explicitly. Otherwise the next agent can follow stale prose
instead of the row-level board.

## Known Limitations

This refresh does not implement a numerical-guard simulation lane, relax any
Julia bridge gate, add `engine_control`, promote q8, update release readiness,
or change any package runtime behavior.

## Next Actions

- Continue `drmTMB#59` by choosing one guard-class artifact lane from
  `docs/design/176-numerical-guard-simulation-audit.md`.
- Alternatively start the queued Phase 2 `engine_control` rejection slice only
  as a separate scoped branch with tests, docs, dashboard evidence, and issue
  maintenance.
