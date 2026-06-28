# Q-Series non-Gaussian status widget

## 1. Goal

Surface all 37 non-Gaussian Q-Series rows on the mission-control widget without
promoting non-Gaussian interval, coverage, REML, AI-REML, bridge, or support
claims.

## 2. Implemented

Added `structured-re-nongaussian-status-audit.tsv`, a 37-row dashboard sidecar
that joins to every non-Gaussian support cell. The widget now distinguishes
`non_gaussian_recovery_only`, `non_gaussian_point_only`,
`non_gaussian_rejected`, and `non_gaussian_planned`. The validator enforces the
37-row count, family distribution, widget-state counts, linked support-cell
status parity, local evidence paths, recovery-result linkage for the eight
recovery rows, and no-promotion language.

## 3a. Decisions and Rejected Alternatives

I rejected calling the eight Poisson/NB2 one-slope recovery rows
`inference_ready`: their banked evidence is convergence plus SD bias/RMSE, not
calibrated intervals or coverage.

I rejected merging point-only count intercept and `phylo_interaction()` rows
with recovery rows because they do not have a recovery denominator yet.

I kept unsupported non-Gaussian family, scale, zero-inflation, hurdle, labelled
count covariance, and multi-provider count rows as rejection-contract rows
rather than planned support.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-nongaussian-status-widget.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells and 37 non-Gaussian status-audit rows.
- `tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r70`.
- `curl -fsS http://127.0.0.1:8765/structured-re-nongaussian-status-audit.tsv | wc -l`: returned 38 lines, meaning header plus 37 audit rows.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: Q-Series board rendered the `NG recovery`, `NG point`, `NG rejected`, `NG planned`, and `Non-Gaussian` summary cards plus representative recovery, rejection, and planned cell IDs.
- `git diff --check`: no whitespace errors.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-28-q-series-nongaussian-status-widget.md')"`: after-task structure check passed.

## 6. Tests of the Tests

The validator now fails if the non-Gaussian sidecar omits any non-Gaussian
support cell, includes a Gaussian cell, changes the expected family or
widget-state counts, drifts from the linked support-cell fit/interval/coverage
statuses, loses the local evidence path, marks any row for promotion, or
disconnects a recovery-only row from the 80-rep recovery-results table.

## 7a. Issue Ledger

- Eight Poisson/NB2 one-slope rows have recovery evidence only.
- Ten count or `phylo_interaction()` rows have point/extractor evidence only.
- Eighteen unsupported rows remain intentional rejections.
- One non-count/extended-count structured-slope bucket remains future design
  work.

## 8. Consistency Audit

Checked the source 104-row support-cell TSV, non-Gaussian family counts,
count-recovery sidecar, rejection-contract sidecars, widget state ordering,
dashboard README wording, and mission-control validator. Every non-Gaussian row
still has `interval_status = unsupported`.

## 9. What Did Not Go Smoothly

The existing generic `recovery_only` widget state was too broad once the board
started carrying full non-Gaussian status. The count recovery rows now use the
more explicit `non_gaussian_recovery_only` state while still displaying the
existing recovery metrics.

## 10. Known Residuals

This tranche does not add new simulations or interval methods. The remaining
non-Gaussian scientific work is family-specific DGP design, recovery grids,
then separate interval/coverage methods only if the recovery evidence warrants
them.

## 11. Team Learning

Non-Gaussian rows need a different vocabulary from Gaussian rows. Recovery,
point fit, intentional rejection, and future family design are distinct states;
compressing them into one "tried" or "unsupported" label hides useful planning
information.
