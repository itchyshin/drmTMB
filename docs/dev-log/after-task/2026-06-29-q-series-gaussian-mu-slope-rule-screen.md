# After Task: Q-Series Gaussian mu-slope rule screen

## 1. Goal

Move the Gaussian q1 `mu` one-slope blocker lane forward without using
Totoro/FIIA/DRAC: replay retained SR150/SR475 artifacts under simple candidate
interval variants and decide whether any candidate is smoke-ready.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian q1 `mu` rule-screen
channel, with retained-artifact replay only, and does not claim
`inference_ready`, `supported`, sigma readiness, q2/q4/q8 readiness,
non-Gaussian interval readiness, REML, AI-REML, bridge support, or public
support.

Added `tools/summarize-structured-re-gaussian-mu-slope-rule-screen.R`. The
script overlays the existing endpoint-profile boundary repairs onto the SR150
and SR475 retained denominator artifacts, then screens 13 candidate interval
variants:

- the current hybrid Wald/profile channel;
- upper-endpoint multipliers at 1.25, 1.50, 2.00, and 3.00;
- log-width multipliers at 1.25, 1.50, 2.00, and 3.00;
- profile-boundary upper multipliers at 1.25, 1.50, 2.00, and 3.00.

The script writes:

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-rule-screen.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-rule-screen-local/structured-re-gaussian-mu-slope-rule-screen.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-rule-screen-local/structured-re-gaussian-mu-slope-rule-screen-target-detail.tsv`

The screen has 13 summary rows and 78 target-detail rows. The current hybrid
channel has 23 lower misses and 73 upper misses across the six target rows. The
2x upper-endpoint multiplier still leaves one upper-heavy target. The only
variants that erase all upper misses are 3x upper-endpoint or 3x log-width
inflations, so they are labelled `large_ad_hoc_multiplier_screen_only` and
blocked from smoke. The profile-boundary-only multipliers do not fix the Wald
upper misses.

Mission control now validates the summary and target-detail artifacts, and the
widget renders a "Mu rule screen" table above the detailed 104-row ledger. The
dashboard build is `r115`.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as a local rule screen, not a new interval implementation.
The candidate variants are post hoc retained-artifact screens and are not
`confint()` defaults.

Decision: do not use Totoro, FIIA, Nibi, Rorqual, or DRAC. The screen says the
next useful work is a principled skew-aware or boundary-aware interval rule,
not a broader denominator.

Decision: do not promote any q1 `mu` support cell. The four linked rows remain
`interval_status = planned` and `coverage_status = planned`.

Rejected alternatives:

- Do not accept a 2x upper-endpoint multiplier because one target remains
  upper-tail blocked.
- Do not accept 3x upper-endpoint or 3x log-width multipliers because they are
  large ad hoc retained-artifact screens, not a derived interval rule.
- Do not use a profile-boundary-only multiplier because it leaves the ordinary
  Wald upper misses unresolved.
- Do not use any rule-screen result for sigma, q2, q4/q8, non-Gaussian, REML,
  AI-REML, bridge, `supported`, or public-support claims.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-mu-slope-rule-screen.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-rule-screen.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-rule-screen-local/structured-re-gaussian-mu-slope-rule-screen.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-rule-screen-local/structured-re-gaussian-mu-slope-rule-screen-target-detail.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-rule-screen.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/summarize-structured-re-gaussian-mu-slope-rule-screen.R --overwrite=true`:
  passed; wrote 13 rule-screen rows and 78 target-detail rows.
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
  returned `r116`, the rule-screen TSV served 14 lines including the header,
  and `/` contained the rule-screen TSV fetch path.

## 6. Tests of the Tests

The new focused test requires 13 candidate rows, 78 target-detail rows, exact
candidate families, non-promotional smoke decisions, and claim boundaries that
say the candidates are post hoc retained-artifact screens rather than
`confint()` defaults. If a future edit turns a candidate into smoke-ready or
removes the no-promotion wording, the focused contract test fails.

Mission control also checks the dashboard TSV against the artifact TSV and
requires the target-detail artifact to contain exactly six target rows per
candidate, scoped only to phylo, relmat, and spatial q1 `mu` one-slope rows.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence hygiene inside the active Q-Series board.

## 8. Consistency Audit

Checked the rule-screen sidecar, target-detail artifact, interval-shape
diagnostic, hybrid SR475 audit, support-cell statuses, dashboard renderer,
dashboard README, validator, and focused tests.

The board remains 104 rows with exactly five interval-and-coverage
`inference_ready` rows and no structured `supported` row. The rule screen does
not change support-cell status and does not authorize a cluster smoke.

## 9. What Did Not Go Smoothly

The first two script runs caught small R construction bugs in the candidate
data frame and label assignment. Both were fixed before any artifacts were
accepted.

## 10. Known Residuals

Gaussian q1 `mu` one-slope remains blocked. A replacement rule still needs a
principled derivation or external statistical rationale, target-scoped replay,
Fisher/Rose/Noether review, and then a small smoke before any denominator
campaign. q4/q8, spatial/animal q2, spatial sigma, and non-Gaussian interval
rows remain separate unfinished arcs.

## 11. Team Learning

When a retained denominator shows shape failure, a local replay screen is a
cheap way to avoid wasting cluster time. If only very large ad hoc multipliers
repair the miss table, the next step is derivation, not a larger run.
