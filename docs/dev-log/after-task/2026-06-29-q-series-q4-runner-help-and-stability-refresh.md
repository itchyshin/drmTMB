# After Task: Q-Series q4 runner help and stability refresh

## 1. Goal

Prevent q4 diagnostic orientation commands from launching fits, and reconcile
the q4 all-four one-slope stability sidecar with the current-source diagnostic
run that was triggered while inspecting the runners.

## 2. Implemented

This promotes exactly no Q-Series row under the q4 direct-SD Wald/profile
diagnostic channel, with fixture-only denominator accounting, and does not
claim q4 interval reliability, q4 coverage, q8 support, REML, AI-REML, bridge
support, `supported`, or public support.

Added `--help` / `-h` exits to three q4 runner scripts:

- `tools/run-structured-re-q4-location-slope-interval-smoke.R`
- `tools/run-structured-re-q4-slope-interval-stability-probe.R`
- `tools/run-structured-re-q4-location-coverage-grid.R`

The two fixed-output smoke/probe scripts now print their destination artifacts
and exit before `devtools::load_all()`. The q4 location coverage grid now
prints usage, options, the 16 direct-SD shard map, and its claim boundary
without requiring `--shard` or loading the package.

The current-source rerun refreshed
`structured-re-q4-slope-interval-stability-probe.tsv`. `phylo()`,
fixed-covariance `spatial()`, and K-matrix `relmat()` remain
`pdHess`-blocked in both `strong` and `more_levels` variants. A-matrix
`animal()` now reaches `pdHess = TRUE` for all 16 direct-SD endpoints, with
finite Wald intervals throughout, 9/16 Wald/profile finite endpoints, and
7/16 Wald-finite/profile-nonfinite endpoints. The validator, focused R test,
dashboard README, and design map now treat that as mixed diagnostic-only
evidence rather than the older all-provider Hessian-blocked shape.

## 3a. Decisions and Rejected Alternatives

Decision: keep the refreshed current-source q4 diagnostic artifacts and update
the contract around them, because they reveal a real provider-specific change:
animal q4 all-four direct-SD endpoints are no longer uniformly Hessian-blocked
in this deterministic smoke.

Rejected alternatives:

- Do not revert to the older all-provider `pdHess = FALSE` story.
- Do not promote animal q4 from one deterministic smoke; the denominator is
  still fixture-only and several animal profile endpoints are nonfinite.
- Do not submit a q4 coverage grid on DRAC from this result. The q4 admission
  gate still needs replicated deterministic fixtures, denominator accounting,
  and derived-correlation interval handling.
- Do not leave q4 scripts with unsafe `--help` behaviour.

## 3b. Mathematical Contract

No likelihood, formula grammar, or interval implementation changed. The q4
sidecar remains a direct-SD diagnostic for all-four one-slope models. It
records fit convergence, `pdHess`, Wald/profile finite status, and next gates
for each direct-SD endpoint. The refreshed contract separates three states:
`pdhess_blocked`, `wald_finite_profile_nonfinite`, and
`wald_profile_finite`. All three remain `diagnostic_only` and do not create a
coverage denominator.

## 4. Files Touched

- `tools/run-structured-re-q4-location-slope-interval-smoke.R`
- `tools/run-structured-re-q4-slope-interval-stability-probe.R`
- `tools/run-structured-re-q4-location-coverage-grid.R`
- `docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-interval-smoke/structured-re-q4-location-slope-interval-smoke-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q4-slope-interval-stability-probe/structured-re-q4-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-runner-help-and-stability-refresh.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-location-slope-interval-smoke.R --help`: before the help guard, this executed the fixed smoke and refreshed the q4 location artifact; after the guard, it printed usage and exited without fitting.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-slope-interval-stability-probe.R --help`: before the help guard, this executed the fixed stability probe and refreshed the q4 all-four artifact; after the guard, it printed usage and exited without fitting.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-q4-location-coverage-grid.R --help`: before the help guard, this printed the shard map and exited nonzero because `--shard` was missing; after the guard, it printed usage, options, and the shard map, then exited 0 without loading or fitting.
- `air format tools/run-structured-re-q4-location-slope-interval-smoke.R tools/run-structured-re-q4-slope-interval-stability-probe.R tools/run-structured-re-q4-location-coverage-grid.R`: passed.
- `air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 64 q4 slope interval-stability
  probe rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: passed with 6819 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-runner-help-and-stability-refresh.md')"`: passed.
- Extracting the dashboard script from `docs/dev-log/dashboard/index.html` and
  running `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r105`.
- `curl -fsS http://127.0.0.1:8765/index.html | rg 'r105|Spatial sigma diag|structured-re-spatial-sigma-boundary-diagnostic|structured-re-q4-slope-interval-stability-probe'`: found the build and widget markers.
- `curl -fsS http://127.0.0.1:8765/structured-re-q4-slope-interval-stability-probe.tsv | python3 -c 'import sys,csv,collections; rows=list(csv.DictReader(sys.stdin, delimiter="\t")); print(len(rows), "rows"); print(collections.Counter((r["structured_type"], r["n_pdhess"], r["stability_status"]) for r in rows))'`: returned 64 rows, with 16 `pdhess_blocked` rows each for phylo, spatial, and relmat, plus 9 animal `wald_profile_finite` rows and 7 animal `wald_finite_profile_nonfinite` rows.

## 6. Tests of the Tests

The validator first failed on the refreshed q4 sidecar because it still
required every q4 all-four endpoint to have `n_pdhess = 0` and
`not_run_pdhess_false` intervals. That failure proved the contract was
watching the sidecar closely enough to catch provider-specific status drift.
The updated validator and R test now require non-animal rows to remain
Hessian-blocked, require animal rows to have finite Wald intervals, split
animal profile-finite from profile-nonfinite endpoints, and keep every row
`diagnostic_only`.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. The live issue sweeps found
only broad tracking issues, not a narrow q4 runner-help issue:

- `gh issue list --state open --search "q4 all-four stability" --limit 10`:
  #59.
- `gh issue list --state open --search "q4 slope interval stability" --limit 10`:
  #59.
- `gh issue list --state open --search "q4 coverage grid" --limit 10`: #491,
  #33, #59, and #5.

## 8. Consistency Audit

The q4 support-cell rows remain planned or diagnostic-only. The high-q audit
still marks q4 all-four and q8-shaped rows as gated or stability-blocked. The
dashboard README and design map now say that animal q4 has mixed diagnostic
interval evidence while phylo, spatial, and relmat remain Hessian-blocked. The
validator and focused R test reject any attempt to turn this into interval
reliability, coverage, REML, AI-REML, bridge support, `supported`, or public
support.

## 9. What Did Not Go Smoothly

The inspection command `--help` was unsafe on two q4 scripts and accidentally
ran the local smoke/probe. That was the useful warning: runners that are likely
to be inspected during DRAC planning need a no-compute help path before any
package load or fit work.

## 10. Known Residuals

The q4 all-four row is still not ready for coverage grids. Animal q4 now has a
promising deterministic signal, but it needs replicated deterministic fixtures,
denominator accounting, and profile failure classification before any admission
change. Derived correlations remain outside this direct-SD sidecar.

## 11. Team Learning

Before spending DRAC budget, make runner orientation commands safe. A `--help`
path should exit before package loading and fitting, especially for scripts
that write fixed dashboard artifacts.

## 12. Next Actions

- If q4 is the next tranche, run a replicated animal q4 all-four deterministic
  fixture/admission probe before any coverage grid.
- Keep Nibi/Rorqual for sustained q4 work; avoid launching q4 coverage arrays
  until q4 admission gates are explicit.
