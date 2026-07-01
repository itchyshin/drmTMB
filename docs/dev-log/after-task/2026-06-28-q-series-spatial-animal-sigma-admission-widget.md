# Q-Series spatial/animal sigma admission widget

## 1. Goal

Surface the remaining evidence gates for the spatial and animal q1 `sigma`
one-slope support cells in the 104-row Q-Series widget without promoting either
cell to `inference_ready`.

## 2. Implemented

Added a two-row dashboard sidecar,
`structured-re-sigma-slope-spatial-animal-admission-audit.tsv`, for
`qseries_spatial_q1_sigma_one_slope` and
`qseries_animal_q1_sigma_one_slope`. The widget now gives those cells separate
display states: `topup_required` for spatial and `admission_blocked` for
animal. The validator reads and enforces the sidecar, including the spatial
finite-Wald shortfall, the animal missing `sigma:x` coverage row, and the
no-promotion boundary.

## 3a. Decisions and Rejected Alternatives

I rejected promoting spatial q1 sigma because the diagnostic SR475 coverage
grid has both endpoints but the intercept finite-Wald rate is 442/475 =
0.9305, below the 0.95 gate used for row-level inference readiness.

I rejected promoting animal q1 sigma because only `sigma:(Intercept)` has an
SR475 coverage row. The `sigma:x` endpoint remains absent from the coverage
grid and is still a visible denominator holdout in the replicated-denominator
rule.

I kept these as widget display states rather than TSV status promotions so
`interval_status` and `coverage_status` remain the scientific source of truth.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-sigma-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-spatial-animal-sigma-admission-widget.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells and 2 sigma-slope spatial/animal admission-audit rows.
- `tools/start-mission-control.sh --background`: passed; dashboard served at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r67`.
- `curl -fsS http://127.0.0.1:8765/structured-re-sigma-slope-spatial-animal-admission-audit.tsv | wc -l`: returned 3 lines.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: passed; the Q-Series board rendered `topup required`, `admission blocked`, `qseries_spatial_q1_sigma_one_slope`, and `qseries_animal_q1_sigma_one_slope`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test()'`: passed, `19604 PASS / 0 FAIL / 17 WARN / 43 SKIP`.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-28-q-series-spatial-animal-sigma-admission-widget.md')"`: passed.

## 6. Tests of the Tests

The validator now fail-closes the new ledger: it requires exactly two audit
rows, requires spatial to retain the SR475 coverage metrics, requires animal
`sigma:x` to remain absent from the coverage grid, requires denominator-rule
actions to match the existing rule sidecar, and requires both linked support
cells to remain `planned` for interval and coverage.

## 7a. Issue Ledger

- Spatial q1 sigma one-slope: diagnostic coverage exists, but the intercept
  finite-Wald rate is below the promotion gate, so the next state is top-up,
  not promotion.
- Animal q1 sigma one-slope: `sigma:x` has a denominator-admission blocker and
  no coverage-grid row, so the next state is admission repair, not promotion.

## 8. Consistency Audit

Checked the support-cell TSV, sigma coverage results, denominator-admission
sidecar, replicated-denominator sidecar, stability probe, widget JavaScript,
dashboard README, and validator. The row-level support statuses remain
unchanged: spatial and animal q1 sigma one-slope are still `planned` for both
interval and coverage.

## 9. What Did Not Go Smoothly

The first dashboard patch missed the exact CSS context and had to be split into
smaller edits. No generated files or status rows were reverted.

## 10. Known Residuals

Spatial still needs retained-denominator top-up evidence, preferably to SR1000
or an equivalent reviewed DRAC/Totoro run. Animal still needs the `sigma:x`
endpoint-profile admission gap reconciled before a coverage grid can include
both endpoints.

## 11. Team Learning

When a row has partial coverage evidence, the widget needs a display state that
separates "we tried this" from "this is promotable." Keeping that state outside
the support-cell scientific columns prevents status drift while still showing
the maintainer what is left.
