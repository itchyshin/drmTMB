# After Task: Q-Series Profile Endpoint Lower-Boundary Fix

## 1. Goal

Repair the scalar endpoint-profile path for positive SD targets whose lower
confidence endpoint belongs on the zero boundary, then rerun the Gaussian q1
`mu` one-slope boundary diagnostic without promoting any Q-Series row.

## 2. Implemented

This promotes exactly no support cell. The four Gaussian q1 `mu` one-slope
cells for animal, phylo, relmat, and spatial remain `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`.

`R/profile.R` now caps extreme curvature-derived first steps in the scalar
endpoint solver and lets lower-side positive-scale endpoints return the zero
boundary when the constrained profile cannot bracket a finite lower crossing.
Finite boundary rows report `conf.status = "profile"`,
`profile.boundary = TRUE`, `profile.message = "near_sd_boundary"`, and a lower
endpoint of zero. Non-positive targets still keep the old finite-root
requirement.

The 42-row Gaussian q1 `mu` one-slope boundary-profile diagnostic was rerun
after the fix. The fix partially rescued finite profile intervals, but upper
misses and remaining endpoint-root failures keep all four rows blocked.

## 3a. Decisions and Rejected Alternatives

I treated the zero lower endpoint as valid only for `exp`-transformed profile
targets. That keeps the repair specific to positive SD/scale targets and avoids
weakening fixed-effect or correlation endpoint checks.

I rejected the full `TMB::tmbprofile()` route as the immediate repair because
the exact animal failing replicate still returned a non-finite interval in the
probe. I also rejected top-up simulation after the partial rescue: finite
boundary intervals now show upper-tail misses, so more replicates would not
solve the interval-channel blocker.

## 4. Files Touched

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-phase18-animal-mu-slope.R`
- `tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local/`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-boundary-profile-diagnostic.md`
- `docs/dev-log/after-task/2026-06-29-q-series-profile-endpoint-lower-boundary-fix.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phase18-animal-mu-slope")'
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "profile-targets")'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --overwrite=true
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-boundary-profile-diagnostic.md'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-profile-endpoint-lower-boundary-fix.md')"
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-q-series-support-cells.tsv | wc -l
curl -fsS http://127.0.0.1:8765/structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv | head -n 5
air format R/profile.R tests/testthat/test-profile-targets.R tests/testthat/test-phase18-animal-mu-slope.R
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test()'
```

Results: the focused animal q1 `mu` slope test passed with 58 PASS / 0 FAIL /
0 WARN / 0 SKIP; the focused profile-targets test passed with 797 PASS / 0 FAIL
/ 0 WARN / 0 SKIP; the full boundary diagnostic rerun passed and rewrote 42
detail rows plus four dashboard rows; the mission-control validator reported
`mission_control_ok`; the structured-RE conversion/widget contract passed with
6353 PASS / 0 FAIL / 0 WARN / 0 SKIP; both after-task structure checks passed;
dashboard JavaScript syntax passed; `git diff --check` passed; and the local
server at `http://127.0.0.1:8765/` served build `r93`, the 104-row support-cell
TSV, and the four updated boundary-profile diagnostic rows. `air format` passed
on the touched R/test files. Full `devtools::test()` passed with 19754 PASS /
0 FAIL / 17 WARN / 43 SKIP; the warnings are existing warning-path tests for
non-convergence, clamp, and missing-data edge cases, not endpoint/profile
regressions.

## 6. Tests of the Tests

The new `profile-targets` unit checks exercise both sides of the lower-boundary
contract: the same fake endpoint path returns `theta = -Inf` when
`allow_lower_boundary = TRUE` and errors when that flag is false. The
animal q1 `mu` slope regression uses the exact failing replicate
(`seed = 791004`, replicate 4, `sd:mu:animal(0 + x | id)`) and asserts the
public `confint()` row now has a zero lower endpoint, a finite upper endpoint,
and the `near_sd_boundary` diagnostic.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The local evidence is recorded
in the check log, after-task reports, mission-control validator, and dashboard
sidecar.

## 8. Consistency Audit

The rerun boundary-profile summary is synchronized across the raw artifact,
dashboard sidecar, validator, check log, and dashboard README. The support-cell
TSV is deliberately unchanged for these rows: the sidecar is diagnostic
evidence, not a status edit.

Counts after the fix: animal has 25/27 finite profile intervals, 10 covered, 15
upper misses, and two profile failures; phylo has 8/9 finite, one covered,
seven upper misses, and one profile failure; relmat has 2/3 finite, zero
covered, two upper misses, and one profile failure; spatial has 3/3 finite,
zero covered, and three upper misses. All finite boundary rows report lower
endpoint zero and `near_sd_boundary`.

## 9. What Did Not Go Smoothly

The first endpoint repair candidate was the full `TMB::tmbprofile()` fallback,
but the exemplar still returned a non-finite interval. The eventual narrow fix
made the lower endpoint valid, then exposed the next real problem: upper misses
dominate the rescued boundary rows.

## 10. Known Residuals

Gaussian q1 `mu` one-slope rows remain blocked. The next technical work must
explain the upper-tail miss pattern and remaining endpoint-root failures before
any retained-coverage top-up can be meaningful.

## 11. Team Learning

Boundary repair and evidence promotion are separate moves. First make the
interval engine report the mathematically valid zero endpoint; then rerun the
retained-denominator diagnostic and let the miss pattern decide whether the row
can move.
