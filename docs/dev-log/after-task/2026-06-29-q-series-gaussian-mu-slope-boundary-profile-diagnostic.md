# After Task: Q-Series Gaussian Mu-Slope Boundary Profile Diagnostic

## 1. Goal

Diagnose whether endpoint-profile intervals rescue the 42 retained SR150
Gaussian q1 `mu` one-slope boundary/non-Wald rows before any top-up,
`inference_ready`, or support-promotion work.

## 2. Implemented

This promotes exactly no support cell. The rows
`qseries_phylo_q1_mu_one_slope`, `qseries_spatial_q1_mu_one_slope`,
`qseries_animal_q1_mu_one_slope`, and
`qseries_relmat_q1_mu_one_slope` remain `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`.

I added `tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R`.
The runner reads the executed SR150 pregrid replicate artifact, selects rows
where `interval_status == "boundary_or_nonwald_status"`, refits the exact
provider/seed/replicate, and runs an endpoint profile for the exact SD
parameter that failed the default Wald interval.

The diagnostic wrote a 42-row detail artifact and a four-row dashboard summary.
The first run showed that all 42 boundary rows refit with convergence and
`pdHess = TRUE`, but every endpoint profile failed. A follow-up endpoint
lower-boundary fix then allowed positive SD lower endpoints to land on the zero
boundary, and the diagnostic was rerun. The rerun partially rescued finite
profile intervals, but upper misses and remaining profile failures still block
top-up and promotion. The widget now displays this boundary-profile blocker
separately from the SR150 retained-coverage blocker.

## 3a. Decisions and Rejected Alternatives

I kept the boundary-profile diagnostic separate from the Q-Series source TSV.
The diagnostic explains why the row remains blocked, but it is not itself a
status promotion and should not overwrite the support-cell interval or coverage
status.

Rejected alternatives: I did not launch a larger SR500/SR1000 top-up, because
the boundary/profile channel now shows upper-tail misses and remaining profile
failures before MCSE is the limiting gate. I also did not treat profile
failures as missing data or remove them from the denominator; that would create
survivor-biased coverage.

## 4. Files Touched

- `tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R`
- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-phase18-animal-mu-slope.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-boundary-profile-diagnostic-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-boundary-profile-diagnostic.md`
- `docs/dev-log/after-task/2026-06-29-q-series-profile-endpoint-lower-boundary-fix.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --max-rows=2 --output-dir=/tmp/drmtmb-mu-boundary-profile-smoke --overwrite=true --write-dashboard=false
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --overwrite=true
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "phase18-animal-mu-slope")'
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "profile-targets")'
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
git diff --check
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-boundary-profile-diagnostic.md')"
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-gaussian-mu-slope-boundary-profile-diagnostic.tsv | head -n 2
```

Results: the smoke run passed without writing the dashboard sidecar. The full
diagnostic passed, writing 42 detail rows, four summary rows, a run log,
`sessionInfo`, `git-sha`, and four dashboard rows. The focused
`phase18-animal-mu-slope` regression test passed with 58 PASS / 0 FAIL / 0 WARN
/ 0 SKIP, and the focused `profile-targets` test passed with 797 PASS / 0 FAIL
/ 0 WARN / 0 SKIP. The validator reported `mission_control_ok` with four
Gaussian mu-slope boundary-profile diagnostic rows. Dashboard JavaScript syntax
passed, `git diff --check` passed, the after-task structure check passed, the
focused structured-RE conversion test passed with 6353 PASS / 0 FAIL / 0 WARN /
0 SKIP, and the served dashboard reported build `r93` with the
boundary-profile TSV reachable.

## 6. Tests of the Tests

The mission-control validator now fails if the dashboard summary sidecar drifts
from the raw summary artifact, if the raw detail artifact is not exactly 42
rows, if any linked support cell stops being `planned/planned`, if a
profile-failed row is silently treated as finite, or if a claim boundary drops
the no-promotion wording.

The runner was smoke-tested into `/tmp` with `--write-dashboard=false` before
the final artifact was written, which checks that rehearsals cannot overwrite
the widget sidecar by accident.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work adds local negative
interval-geometry evidence for the Q-Series widget and validator.

## 8. Consistency Audit

The boundary-profile detail rows are:

- animal: 27/27 refits converged with `pdHess = TRUE`; 25/27 profile intervals
  were finite, 10 covered, 15 missed high, and two profile attempts failed.
- phylo: 9/9 refits converged with `pdHess = TRUE`; 8/9 profile intervals were
  finite, one covered, seven missed high, and one profile attempt failed.
- relmat: 3/3 refits converged with `pdHess = TRUE`; 2/3 profile intervals were
  finite, none covered, two missed high, and one profile attempt failed.
- spatial: 3/3 refits converged with `pdHess = TRUE`; 3/3 profile intervals
  were finite, none covered, and three missed high.

The dashboard now joins this sidecar to the four q1 `mu` one-slope rows without
letting the sidecar override the existing `mu_slope_pregrid_blocked` row state.
The validator also cross-checks the dashboard rows against the artifact summary
rows.

## 9. What Did Not Go Smoothly

The first manual probe and full diagnostic found profile failures rather than
finite rescue intervals. The lower-boundary fix improved that failure mode, but
the rerun exposed a sharper blocker: finite boundary-profile intervals often
miss above the true SD, so a simple compute top-up would harden a bad interval
channel.

## 10. Known Residuals

Gaussian q1 `mu` one-slope rows are still not admission-ready. The remaining
technical questions are why some endpoint roots still fail and why finite
zero-lower-boundary intervals produce upper misses for most rescued boundary
replicates.

## 11. Team Learning

Do the boundary diagnostic before the large top-up. A clean retained-coverage
range near nominal can still be scientifically blocked if boundary rows either
fail the profile channel or reveal one-sided misses after the endpoint is made
finite.
