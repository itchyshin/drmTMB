# After Task: Q-Series Gaussian mu-slope split calibration

## 1. Goal

Test whether the Gaussian q1 `mu` one-slope upper-tail blocker can be resolved
by a split-sample, endpoint-class calibration before using Totoro/FIIA/DRAC or
editing any support-cell status.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian q1 `mu` split-
calibration channel, with SR150 calibration plus SR325 holdout replay only, and
does not claim `inference_ready`, `supported`, sigma readiness, q2/q4/q8
readiness, non-Gaussian interval readiness, REML, AI-REML, bridge support, or
public support.

Added `tools/summarize-structured-re-gaussian-mu-slope-split-calibration.R`.
The script reads the retained SR150/base and SR475/top-up artifacts, overlays
the boundary-profile endpoint repairs, learns one log-upper endpoint offset for
`mu:(Intercept)` and one for `mu:x` on the SR150/base slice, and validates those
frozen constants on the SR325/top-up holdout.

The script writes:

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-split-calibration.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-split-calibration-local/structured-re-gaussian-mu-slope-split-calibration.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-split-calibration-local/structured-re-gaussian-mu-slope-split-calibration-constants.tsv`

The learned upper multipliers are 1.0556 for `mu:(Intercept)` and 1.2777 for
`mu:x`. The intercept holdout targets pass the local screen only. The slope
holdout targets fail: phylo fails miss-balance plus MCSE, relmat exceeds the
upper coverage bound, and spatial misses the MCSE gate. Mission control now
validates all six holdout rows and both learned constants, and the widget
renders a "Mu split cal" card/table at build `r116`.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as retained-artifact replay evidence, not an interval
implementation or `confint()` default.

Decision: do not use Totoro, FIIA, Nibi, Rorqual, or DRAC for this lane yet.
The slope holdout failures mean a larger denominator would spend cluster time
on a rule already blocked locally.

Decision: do not use provider-specific constants. The screen used endpoint-
class constants only; needing provider-specific constants would block the rule.

Rejected alternatives:

- Do not promote the intercept rows from screen-only holdout passes because the
  slope rows fail and the support cells are one-slope row contracts, not
  endpoint-only status rows.
- Do not run a cluster smoke after slope holdout failures.
- Do not use this split calibration for sigma, q2, q4/q8, non-Gaussian rows,
  REML, AI-REML, bridge, `supported`, or public-support claims.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-mu-slope-split-calibration.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-split-calibration.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-split-calibration-local/structured-re-gaussian-mu-slope-split-calibration.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-split-calibration-local/structured-re-gaussian-mu-slope-split-calibration-constants.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-split-calibration.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/summarize-structured-re-gaussian-mu-slope-split-calibration.R --overwrite=true`:
  passed; wrote six split-calibration rows and two learned constants.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-mu-slope-rule-screen.R tools/summarize-structured-re-gaussian-mu-slope-split-calibration.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 13 Gaussian mu-slope rule-screen
  rows and 6 Gaussian mu-slope split-calibration rows.
- Dashboard JavaScript parse check: passed with `dashboard_js_parse_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7359 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-rule-screen.md'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-split-calibration.md')"`:
  passed for both after-task reports.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt`
  returned `r116`, the split-calibration TSV served 7 lines including the
  header, the rule-screen TSV served 14 lines including the header, `/`
  contained `Mu split cal`, `/` contained the split-calibration TSV fetch path,
  and the split-calibration TSV contained
  `upper_lower_miss_ratio_above_2;mcse_above_0_01`.

## 6. Tests of the Tests

The new focused test requires exactly six split-calibration rows, three
intercept `holdout_gate_passed_screen_only` rows, three slope
`holdout_gate_failed` rows, the exact learned constants, non-promotional smoke
decisions, and claim boundaries that forbid `inference_ready`, `supported`,
sigma, q2, q4/q8, non-Gaussian, REML, AI-REML, and public-support claims.

Mission control also compares the dashboard TSV against the artifact TSV,
validates the constants artifact, and requires all rows to block smoke.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence hygiene inside the active Q-Series board.

## 8. Consistency Audit

Checked the split-calibration sidecar, constants artifact, retained rule
screen, target-level interval-shape diagnostic, dashboard renderer, dashboard
README, validator, and focused tests.

The board remains 104 rows with exactly five interval-and-coverage
`inference_ready` rows and no structured `supported` row. The split calibration
does not change support-cell status and does not authorize a cluster smoke.

## 9. What Did Not Go Smoothly

Nothing was promoted because the holdout did its job: it exposed the remaining
slope failures before cluster time was spent. This is a negative result, but it
is useful negative evidence.

## 10. Known Residuals

Gaussian q1 `mu` one-slope remains blocked. A replacement rule still needs a
principled derivation or external statistical rationale, replay on retained
artifacts, Fisher/Rose/Noether review, and only then a small Totoro/FIIA smoke
before any DRAC denominator campaign. q4/q8, spatial/animal q2, spatial sigma,
and non-Gaussian interval rows remain separate unfinished arcs.

## 11. Team Learning

Split-sample replay is a better gate than widening from the full retained
denominator. It can save cluster time by separating promising endpoint classes
from rules that still fail holdout coverage, MCSE, or miss-balance gates.
