# Big 4 Finish Plan

## Task Goal

Bank a detailed operating plan for the next four large `drmTMB#59` work
blocks after the post-#633 decision ledger and Student-t profile-failure
decision audit.

## Files Changed

- `docs/design/177-big4-finish-plan-2026-06-19.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-big4-finish-plan.md`

## What Changed

The new plan sequences four blocks:

1. fixed-effect bivariate Gaussian `sigma1`/`sigma2` scale-clamp sensitivity;
2. ordinary q2 and same-response covariance hardening;
3. q8 endpoint and staged-start hardening;
4. fixed-effect skew-normal guard-grid work.

It records per-block scope, starting evidence, proposed artifacts, required
outputs, subagent review roles, validation commands, and claim boundaries. It
also makes the cross-block rule explicit: native R/TMB, direct Julia, and
Julia-via-R evidence are separate lanes, and native-only slices must say so
instead of implying bridge or companion-package support.

## Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

## Results

Curie reviewed the bivariate `sigma1`/`sigma2` scale-clamp next slice and
recommended a native R/TMB diagnostic with 10 cells, 50 replicates, and three
clamp controls, with no profile/bootstrap/refit budgets. Grace reviewed the
reproducibility boundary and confirmed that the current bivariate scale
evidence supports only native fixed-effect `biv_gaussian()` scale-guard
visibility, not Julia, bridge, interval, coverage, release, CRAN, REML, or
AI-REML claims.

The dashboard active-work text now points to the plan. Metrics remain 25/68
banked_or_verified, 1 active, 0 blocked, and 1 deferred.

A `drmTMB#59` plan breadcrumb was posted:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4751426124.

## Consistency Audit

This is a planning and evidence-ordering change only. It does not change
package code, formula grammar, likelihood parameterization, simulation runners,
tests, or pkgdown navigation. It does not claim that any of the four planned
blocks are complete.

## Known Limitations

The plan has not run the bivariate scale larger diagnostic, q2 hardening, q8
hardening, or skew-normal grid. Each block still needs its own artifact,
validation pass, after-task report, and issue breadcrumb.
