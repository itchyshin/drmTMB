# Student-t Guard Ledger Sync

## Task

Synchronize the numerical-guard source of truth after the Student-t
finite-variance diagnostic pilot landed. The goal was to make the design
ledger, capability matrix, dashboard row, and current worklist say the same
thing: the `log(sigma)` clamp pilot and the Student-t `nu` boundary pilot are
both banked diagnostic evidence, but neither one promotes coverage, power,
interval calibration, release readiness, or CRAN readiness.

## What Changed

`docs/design/176-numerical-guard-simulation-audit.md` now has a second pilot
section for the Student-t finite-variance boundary. It records the artifact
path, aim, two `nu(w = 0)` cells, estimands, methods, status counts, and the
explicit no-promotion boundary.

`docs/design/168-r-julia-finish-capability-matrix.md` and
`docs/design/157-capability-completion-worklist.md` now name the Student-t pilot
beside the first fixed-effect Gaussian `log(sigma)` clamp pilot. The remaining
queue is narrower and more honest: scale-side phylogeny, bivariate scale
routes, support floors, Student-t calibration, correlation guards, and broader
interval evidence still need their own sensitivity evidence before release
wording.

The mission-control dashboard row for `drmTMB#59` now links to the guard-audit
design ledger as the shared evidence source. The blocker text names both banked
pilots and keeps broader support floors, correlation guards, interval coverage,
random/structured/bivariate scale routes, release claims, and CRAN claims
planned.

## Verification

This documentation and dashboard-truth slice passed JSON validation,
`tools/validate-mission-control.py`, `git diff --check`,
`pkgdown::check_pkgdown()`, and a served dashboard smoke test. The dashboard
reported `updated = "2026-06-17 23:41 MDT"` with unchanged metrics:
25/68 banked or verified, 1 active, 0 blocked, and 1 deferred.

## Boundaries

No R runtime API, formula grammar, likelihood, TMB C++, diagnostic threshold,
simulation result, coverage estimate, power estimate, interval method, Julia
bridge behavior, release-readiness decision, or CRAN-readiness decision changed.
