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
