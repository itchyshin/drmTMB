# After Task: Q-Series Mu-Slope Small-Sample Correction Fix

## 1. Goal

Fix the q1 structured `mu` slope Wald default so component SD rows from
`provider(1 + x | group)` receive the documented location-axis t-width and
`log(g/(g-1))` centre shift, then rerun the Gaussian q1 `mu` one-slope SR150
pregrid without promoting any support cell.

## 2. Implemented

This promotes exactly no support cell. The four Gaussian q1 `mu` one-slope rows
remain `interval_status = planned` and `coverage_status = planned`.

`R/profile.R` now matches decomposed structured SD target terms such as
`spatial(1 | site)` and `spatial(0 + x | site)` back to the structured block
label `spatial(1 + x | site)`. The same helper applies to `phylo`, `animal`,
and `relmat` structured q1 slope blocks because the match is on provider type
and grouping variable, not on the left-hand side terms.

I added a regression test in
`tests/testthat/test-wald-small-sample-default.R` that checks both decomposed
component rows resolve `g - 1` and `log(g/(g-1))`, then reconstructs the expected
corrected endpoints from the raw z-interval.

## 3a. Decisions and Rejected Alternatives

I did not broaden the correction to dispersion-axis `sigma` targets or to
unstructured random effects. The existing scope remains location-axis structured
SD targets only.

I did not mark q1 `mu` rows `inference_ready`: the corrected SR150 run still has
boundary/non-Wald slope rows, an animal intercept holdout, and MCSE above the
inference gate.

## 4. Files Touched

- `R/profile.R`
- `tests/testthat/test-wald-small-sample-default.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-coverage-pregrid-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local/`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-coverage-pregrid.md`
- `docs/dev-log/after-task/2026-06-29-q-series-mu-slope-small-sample-correction-fix.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "wald-small-sample-default")'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=150 --overwrite=true
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
git diff --check
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-mu-slope-small-sample-correction-fix.md'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-coverage-pregrid.md')"
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
```

Results: `wald-small-sample-default` passed with 21 PASS / 0 FAIL / 0 WARN /
0 SKIP. The SR150 pregrid rerun wrote four dashboard result rows, eight target
summary rows, 600 fit-status rows, and 1200 retained target-replicate rows.
`tools/validate-mission-control.py` reported `mission_control_ok`, and
`git diff --check` passed. Dashboard JavaScript syntax passed, the focused
structured-RE conversion contract test passed with 6353 PASS / 0 FAIL / 0 WARN /
0 SKIP, both after-task structure checks passed, and the served dashboard
reported build `r92`.

## 6. Tests of the Tests

The regression test fails under the previous exact-suffix matcher because the
component rows resolve `NA` for group count and log-bias. It now proves both
component rows receive the same group count as the parent structured block.

The mission-control validator now checks the corrected SR150 dashboard numbers,
so the old under-corrected artifact with phylo coverage 0.860-0.933 and relmat
coverage 0.887-0.980 can no longer pass the Q-Series guardrail.

## 7a. Issue Ledger

No GitHub issue action was taken in this local slice.

## 8. Consistency Audit

The corrected SR150 summaries are:

- animal: still blocked, with one visible holdout and 122/150 usable intervals
  for the eligible slope target.
- phylo: 291/300 usable intervals, retained coverage 0.940-0.947, and 3 lower /
  5 upper misses.
- relmat: 297/300 usable intervals, retained coverage 0.953-0.973, and 2 lower /
  6 upper misses.
- spatial: 297/300 usable intervals, retained coverage 0.947-0.960, and 6 lower /
  5 upper misses.

All four rows remain `mu_slope_pregrid_blocked`; none are `inference_ready` or
`supported`.

## 9. What Did Not Go Smoothly

The first regression fixture accidentally simulated no real structured slope,
so the slope SD landed on the boundary. I replaced it with deterministic
site-specific intercept and slope effects before banking the test.

I also ran a 20-rep smoke that wrote the dashboard sidecar before the full
SR150 rerun. The full SR150 rerun replaced that temporary sidecar.

## 10. Known Residuals

q1 `mu` one-slope rows still need a boundary/profile geometry diagnostic before
any top-up campaign. A simple larger SR1000 run would mix real MCSE reduction
with unresolved boundary/non-Wald censoring.

## Next Actions

For phylo, relmat, and spatial, diagnose the slope-target boundary/non-Wald rows
and decide whether they are rare enough for a retained top-up or require a
profile/skew-aware interval channel. For animal, reconcile the intercept holdout
before considering a top-up.

## 11. Team Learning

When a documented default correction is scoped by target metadata, tests need to
cover both scalar and decomposed slope-component target names. A scalar-only
test can miss a silent no-op on the exact Q-Series rows that need the correction.
