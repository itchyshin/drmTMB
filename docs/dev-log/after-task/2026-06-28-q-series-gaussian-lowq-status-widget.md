# Q-Series Gaussian low-q status widget

## 1. Goal

Surface the remaining 35 Gaussian low-q Q-Series rows on the
mission-control widget without promoting interval, coverage, REML, AI-REML,
bridge, structured covariance, or support claims.

## 2. Implemented

Added `structured-re-gaussian-lowq-status-audit.tsv`, a 35-row dashboard
sidecar covering the remaining Gaussian q1, q1-plus-q1, q2, and q2-plus-q2
rows after exact `inference_ready`, sigma/q2 admission, high-q, and
non-Gaussian rows are accounted for. The widget now distinguishes
`gaussian_baseline_comparator`, `gaussian_lowq_gate_required`,
`gaussian_lowq_diagnostic`, and `gaussian_lowq_rejected`. The validator
enforces the 35-row count, the 3 / 27 / 2 / 3 state split, linked
support-cell fit/interval/coverage parity, local evidence paths, and
no-promotion language.

## 3a. Decisions and Rejected Alternatives

I rejected leaving these rows in generic `fit_supported_baseline`,
`tried_not_inference_ready`, `tried_diagnostic`, and
`unsupported_or_blocked` buckets because the user asked for a useful 104-row
widget table with tried, blocked, stability, and inference readiness separated.

I rejected promoting the twenty-seven point/fixture rows: they have fit or
fixture evidence only, not interval plus coverage evidence.

I kept the three ordinary comparator rows separate from structured support
because ordinary Gaussian baselines are useful fit comparators but not
structured covariance evidence.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-gaussian-lowq-status-widget.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells and 35 Gaussian low-q status-audit rows.
- `tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r71`.
- `curl -fsS http://127.0.0.1:8765/structured-re-gaussian-lowq-status-audit.tsv | wc -l`: returned 36 lines, meaning header plus 35 audit rows.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: Q-Series board rendered the `Gaussian baselines`, `Low-q gate`, `Low-q diagnostic`, and `Low-q rejected` cards and representative row labels.
- Overlay state accounting: 104 rows assigned to specific evidence states, 4 `inference_ready`, and no generic `fit_supported_baseline`, `tried_not_inference_ready`, `tried_diagnostic`, `unsupported_or_blocked`, `recovery_only`, or `planned` leftovers.

## 6. Tests of the Tests

The validator now fails if the Gaussian low-q sidecar omits any expected row,
includes a row already owned by inference evidence, sigma/q2 admission, high-q,
or non-Gaussian sidecars, changes the expected widget-state counts, drifts from
linked support-cell fit/interval/coverage statuses, loses a local evidence
path, marks any row for promotion, or drops conservative claim-boundary
wording.

## 7a. Issue Ledger

- Three ordinary Gaussian comparator rows are fit baselines only.
- Twenty-seven Gaussian low-q rows have point/fixture evidence but still need
  row-specific interval and coverage gates.
- Two ordinary Gaussian q2 rows are diagnostic-only.
- Three q2-plus-q2 sigma rows remain unsupported rejection-contract rows.
- No new GitHub issue was opened; this is a PR #685 dashboard/status tranche.

## 8. Consistency Audit

Checked the 104-row support-cell TSV, the inference-evidence sidecar, sigma and
q2 admission sidecars, high-q sidecar, non-Gaussian sidecar, widget ordering,
dashboard README, check-log, and mission-control validator. The support-cell
TSV statuses did not change.

## 9. What Did Not Go Smoothly

The first browser smoke caught an ordering issue: ordinary baseline rows had
the new audit data attached, but the generic fit-baseline fallback still
controlled the visible row state. I moved the audit overlay ahead of the
generic fallback, reran the JavaScript check, refreshed mission control, and
reran the browser smoke.

## 10. Known Residuals

This tranche does not add simulations, intervals, or coverage. The remaining
Gaussian low-q scientific work is still row-specific: sigma/spatial/animal
admission, q2 row-specific calibration, matched `mu+sigma`, and the exact
ordinary diagnostic neighbours all need their own evidence before promotion.

## 11. Team Learning

The Q-Series board now benefits from treating display state as an overlay
owned by evidence sidecars. The source TSV remains the authority, but the
widget can now show why a row is unfinished without turning every unfinished
row into the same vague "tried" bucket.
