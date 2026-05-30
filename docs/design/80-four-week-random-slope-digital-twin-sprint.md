# Four-Week Random-Slope and Digital-Twin Sprint

## Purpose

This note turns the 2026-05-30 planning session into a repo-visible sprint
contract. The reader is a future `drmTMB` contributor deciding which issue to
open next, which status claim is already supported, and which sister-package
lesson can be used only as a candidate design signal.

Parent issue: <https://github.com/itchyshin/drmTMB/issues/436>

Child issues:

- #437: daily digital-twin and sister-package exchange.
- #438: random-slope support matrix refresh.
- #439: Gaussian ordinary random-slope closeout.
- #440: bivariate Gaussian slope-only evidence gate.
- #441: non-Gaussian independent `mu` slope admission.
- #442: structured Gaussian one-slope audit.
- #443: coscale and `corpairs()` boundary.
- #444: random-slope tutorial and release ledger.

Simulation planning issue:

- #59 is the Phase 18 simulation mega-issue for power, accuracy, coverage,
  runtime, and failure-mode evidence across families and model types.
- #255 is the artifact-grain child issue that keeps replicate-level rows,
  aggregate summaries, MCSE intervals, and figure geometry honest.
- #60 is the smaller comparator-package lane for `glmmTMB`, direct TMB
  baselines, Julia twins such as `DRM.jl` and `GLLVM.jl`, and other packages
  where the parameter target is genuinely comparable. Comparator or twin
  results can motivate `drmTMB` simulations, but they are not `drmTMB`
  coverage evidence.

## Current Sprint Matrix

| Layer | Current status | Sprint action |
| --- | --- | --- |
| Ordinary Gaussian `mu` | Fitted for independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric location blocks. | Use #439 to consolidate q=3 recovery, extractor, `summary()`, `corpairs()`, and direct-SD profile evidence. |
| Gaussian `sigma` | Fitted for random intercepts and multiple independent numeric slopes on `log(sigma)`. | Use #439 to keep correlated residual-scale slope blocks and labelled residual-scale slope covariance planned, not fitted. |
| Bivariate Gaussian covariance | Fitted for selected labelled intercept blocks and matching slope-only `mu1`/`mu2` blocks. | Use #440 to promote or hold the `biv_gaussian_mu_slope` grid from dispatch/artifact evidence to recovery evidence. |
| Non-Gaussian `mu` slopes | Fitted or source-tested for selected ordinary independent `mu` slope paths, depending on family. | Use #441 to admit families one by one; do not write a broad non-Gaussian slope claim. |
| `phylo()`, `spatial()`, `animal()`, `relmat()` | First univariate Gaussian `mu` one-slope paths are fitted as independent intercept and slope fields. | Use #442 to audit tests, diagnostics, profile targets, and q2/q4 status; keep multiple structured slopes, slope correlations, residual-scale structured slopes, structured `rho12`, and non-Gaussian structured slopes planned. |
| Coscale and correlation extraction | Residual `rho12` and fitted group/structured covariance rows are separate output layers. | Use #443 to keep `rho12`, `corpair()`, and `corpairs()` wording precise in random-slope examples. |
| Tutorial and release ledger | Existing tutorials cover pieces of the ordinary core and bivariate/coscale surfaces. | Use #444 to produce a reader-facing path and reference-index check after status wording is reconciled. |

## Issue #438 Support-Matrix Labels

Use these labels in #438, the roadmap, and pkgdown pages until a later evidence
slice supersedes them. Fitted support, simulation admission, and interval
readiness are separate claims.

