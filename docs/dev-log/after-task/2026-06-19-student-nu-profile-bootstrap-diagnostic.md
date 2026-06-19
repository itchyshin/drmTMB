# After Task: Student-t Nu Profile/Bootstrap Diagnostic

## Goal

Record a bounded interval-method feasibility slice for the fixed-effect
Student-t shape route so later profile/bootstrap calibration work starts from
visible status evidence rather than from a Wald-only artifact.

## Implemented

The branch adds
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/`.
The runner reuses the Phase 18 Student-t shape simulation path for
`bf(y ~ x, sigma ~ z, nu ~ w)` with `family = student()`, two finite-variance
cells, and five replicates per cell. It requests 70% profile intervals for
`nu:(Intercept)` and `nu:w`, plus 70% parametric-bootstrap intervals with 10
refits per fit.

The result is intentionally diagnostic. Ten requested fits produced minimum
convergence 0.60 and minimum `pdHess` 0.80. The low-boundary cell had 0/5 ok
profile intervals for both `nu` coefficients. The ordinary cell had 3/5 ok
profiles for `nu:(Intercept)` and 1/5 ok profiles for `nu:w`. All requested
parametric-bootstrap intervals returned with 10 refits.

## Mathematical Contract

The fitted Student-t model uses `nu = 2 + exp(eta_nu)`, so the public route is
finite-variance and excludes `nu <= 2`. The diagnostic does not redefine that
model. It asks whether interval methods expose status rows for ordinary and
low-boundary finite-variance fits.

The profile and bootstrap intervals are formula-coefficient intervals for the
fixed-effect shape terms. The profile level and bootstrap refit count are too
small for coverage calibration, so the artifact supports status visibility
only.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/run-pilot.R`
- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/student-nu-profile-bootstrap-run-summary.csv`
- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/tables/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-student-nu-profile-bootstrap-diagnostic.md`

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla - <<'RS'
# one-replicate Student-t profile/bootstrap column probe
RS
air format docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-diagnostic/run-pilot.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
python3 tools/validate-mission-control.py
git diff --check
git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|recovery accuracy|promote|promotion' || true
rg -n 'Student-t.*(release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy|power claim|coverage claim|profile/bootstrap promotion)|nu.*(release|CRAN|Julia bridge|AI-REML|REML|power claim|coverage claim)' README.md ROADMAP.md NEWS.md docs vignettes R tests || true
rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs vignettes R tests || true
/usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

The artifact runner reproduced 10 requested fits, the summary CSVs, README,
interval diagnostics, interval failures, and session info. Both dashboard JSON
files parsed cleanly. Mission-control validation passed with `25/68
banked_or_verified`, `1 active`, `17 matrix rows`, `11 finish rows`, `15 Julia
gate rows`, and `9 Julia capability rows`. `git diff --check` passed.
`pkgdown::check_pkgdown()` reported no problems.

The claim-boundary scan hit only explicit negative-boundary wording in changed
files. The broader Student-t and meta-analysis scans were noisy from existing
public-status, historical, and guardrail text; the new hits were diagnostic
boundaries, not promoted claims.

## Tests Of The Tests

The one-replicate probe confirmed the exact profile/bootstrap interval table
columns before the runner was written. The committed runner then used the same
public interval hooks at a small but nontrivial size. The result includes both
successes and failures: all bootstrap requests returned, while low-boundary
profile requests failed visibly. That failure pattern is the test of the
diagnostic surface.

## Consistency Audit

The design ledger, worklist, R-Julia finish matrix, dashboard source, sweep
source, and check log all describe this as feasibility evidence. None of the
changed prose promotes Student-t profile/bootstrap coverage, release readiness,
CRAN readiness, Julia bridge parity, true `nu <= 2`, random effects,
bivariate routes, or non-Gaussian REML/AI-REML.

## GitHub Issue Maintenance

`drmTMB#59` remains the owning issue for numerical-guard sensitivity. After
the branch is merged and post-merge checks pass, add a compact issue comment
with the PR, merge SHA, artifact path, CI/deploy run IDs, and the same claim
boundary recorded here.

## What Did Not Go Smoothly

The first structured dashboard edit attempted to update a nonexistent
`recent_activity` field. The dashboard schema uses `activity`. A follow-up
correction rebuilt the dashboard JSON from `HEAD` and applied only targeted
string substitutions, avoiding unrelated formatting churn.

## Team Learning

Fisher should treat the low-boundary Student-t profile failures as first-class
evidence. A small bootstrap smoke can show that refits run, but it cannot
override failed profile status or weak Hessian status.

Rose should keep the dashboard row active until larger profile/bootstrap
calibration, additional guard depth, and interval consequences are banked with
replicate counts sized for their claims.

## Known Limitations

This artifact has five replicates per cell and 10 bootstrap refits per fit.
It does not estimate calibrated profile or bootstrap coverage. It does not
test true infinite-variance Student-t data, random effects, bivariate models,
structured covariance, Julia bridge parity, or release readiness.

## Next Actions

Run the local validation pass, open a focused PR, wait for 3-OS R-CMD-check,
merge only if green, verify post-merge main R-CMD-check and pkgdown/Pages, and
then post the evidence breadcrumb to `drmTMB#59`.
