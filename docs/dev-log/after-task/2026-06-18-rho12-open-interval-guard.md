# After Task: Residual rho12 Open-Interval Guard Diagnostic

## Goal

Bank a diagnostic-only fitted residual `rho12` open-interval guard slice for
`drmTMB#59`, without forcing convergence or promoting interval, power, release,
CRAN, Julia bridge, random-effect `rho12`, or structured-correlation claims.

## Implemented

Added
`docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/`
with a runner, source transform grid, fitted diagnostics, exposure table,
condition denominator table, full `check_drm()` rows, failure table, run
summary, session info, and README.

The active residual `rho12` simulation helpers, tests, design docs, vignettes,
and NEWS references now match the six-nines transform used by the TMB template:
`rho12 = 0.999999 * tanh(eta_rho12)`.

## Mathematical Contract

The fitted surface is complete-row bivariate Gaussian residual correlation
with fixed `rho12 ~ 1` only. The diagnostic uses true correlations 0, 0.4,
0.9, and 0.98 and records the guarded link-equivalent truth, fitted link,
fitted response-scale `rho12`, `1 - rho12^2`, and boundary distance.

The guard keeps the residual covariance matrix inside `(-1, 1)`. It does not
make a near-boundary fit inferentially reliable.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/52-phase-18-bivariate-rho12-ademp.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- Active six-nines synchronization in `NEWS.md`, selected `docs/design/`
  files, `vignettes/bivariate-coscale.Rmd`, `vignettes/source-map.Rmd`,
  `inst/sim/dgp/sim_dgp_biv_rho12.R`,
  `inst/sim/fit/sim_summarise_biv_rho12.R`, and focused `rho12` tests.

## Checks Run

- `/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/run-pilot.R`
- `cd /tmp && /usr/local/bin/Rscript --vanilla /Users/z3437171/.codex/worktrees/1d33/drmTMB/docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/run-pilot.R`
- `/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^(corpairs|profile-targets|phase18-correlation-targets|phase18-biv-rho12-summary-smoke)$', reporter = 'summary')"`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"`
- `rg -n "0\\.99999999|eight-nines" README.md ROADMAP.md NEWS.md docs/design vignettes R tests inst man`
- `rg -n "random effects in ``rho12``|random effects in \`rho12\`|structured.*rho12|structured.*\`rho12\`|rho12.*structured|rho12.*random" README.md ROADMAP.md NEWS.md docs/design vignettes docs/dev-log/dashboard docs/dev-log/after-task/2026-06-18-rho12-open-interval-guard.md docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/README.md`
- `rg -n "CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|fitted.*stability" docs/design/176-numerical-guard-simulation-audit.md docs/design/168-r-julia-finish-capability-matrix.md docs/design/157-capability-completion-worklist.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/after-task/2026-06-18-rho12-open-interval-guard.md docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/README.md NEWS.md`

The runner passed from the package root and from `/tmp`. Focused `rho12` and
correlation-target tests passed, with one pre-existing bootstrap/profile
fixture warning about optimizer non-convergence in a structured
location-scale dependency case. JSON validation, mission-control validation,
`git diff --check`, and `pkgdown::check_pkgdown()` passed.

## Tests Of The Tests

The runner preserves warning and failure denominators even though this run had
zero fit errors. The high-correlation cells exercise the exact diagnostic risk:
the fits converge with `pdHess = TRUE`, but the artifact still records two
starting-value clamps, two fixed-gradient warnings, and one `rho12_boundary`
warning.

## Consistency Audit

Fisher required explicit denominators and boundary exposure columns; the final
artifact includes per-cell requested, attempted, error, warning, convergence,
Hessian, gradient, and `check_drm()` warning/error counts.

Noether and Rose found stale eight-nines residual `rho12` wording in active
simulation helpers, tests, and design docs. Those active sources were
synchronized to six nines. Historical dev-log notes and generated old artifact
outputs were not rewritten.

## GitHub Issue Maintenance

No issue comment has been posted yet. If this branch becomes a PR, the PR body
or issue comment should state that this is residual `rho12` diagnostic evidence
for `drmTMB#59`, not coverage, power, release, CRAN, Julia bridge, random
effects in `rho12`, or structured-correlation support.

## What Did Not Go Smoothly

The first artifact runner lacked denominator and exposure tables. Fisher's
review caught that before documentation was finalized.

The first source scan also exposed stale eight-nines `rho12` text in active
documents and test fixtures. That was useful but widened the slice slightly
from a pure artifact addition to an artifact plus transform-consistency cleanup.

## Team Learning

For numerical-guard work, ask Noether/Rose for constant consistency before the
first runner is finalized. Tiny guard differences are still real
source-of-truth differences when the task is a guard diagnostic.

## Known Limitations

This is a one-replicate-per-cell diagnostic, not a calibration or promotion
grid. It does not attempt profile or bootstrap intervals. It does not test
predictor-dependent `rho12`, missing-response bivariate behavior, random
effects in `rho12`, structured correlations, Julia bridge parity, release
readiness, CRAN readiness, or non-Gaussian REML/AI-REML language.

## Next Actions

Open a small PR for the residual `rho12` diagnostic and six-nines source
synchronization. The next guard slice after this should stay separate:
random-effect/structured correlation guards or Student-t calibration depth, not
both in one PR.
