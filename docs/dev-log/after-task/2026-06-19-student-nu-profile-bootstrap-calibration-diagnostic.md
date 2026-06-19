# After Task: Student-t `nu` Profile/Bootstrap Calibration Diagnostic

## Goal

Bank a larger diagnostic interval-calibration artifact for the fixed-effect
Student-t shape route in `drmTMB#59`, after the smaller feasibility and pilot
runs showed that profile intervals can fail even when bounded bootstrap
intervals return.

## Implemented

The new artifact lives at
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/`.
It uses the same complete-data Student-t design as the earlier Wald,
profile/bootstrap feasibility, and profile/bootstrap pilot slices, but raises
the run to 50 replicates per cell and 50 parametric-bootstrap refits per fit.

The runner writes condition, fit-status, profile-interval,
bootstrap-interval, interval-diagnostic, interval-failure, run-summary,
README, RDS replicate, and session-info artifacts.

## Mathematical Contract

The fitted model is

```r
bf(y ~ x, sigma ~ z, nu ~ w)
```

with `family = student()`. The shape parameter is
`nu = 2 + exp(eta_nu)`, so this is a finite-variance Student-t model. The
artifact does not test or claim support for true `nu <= 2`.

The two cells use `n = 180`, `beta_mu = (0.25, 0.55)`,
`beta_sigma = (log(0.65), 0.20)`, `nu_slope = 0`, and
`rho(x, w) = 0.20`. The low-boundary cell has `nu(w = 0) = 2.8`; the ordinary
cell has `nu(w = 0) = 8.0`.

## Files Changed

- Added
  `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/`.
- Updated `docs/design/176-numerical-guard-simulation-audit.md`.
- Updated `docs/design/157-capability-completion-worklist.md`.
- Updated `docs/design/168-r-julia-finish-capability-matrix.md`.
- Updated `docs/dev-log/dashboard/status.json`.
- Updated `docs/dev-log/dashboard/sweep.json`.
- Updated `docs/dev-log/check-log.md`.
- Added this after-task report.

## Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/run-pilot.R`
- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/run-pilot.R`
- `/usr/local/bin/Rscript --vanilla - <<'RS' ... artifact summary readback ... RS`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `tools/validate-mission-control.py`
- `git diff --check`
- `/usr/local/bin/Rscript --vanilla - <<'RS' ... artifact consistency assertions ... RS`
- `git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|structured correlations|recovery accuracy|promote|promotion' || true`
- `rg -n 'Student-t.*(release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy|power claim|coverage claim|profile/bootstrap promotion)|nu.*(release|CRAN|Julia bridge|AI-REML|REML|power claim|coverage claim)' README.md ROADMAP.md NEWS.md docs vignettes R tests || true`
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs vignettes R tests || true`
- `rg -n "25 refits|25 bootstrap refits|diagnostic pilot has 50|larger Student-t profile/bootstrap calibration|calibrated Student-t profile/bootstrap interval evidence" docs/design/176-numerical-guard-simulation-audit.md docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic.md docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic/README.md || true`
- `RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"`

## Tests Of The Tests

This is a simulation artifact rather than a package-code test. It exercises a
known weak-identification region for the Student-t `nu` parameter and retains
failure rows rather than discarding them. The new run deepens the previous
25-replicate pilot; it should have found a smoother version of the same
profile-status pattern if that pattern was real.

## Consistency Audit

The artifact requested 100 fixed-effect Student-t shape fits. The minimum
convergence rate was `0.88`, and the minimum `pdHess` rate was `0.86`.

For `nu:(Intercept)` and `nu:w`, profile ok rates ranged from `0.38` to
`0.54`. Rough 70% profile coverage for ok rows ranged from `0.5185185` to
`0.8095238`, with coverage MCSE up to `0.1010226`.

All requested parametric-bootstrap intervals returned with 50 refits. Rough
70% bootstrap coverage ranged from `0.50` to `0.68`, with coverage MCSE up to
`0.07071068`.

The design docs, capability worklist, finish matrix, dashboard, and check log
describe this as diagnostic interval-calibration evidence only. They do not
promote Student-t profile/bootstrap coverage, random effects, bivariate routes,
true `nu <= 2`, Julia bridge parity, release readiness, CRAN readiness, or
non-Gaussian REML/AI-REML.

## GitHub Issue Maintenance

`drmTMB#59` remains open and active. After the pull request merges, add a
breadcrumb comment with the PR number, merge SHA, CI run IDs, pkgdown/Pages
run ID, live Pages check, and this diagnostic boundary.

## What Did Not Go Smoothly

The copied runner initially retained one stale README sentence that said 25
bootstrap refits per fit. The generator and generated README were corrected to
50 refits before the ledger updates.

## Team Learning

Fisher's useful check is no longer "did bootstrap return intervals?" alone.
For Student-t `nu`, the team needs to keep profile failures, bootstrap refit
counts, rough coverage, and MCSE beside convergence and `pdHess` status.

Rose's useful check is to keep the wording on "diagnostic interval-calibration"
until a deliberately sized promotion grid exists.

## Known Limitations

This slice uses fixed-effect complete-data Student-t models only. It does not
cover random effects, bivariate responses, structured effects, missing data,
true infinite-variance data with `nu <= 2`, comparator fits, fallback
optimizers, retries, or release-readiness evidence.

The profile and bootstrap level is `0.70`, not the user-facing `0.95` interval
target. The run is larger than the pilot but still smaller than the
promotion-grid tier described in the numerical-guard ADEMP design.

## Next Actions

Run the remaining local validation gates, open a focused evidence-only pull
request, monitor CI, merge only after green checks, then verify post-merge main
R-CMD-check and pkgdown/Pages before adding the `drmTMB#59` breadcrumb.
