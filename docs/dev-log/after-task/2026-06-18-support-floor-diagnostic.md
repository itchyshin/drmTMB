# After-Task Audit: Support-Floor Diagnostic

Date: 2026-06-18  
Task: `drmTMB#59` beta and zero-one beta support-floor diagnostic  
Branch: `codex/support-floor-diagnostic-contract`

## Goal

Bank a diagnostic-only numerical-guard artifact for beta, zero-one beta, and
beta-style missing-predictor support floors. The slice asks where the `1e-12`
beta mean clamp and `1e-8` beta shape floor activate, whether small fitted
response-route examples report floor-active shape vectors, and whether
boundary validation errors remain visible.

This task does not change the package API, formula grammar, likelihood
parameterization, optimizer behavior, or user-facing warnings.

## Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-18-support-floor-diagnostic/`.
- Added `run-pilot.R`, which writes deterministic source summaries, fitted
  diagnostics, `check_drm()` rows, validation-error rows, unexpected-failure
  rows, a run summary, and session info.
- The runner resolves the repository root from its own file path and records
  UTC timestamp, git SHA, branch, dirty state, and command in the run summary
  and session info.
- Added artifact README text naming the diagnostic contract, outputs, results,
  and non-claims.
- Updated the numerical-guard audit, finish matrix, capability worklist,
  dashboard JSON, sweep JSON, and check log to keep the support-floor evidence
  aligned with the active `drmTMB#59` row.

## Mathematical Contract

The diagnostic mirrors the beta-family guard algebra used by the TMB template:

```text
mu = 1e-12 + (1 - 2e-12) * plogis(eta_mu)
phi = exp(-2 * log_sigma)
alpha_raw = mu * phi
beta_raw = (1 - mu) * phi
alpha = max(alpha_raw, 1e-8)
beta_shape = max(beta_raw, 1e-8)
```

The source grid evaluates this contract for beta response, zero-one beta
response, beta missing-predictor, and zero-one beta missing-predictor routes.
The fitted cells use the default optimizer path. No multi-start, fallback
optimizer, wider clamp, or forced-convergence trick is used.

## Evidence

The runner completed with:

```text
artifact=2026-06-18-support-floor-diagnostic
master_seed=20260618
n_source_rows=60
n_fit_cells=6
n_fit_errors=0
n_fit_cells_with_reported_shapes=4
n_validation_cells=6
n_validation_expected_errors=6
max_reported_fit_alpha_floor_count=0
max_reported_fit_beta_floor_count=0
```

Source-level shape-floor activation was absent at
`log_sigma = log(0.5)` and `log_sigma = log(2)`. It appeared in high-scale
source cells: 4/12 alpha and 4/12 beta-shape floor activations at
`log_sigma = 8`, then 12/12 and 12/12 at `log_sigma = 12` and
`log_sigma = 16`.

All 6 small fitted cells converged with `pdHess = TRUE` and no fit errors. Four
fitted response-route cells exposed `alpha` and `beta_shape`; none reported
either vector at the `1e-8` floor. The two fitted missing-predictor cells did
not expose `alpha` or `beta_shape` in the TMB report, so their fitted
shape-floor counts are recorded as `NA`, not zero. The largest fixed-gradient
diagnostic was `0.002022189` in the valid missing-predictor zero-one beta cell,
where `check_drm()` marked fixed-gradient and standard-error rows as warnings.

All 6 validation cells errored with the expected boundary messages. Exact 0
and 1 beta responses, out-of-range zero-one beta responses, all-boundary
zero-one beta responses, boundary beta predictors, and all-boundary zero-one
beta predictors were rejected visibly before a density floor could hide the
boundary problem.

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-support-floor-diagnostic/run-pilot.R
cd /tmp && /usr/local/bin/Rscript --vanilla /Users/z3437171/.codex/worktrees/1d33/drmTMB/docs/dev-log/simulation-artifacts/2026-06-18-support-floor-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla -e "devtools::test(filter = '^(beta-location-scale|zero-one-beta|missing-predictor-beta|missing-predictor-zero-one-beta)$', reporter = 'summary')"
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
python3 tools/validate-mission-control.py
git diff --check
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript -e "pkgdown::check_pkgdown()"
rg -n "CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|fitted.*stability" docs/design/176-numerical-guard-simulation-audit.md docs/design/168-r-julia-finish-capability-matrix.md docs/design/157-capability-completion-worklist.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/after-task/2026-06-18-support-floor-diagnostic.md docs/dev-log/simulation-artifacts/2026-06-18-support-floor-diagnostic/README.md
```

The artifact runner, focused tests, JSON parsing, mission-control validation,
`git diff --check`, and local pkgdown check passed. The boundary scan found
only intentional or pre-existing guardrail wording, not a new coverage, power,
release, CRAN, Julia bridge, or non-Gaussian AI-REML claim.
The artifact runner also passed when launched from `/tmp`, confirming that it
does not depend on the caller's working directory.

## What Did Not Go Smoothly

A plain near-boundary beta fit did not activate the fitted shape floor, and
`offset()` terms in the `sigma` formula are not supported for this route. The
diagnostic therefore uses a source-level high-scale grid for floor activation
and keeps the fitted cells as ordinary/boundary-near status evidence. That is a
better answer than forcing convergence or inventing an optimizer trick.

## Current External Gate State

At the start of this branch, `origin/main` was
`32741fa683df16164b5bbfb686c90ccd988d95c4`, which is newer than the handoff
anchor `01c7f5c1b18b42ef0d81ca132eba9a204b0a22c9`.

Post-merge main R-CMD-check run `27765267220` passed for `32741fa6` on macOS,
Ubuntu, and Windows. Matching pkgdown run `27767064877` initially cancelled
during dependency setup, then passed on rerun for the same SHA: pkgdown built
in 25m21s and deploy completed in 1m14s. Pages returned HTTP 200 with
`last-modified: Thu, 18 Jun 2026 15:43:02 GMT`.

## Boundaries

This is diagnostic evidence only. It does not promote beta or zero-one beta
interval coverage, power, profile intervals, bootstrap intervals, random
effects, structured effects, bivariate bounded responses, missing-data breadth,
Julia bridge parity, release readiness, CRAN readiness, or non-Gaussian
REML/AI-REML claims.

## Next Safe Step

Open a small PR for this support-floor diagnostic branch, then wait for PR
R-CMD-check and pkgdown before merging.
