# After Task: Student-t Profile/Bootstrap Diagnostic Pilot

## Goal

Advance drmTMB#59 one bounded step beyond the 10-fit Student-t
profile/bootstrap feasibility artifact without promoting profile/bootstrap
coverage or release readiness.

## Implemented

Added a reproducible artifact under
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-pilot/`.
The runner reuses the existing Phase 18 Student-t shape grid functions for
`bf(y ~ x, sigma ~ z, nu ~ w)` with `family = student()`.

The pilot ran two complete-data cells, 25 replicates per cell, profile intervals
for `nu:(Intercept)` and `nu:w`, and 25 parametric-bootstrap refits per fit.

## Mathematical Contract

The fitted Student-t route is finite-variance:

```text
nu = 2 + exp(eta_nu)
```

The low-boundary cell sets `nu(w = 0) = 2.8`; the ordinary cell sets
`nu(w = 0) = 8.0`. The artifact tests interval status and rough pilot behavior
for that fitted model. It does not test true `nu <= 2` data, random effects,
bivariate responses, structured effects, or non-Gaussian REML/AI-REML.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-pilot/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-student-nu-profile-bootstrap-pilot.md`

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-pilot/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-pilot/run-pilot.R
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|recovery accuracy|promote|promotion' || true
rg -n 'Student-t.*(release|CRAN|Julia bridge|AI-REML|REML|recovery accuracy|power claim|coverage claim|profile/bootstrap promotion)|nu.*(release|CRAN|Julia bridge|AI-REML|REML|power claim|coverage claim)' README.md ROADMAP.md NEWS.md docs vignettes R tests || true
rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs vignettes R tests || true
/usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

The final artifact run reproduced 50 requested fits in about 114 seconds.
Minimum convergence was 0.92 and minimum `pdHess` was 0.88. Profile ok rates
for the two `nu` coefficients were 0.40-0.68. All requested
parametric-bootstrap intervals returned with 25 refits. Rough 70% profile pilot
coverage was 0.40-0.765 with MCSE up to 0.1549193; rough 70% bootstrap pilot
coverage was 0.56-0.72 with MCSE up to 0.09927739.

Both dashboard JSON files parsed cleanly. Mission-control validation passed with
`25/68 banked_or_verified`, `1 active`, `17 matrix rows`, `11 finish rows`,
`15 Julia gate rows`, and `9 Julia capability rows`. `git diff --check` passed.
The claim-boundary scan hit only explicit negative-boundary wording in changed
files. The broader Student-t and meta-analysis scans were noisy from existing
public-status and historical guardrails, but the new hits were diagnostic-only
boundaries. `pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

The first full run exposed an internal summary bug: coverage MCSE fields were
`-Inf` because the focused `nu` interval tables did not carry a precomputed
`covered` column. The runner now computes coverage directly from `truth`,
`conf.low`, and `conf.high`, and the clean rerun writes finite MCSE values.

## Consistency Audit

The design ledger, completion worklist, R-Julia finish matrix, dashboard JSON,
sweep JSON, and check-log all describe this as diagnostic interval-pilot
evidence. Counts remain unchanged at 25/68 verified, 1 active, 0 blocked, and 1
deferred because no capability row is promoted.

## GitHub Issue Maintenance

drmTMB#59 is the live umbrella issue. Post a breadcrumb there after local checks,
PR CI, post-merge main R-CMD-check, pkgdown/Pages, and live Pages verification
are complete.

## What Did Not Go Smoothly

The first runner summary treated missing coverage MCSE as `-Inf`; the final
runner fixes this by computing coverage explicitly. The first structured JSON
update also looked for the wrong dashboard row id before any file was written;
the successful update used the actual `drmTMB-numerical-guard-sensitivity` row.

## Team Learning

Rose's rule for interval artifacts should be explicit: if a focused interval
table lacks a `covered` column, compute it from truth and endpoints before any
coverage or MCSE summary is written.

## Known Limitations

This is not calibrated profile/bootstrap coverage. The profile level is 0.70,
the bootstrap budget is 25 refits per fit, and target-specific profile failures
remain part of the evidence. Larger Student-t profile/bootstrap calibration and
broader guard-class simulations remain planned.

## Next Actions

Run the remaining local checks, open a focused PR, monitor three-platform
R-CMD-check, merge only after green gates, then verify post-merge main
R-CMD-check, pkgdown/Pages, and live Pages before posting the drmTMB#59
breadcrumb.
