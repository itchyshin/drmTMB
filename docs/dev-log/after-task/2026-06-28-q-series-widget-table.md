# After-task: Q-Series widget table

Meta: 2026-06-28 · Codex · branch `codex/qseries-sigma-inference-ready`;
dashboard build `r64`.

## 1. Goal

Make the mission-control widget show the full 104-row Q-Series support-cell
table near the top of the page, with fit/stability and inference readiness kept
separate. The goal was visibility and claim-boundary hygiene, not a status
promotion.

## 2. Implemented

- Added a `Q-Series Support Cells` panel immediately after the top metrics in
  `docs/dev-log/dashboard/index.html`.
- Wired the panel to
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, so the
  widget renders all 104 source rows directly.
- Added summary cards for total rows, inference-ready rows, fit-supported
  baseline rows, tried rows, diagnostic rows, planned rows, unsupported/blocked
  rows, high-q rows, and q8 rows.
- Added separate columns for row state, fit/stability, inference readiness, raw
  fit status, interval status, coverage status, evidence, and next gate.
- Updated pill labels to display human-readable spaces while keeping the source
  status strings unchanged in the TSV.
- Updated the dashboard README, dashboard timestamp, and build marker
  (`version.txt` and `BUILD`) to `r64`.

## 3a. Decisions and Rejected Alternatives

The widget derives display-only categories from existing TSV fields. A row is
shown as inference-ready only when both `interval_status` and
`coverage_status` are `inference_ready`.

Rejected alternatives:

- Do not add a new TSV or duplicate the 104 rows in JSON.
- Do not change any source Q-Series status row.
- Do not collapse point-fit, fixture parity, interval feasibility, and coverage
  readiness into one status.
- Do not use the table to imply q4/q8 or non-Gaussian inference readiness.

## 4. Files Touched

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-widget-table.md`

## 5. Checks Run

- Extracted the dashboard script from `docs/dev-log/dashboard/index.html` and
  ran `node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `python3 tools/validate-mission-control.py`: passed and reported 104
  structured RE Q-Series cells.
- `git diff --check`: passed.
- `tools/start-mission-control.sh --background`: passed; dashboard already
  listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r64`.
- Served-asset scan confirmed the live dashboard includes `Q-Series Support
  Cells`, `qSeriesSupportState`, `qSeriesStability`, `qSeriesInference`, and the
  TSV fetch for `structured-re-q-series-support-cells.tsv`.

## 6. Tests of the Tests

The served TSV under `/tmp/drm-dashboard` was summarized independently of the
browser renderer. It reported 104 rows and these derived display-state counts:
4 inference-ready, 3 fit-supported baseline, 43 tried-not-ready, 6 diagnostic,
8 planned, and 40 unsupported/blocked.

The same served-TSV check reported separate stability counts: 69 fit-stable, 3
stable fit-baseline, 2 diagnostic-only, 9 planned, and 21 unsupported/blocked.
Separate inference-readiness counts were 4 inference-ready, 4 interval-feasible,
6 diagnostic-only, 50 planned, and 40 inference-blocked.

## 7a. Issue Ledger

No GitHub issue or PR comment was added. This was a local dashboard visibility
patch over existing Q-Series source-of-truth data.

## 8. Consistency Audit

The source TSV was not edited. The dashboard README now documents that the
widget separates row state, fit/stability state, inference readiness, interval
status, and coverage status. The new display preserves the current Q-Series
boundary: q4/q8 and non-Gaussian rows are visible but not promoted.

The current live-source counts remain 104 Q-Series rows, with exactly four rows
displayed as inference-ready because both interval and coverage statuses are
`inference_ready`.

## 9. What Did Not Go Smoothly

Playwright was available as a package, but its bundled Chromium binary was not
installed in the local cache. I did not install a browser during this patch.
Instead I used JavaScript syntax checking, mission-control validation, live
asset checks, and served-TSV summary checks.

## 10. Known Residuals

- The table is a static all-row view; it does not yet have filters, search,
  sticky headers, or column sorting.
- Stability labels are derived only from current TSV status fields. They do not
  inspect per-replicate simulation artifacts.
- No Q-Series row was promoted by this patch.

## 11. Team Learning

When the maintainer asks "what is left?", the widget should expose the row-level
source of truth directly. Summary prose is useful, but a 104-row table with
separate stability and inference columns makes overclaiming easier to catch.
