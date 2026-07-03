# After Task: Q-Series Tranche 3 q4 Admission-Denominator Contract

## 1. Goal

Start Tranche 3 from merged `main` by banking a q4 admission-denominator
contract before any coverage work. The slice should make the retained
denominator, direct-SD interval gate, and no-promotion boundary visible in
Mission Control.

## 2. Implemented

Added `structured-re-q4-admission-denominator-contract.tsv` with 14 rows. It
covers the ordinary q4 location comparator, structured q4 location and
all-four-intercept cells for `phylo()`, fixed-covariance `spatial()`,
A-matrix `animal()`, and K-matrix `relmat()`, the q8-shaped all-four one-slope
hold rows, and the phylo bivariate direct-SD diagnostic row.

Each row freezes the retained denominator, convergence, `pdHess`, gradient,
profile-warning, boundary, finite direct-SD interval, and
derived-correlation gates. Every row has `promotion_decision = do_not_promote`.

Mission Control now loads the sidecar, shows a `Q4 denom contract` summary card,
and renders the detailed contract under Structured RE contracts with
`promotion_decision` and `claim_boundary` visible. The validator now checks the
TSV contract, the support-cell status links, evidence references, visible
boundary columns, and the Q-Series render-call wiring.

No support-cell status changed.

## 3a. Decisions and Rejected Alternatives

I kept this as an admission-denominator contract rather than launching a
coverage grid. The q4/high-q evidence still contains diagnostic-only and
Hessian-blocked routes, so coverage would be premature.

I included the q8-shaped all-four one-slope hold rows because they are named
q4 all-four one-slope support cells but have q8 geometry. They remain
design-first holds, not q4 admission passes.

After Rose found that the rendered contract table omitted the strongest
no-promotion fence, I changed the visible table fields instead of relying on
the TSV alone. The browser-render check then caught a missing render argument,
so the validator now guards that wiring.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-admission-denominator-contract.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche3-q4-admission-denominator-contract.md`

## 5. Checks Run

- `git status --short --branch`: confirmed the work is on
  `codex/qseries-q4-admission-tranche3`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series cells and 14 q4
  admission-denominator contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  first failed on a brittle `table()` comparison in the new test; after fixing
  that assertion, passed `10285 PASS / 0 FAIL / 0 WARN / 0 SKIP`.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed and served Mission Control at `http://127.0.0.1:8765/`.
- Served checks: `version.txt` returned `r192`; the new TSV served 15 lines.
- In-app browser render check: Mission Control loaded without the data-load
  error; the Q4 denom card was visible; the Structured RE contracts section
  showed `promotion_decision: do_not_promote` and the `no inference_ready` /
  `no supported` claim boundary.
- `git diff --check`: passed after the final report and check-log edits.

## 6. Tests of the Tests

The focused R test failed before the assertion was repaired, proving the new
contract block was running. The Rose audit also caught a real UI visibility gap:
the TSV and validator had the no-promotion boundary, but the rendered table did
not. The browser render check then caught the missing Q-Series render argument
that static TSV validation alone missed.

## 7a. Issue Ledger

No GitHub issue was opened or closed in this slice. This is a local
mission-control contract for the active Q-Series Tranche 3 lane.

## 8. Consistency Audit

Tranche 2 merged-main invariants were confirmed before editing: `main` and
`origin/main` were at `4d6d2339eb482f574293f30464276b284cb3e949`, PR #684 and
PR #685 were merged, and mission control was green with 104 Q-Series rows, 8
interval/coverage `inference_ready` rows, 0 structured `supported` rows, 0
high-q `inference_ready` rows, and 0 non-Gaussian interval/coverage
`inference_ready` rows.

The new TSV, README, dashboard renderer, focused R test, mission-control
validator, and live browser all agree that this is an admission contract only.
No row is promoted to `inference_ready` or `supported`.

## 9. What Did Not Go Smoothly

The first dashboard wiring passed static syntax checks but failed in the live
browser because the Q-Series renderer did not receive the new sidecar argument.
The first rendered contract table also hid `promotion_decision` because the
generic contract renderer displays only the first three detail fields.

## 10. Known Residuals

This does not admit q4 inference and does not authorize coverage. All q4/high-q
rows remain at their previous support-cell statuses. Derived-correlation
intervals, q4 REML, REML, AI-REML, q8 inference, broad bridge support, and
public support remain unclaimed.

## 11. Team Learning

For Mission Control sidecars, a green TSV validator is not enough. New sidecars
need a live browser render check, and validators should guard both the data
contract and the widget wiring that makes the contract visible to the team.