| Label | Current cells | Evidence handles |
| --- | --- | --- |
| Fitted | Ordinary Gaussian `mu` random intercepts/slopes, independent Gaussian `sigma` slopes, selected bivariate Gaussian covariance, residual `rho12`, Gaussian structured `phylo()`/`spatial()`/`animal()`/`relmat()` intercept and one-slope `mu` rows, ordinary Poisson/NB2 `mu` slopes, and selected ordinary non-Gaussian `mu` slopes. | `docs/design/46-pre-simulation-readiness-matrix.md`, `docs/design/59-structural-slope-and-non-gaussian-map.md`, `vignettes/implementation-map.Rmd`, and the current README/model-map status rows. |
| Simulation-ready | Registry rows marked `ready_grid`, including `gaussian_ordinary_mu_slopes`, `gaussian_sigma_independent_slopes`, `bivariate_gaussian_slope_only`, residual `rho12`, selected ordinary q=2 `corpairs()` rows, ordinary Poisson/NB2 `mu` random effects, and Gaussian structured one-slope rows queued for focused wrappers. | `inst/sim/registry/phase18_structured_workflow_registry.csv` and `docs/design/143-phase-18-structured-workflow-registry.md`. |
| Smoke or source-only | Selected bounded, positive-continuous, Student-t, and zero-truncated NB2 ordinary `mu` independent slopes; NB2 `sigma` random intercepts; Poisson q=1 phylogenetic formal-admission lane; NB2 q=1 phylogenetic held-smoke lane. | Registry rows with `ready_source_test`, `ready_smoke`, `smoke_formal_admission`, or `hold_smoke_only`. |
| Diagnostic-only | Ordinary or structured q=4 `corpairs()` rows, q=4 spatial/animal/`relmat()` location-scale point-estimate lanes, count q=1 spatial/animal/`relmat()` structured rows before formal recovery, and Ayumi hard real-data q2/q4 cases. | Registry rows marked `diagnostic_only`, plus hard-fit diagnostics in `docs/design/46-pre-simulation-readiness-matrix.md`. |
| Design-only | Mixed-response bivariate families and any future joint/coplanar likelihood or latent contract work. | `mixed_response_bivariate` in the Phase 18 registry. |
| Unsupported or blocked | Count labelled q2/q4 covariance, random effects in `rho12`, correlated non-Gaussian slopes, structured count slopes, zero-inflation/hurdle random effects, Student-t `nu` random effects, ordinal random effects, NB2 `sigma` slopes, and structured `sigma`. | Registry rows marked `blocked`, failure-ledger text in the readiness matrix, and the implementation-map planned-neighbour rows. |

## Simulation Admission Bridge

The four-week sprint does not replace the larger Phase 18 simulation programme
in #59. Each capability child issue should end by saying whether the surface is
documentation-only, source or smoke only, simulation-ready, or ready for a
larger operating-characteristic grid. A supported claim needs local `drmTMB`
evidence for the relevant estimand, not only a successful fit.

For every surface promoted from fitted to simulation evidence, require a small
ADEMP sheet or equivalent row that names the aim, data-generating mechanism,
estimand, fitted method, performance measures, replicate plan, and Monte Carlo
standard-error target. The minimum performance vocabulary is bias or accuracy,
RMSE, interval coverage, power or Type I error when a null comparison is part
of the question, convergence and Hessian status, boundary rate, and runtime.

Keep the first Phase 6c simulation bridge narrow:

- #439 queues ordinary Gaussian q > 2 `mu` slopes and independent Gaussian
  `sigma` slopes into #59 only when extractor and direct-SD interval targets
  are stable.
- #440 queues the bivariate Gaussian slope-only lane into #59 only when
  residual `rho12` is separated from group-level covariance in the estimands
  and report tables.
- #441 queues non-Gaussian independent `mu` slopes family by family, with
  fixed-effect likelihood and interval evidence ahead of random-effect claims.
- #442 queues structured Gaussian one-slope rows only as one-slope rows; q2/q4
  structured covariance, multiple structured slopes, and structured
  residual-scale slopes remain separate design or diagnostic lanes.

## Daily Twin/Sister Exchange

The daily exchange lives in #437 and in
`docs/dev-log/twin-sister-exchange.md`. Each lesson card records source repo,
branch/commit, observed pattern, applicability, proposed `drmTMB` action,
provenance risk, and comment status.

The direct digital twin is `DRM.jl`. It is an MIT Julia package that mirrors
the `drmTMB` formula surface and aims to become the fastest correct engine for
the one-response and two-response `drmTMB` model class. Treat it as a design
mirror, not a dependency.

The sister package is `gllvmTMB`, with Julia digital twin `GLLVM.jl`. They
are useful for performance, validation, and workflow
lessons, but higher-dimensional latent-variable models remain out of
`drmTMB` scope. Their speed and coverage results motivate candidate benchmark
or diagnostic slices only; they are not `drmTMB` evidence.

## Guardrails

- Keep `drmTMB` to one-response and two-response models.
- Keep residual `rho12`, ordinary group-level covariance, structured
  covariance, and known-matrix covariance as separate layers.
- Do not change formula grammar without updating
  `docs/design/01-formula-grammar.md`.
- Do not change likelihood parameterisation without updating
  `docs/design/03-likelihoods.md`.
- Do not port or adapt code from another package without recording source,
  commit, license, adaptation, and reviewer in `inst/COPYRIGHTS`.
- Do not describe `DRM.jl`, `GLLVM.jl`, or benchmark-repo
  performance as `drmTMB` performance until a `drmTMB` benchmark or simulation
  artifact exists.
