# After Task: Skew-Normal Guard-Grid Diagnostic

## Goal

Bank the fourth Big 4 block as native R/TMB fixed-effect skew-normal diagnostic
evidence, separating generating-scale and fitted-scale tail-floor exposure
without promoting recovery, intervals, comparator parity, Julia bridge parity,
release readiness, or CRAN readiness.

## Implemented

Added
`docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/`.
The artifact runner fits
`bf(y ~ x, sigma ~ z, nu ~ w), family = skew_normal()` across ordinary,
moderate-tail, extreme-tail, and deliberately injected tail cells. It records
the response mean `mu`, residual SD `sigma`, and residual slant `nu` coefficient
truth and estimates, while also recording the internal tail-floor diagnostic on
the fitted native `alpha * z` scale.

The artifact writes condition, fit-diagnostic, `check_drm()`, tail-exposure,
coefficient, coefficient-summary, condition-summary, failure, run-summary,
README, and session-info files.

## Evidence

The full run requested 200 complete-data fits across 8 cells with 25 replicates
per cell. All 200 fits returned, converged, and had `pdHess = TRUE`. The run
wrote 1200 coefficient rows and 102000 observation rows.

The injected near-floor and floor-dominated cells produced generating-scale
floor exposure as intended, with up to 8 generating floor-dominated observations
per replicate. No fitted-scale row had floor-dominated observations. The
maximum fitted-scale absolute log-CDF lift was `8.88178419700125e-16`.

The result is not clean promotion evidence: 27 fits retained fixed-gradient
warnings. Cell-level fixed-gradient ok rates ranged from 0.68 to 1.00, so the
overall decision is `diagnostic_hold`.

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/run-pilot.R
DRMTMB_SKEW_NORMAL_GUARD_REPS=1 /usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "skew-normal|phase18-skew-normal-fixed-effect|confint-skew-normal-slant", reporter = "summary")'
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-gate-vs-engine|julia-tmb-parity", reporter = "summary")'
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
```

Artifact consistency assertions passed after the full run. Focused skew-normal
tests passed for the slant `confint()` warning, fixed-effect Phase 18
runner/writer, density contract, and location-scale tests. Dashboard JSON
parsing passed, `tools/validate-mission-control.py` reported 25/68
banked_or_verified, 1 active, 17 matrix rows, 11 finish rows, 15 Julia gate
rows, and 9 Julia capability rows, and `git diff --check` passed.
The R-side Julia gate/parity boundary test passed with one existing intentional
skip for the tracked Gaussian phylo-mean all-node log-likelihood bug. This is
a bridge-boundary check only; Block 4 makes no skew-normal direct Julia or
Julia-via-R claim. `pkgdown::check_pkgdown()` found no problems.

The #59 breadcrumb was posted:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4752927665.

## Team Review

Curie recommended explicit denominators, separate generating/fitted
tail-exposure rows, and no interval or Julia claims. Fisher kept the decision
boundary at `needs_larger_grid` or `diagnostic_hold`, with `diagnostic_hold`
required for repeated fixed-gradient warnings. Pat asked for applied-reader
wording that treats non-convergence, non-positive Hessians, fixed-gradient
warnings, and large `skew_normal_nu` diagnostics as “not usable inference”
even when the likelihood is finite. Rose identified the worklist, finish
matrix, numerical-guard audit, dashboard, README, NEWS, and ROADMAP wording
that needed synchronized updates.

## Boundary

This is native R/TMB fixed-effect skew-normal guard-grid evidence only. It does
not support skew-normal recovery accuracy, standard-error reliability,
Wald/profile/bootstrap interval calibration, coverage, power, random effects,
structured effects, bivariate skew-normal models, residual `rho12`, external
comparator parity, release readiness, CRAN readiness, direct Julia parity,
Julia-via-R parity, or non-Gaussian REML/AI-REML.

## Next Actions

Keep skew-normal tail-floor exposure and fit-health status together in future
summaries. Any next skew-normal work should choose between fixed-gradient
diagnostics, a formal operating-characteristic grid, or an external comparator
study; none of those are implied complete by this guard grid.
