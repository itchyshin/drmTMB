# After Task: Q-Series q4 Animal Transform-Admission Contract

## 1. Goal

Bank the next animal q4 all-four gate as an admission contract, not as a
cluster run or status promotion. The contract should tell Grace, Gauss, Fisher,
Curie, and Rose exactly when Nibi/Rorqual admission or later DRAC coverage is
allowed.

## 2. Implemented

Added a seven-route `structured-re-q4-animal-transform-admission-contract.tsv`
sidecar for `qseries_animal_q4_all_four_one_slope_planned`. It separates the
zero-correlation reference, current all-free route, fixed soft-cap route,
sparse one-theta localization route, ridge MAP/penalty route,
ridge-continuation annealing route, and the required production-transform
admission experiment.

The Q-Series widget now renders a distinct `Animal q4 transform` summary card,
a compact transform-admission table, a per-row evidence link, and a row-summary
note for the animal q4 all-four cell. The queue, high-q audit, and support-cell
next gate now point first to the lower-level TMB parameterization design in
`docs/design/220-structured-q4-animal-production-transform-gate.md`, then to
the production-transform admission experiment. This is deliberately narrower
than another broad exploratory cluster run.

No support-cell status changed.

## 3a. Decisions and Rejected Alternatives

The ridge-continuation diagnostic was included as a seventh route because it is
live evidence in the checkout: 25 penalty-supported stages stabilize local
modes, but the final zero-penalty stages still leave six runaway/Hessian-blocked
rows, two convergence-watch rows, and one large-theta watch row, with zero
clean admission passes. That is useful blocker localization, not an admission
pass.

I rejected launching Nibi/Rorqual work from the existing diagnostics. The
contract requires a production transform/admission experiment that passes hard
seeds `910101`, `910102`, and `910110` without cap saturation,
optimizer-layer ridge penalties, convergence-watch rows, or Hessian-blocked
multi-coordinate rows before cluster admission or DRAC coverage.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-animal-transform-admission-contract.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-transform-admission-contract.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `python3 tools/validate-mission-control.py`: first failed because
  `index.html` still advertised build `r126` while `version.txt` was `r127`,
  and because the animal q4 support-cell `next_gate` dropped the required
  `interval diagnostics` phrase. After fixing both, passed with
  `mission_control_ok`, including 104 Q-Series cells and 7 animal q4
  transform-admission contract rows.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`:
  passed. The direct `node --check docs/dev-log/dashboard/index.html` attempt
  failed because Node does not syntax-check `.html` files directly.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  first failed on the same missing `interval diagnostics` phrase and on a
  too-rigid `table()` comparison in the new test. After fixing both, passed
  `7768 PASS / 0 FAIL / 0 WARN / 0 SKIP`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-transform-admission-contract.md')"`:
  passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh
  tools/start-mission-control.sh --background`: passed; the dashboard was
  already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: after refreshing the
  copied dashboard, `version.txt` returned `r128`;
  `structured-re-q4-animal-transform-admission-contract.tsv` served 8 lines
  including the header and all seven `no large-theta rows` gates; `/`
  contained `Animal q4 transform`, `q4 transform`, and
  `final lambda=0 clean admission passes`.

## 6. Tests of the Tests

The focused R test now requires exactly seven transform-admission routes, exact
source sidecars including the ridge-continuation diagnostic, diagnostic-only
interval status, not-evaluable coverage status, cluster-hold wording, and the
forbidden-claim boundary. The Python validator mirrors the same route/status
contract and checks source/evidence paths resolve locally.

## 7a. Issue Ledger

No GitHub issue was opened or closed in this slice. This is dashboard and
mission-control evidence gating for the existing Q-Series high-q lane.

## 8. Consistency Audit

The support-cell row remains `diagnostic_only` / `planned`. The queue,
high-q audit, support-cell `next_gate`, README, widget renderer, focused test,
and mission-control validator now agree that the next action is a lower-level
TMB parameterization design followed by a production-transform admission
experiment, not q4/q8 inference, coverage, REML, AI-REML, or support.

## 9. What Did Not Go Smoothly

The first widget patch was too broad for the current `index.html`, so I split it
into smaller patches. I also found the newer ridge-continuation diagnostic while
working and folded it into the contract rather than leaving the contract stale
at the MAP/penalty stage.

## 10. Known Residuals

This promotes exactly no Q-Series row. The animal q4 all-four cell remains
blocked for inference because no production transform has passed the hard-seed
admission gate. Nibi/Rorqual admission and DRAC coverage remain held.

## 11. Team Learning

When a new diagnostic exists in the dashboard, the next gate should synthesize
all current hard-seed evidence before spending cluster time. In this lane,
contract first, cluster second.
