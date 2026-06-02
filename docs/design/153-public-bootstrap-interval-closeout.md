# Public Bootstrap Interval Closeout

## Purpose

Issue #265 asked for a public bootstrap confidence-interval design before
`drmTMB` advertised bootstrap intervals for hard fits. The issue can close at
the first public boundary: `confint(..., method = "bootstrap")` is implemented
for selected direct fitted-object targets, with visible refit success and
failure accounting. This is not a package-wide hard-fit rescue layer.

The supported user route is:

```r
confint(fit, parm = "variance_components", method = "bootstrap", R = 199)
confint(fit, parm = "rho12", method = "bootstrap", R = 199)
```

These calls simulate from the fitted model, refit each simulated response,
extract the requested direct target from each refit, and return percentile
intervals. Positive scale and standard-deviation targets take percentiles on
the fitted log scale before transforming endpoints back to the public positive
scale.

## Issue Checklist

| #265 requirement | Current evidence | Boundary kept visible |
| --- | --- | --- |
| Target extraction for fixed effects, direct SDs, residual `rho12`, and supported latent correlation rows | `profile_targets()` supplies the fitted-object inventory, `profile_match_bootstrap_targets()` filters requested targets, and `bootstrap_supported_targets()` shares the direct-target gate with Wald intervals. Focused tests cover fixed effects, direct scale, ordinary and structured SDs, random-effect correlations, and residual or latent correlation rows. | Derived q4 correlations, covariance products, modelled `sd(group)` rows, repeatability, phylogenetic signal, custom contrasts, prediction rows, and `newdata` response-scale rows remain unsupported. |
| Refit contract, seed control, and worker provenance | `confint.drmTMB()` exposes `R`, `seed`, `parallel`, `workers`, and `refit_control`. `drm_bootstrap_confint()` calls `simulate()` with the seed, refits with stored model data, and returns `bootstrap.parallel` and `bootstrap.workers`. | PSOCK and nested parallelism are not part of the public fitted-model route. |
| 10-core cap and no nested parallelism | `bootstrap_parallel_plan()` caps actual workers at 10, at `R`, and at requested workers; Windows rejects `parallel = "multicore"`. Phase 18 private bootstrap helpers use the same bounded-worker discipline. | The public route is still an explicit user request, not an automatic fallback during fitting or summaries. |
| Failure ledger for non-convergence, non-finite statistics, boundary fits, and too few successful draws | Each interval row reports `bootstrap.n`, `bootstrap.failed`, and `profile.message`; rows with fewer than two successful finite refits return `conf.status = "bootstrap_unavailable"`. Refit errors and failed target extraction stay out of successful counts. | Bootstrap rows do not classify every profile-shape failure or prove coverage; Phase 18 operating-characteristic simulations remain separate evidence. |
| Documentation separating Wald, profile, bootstrap, and simulation intervals | `R/profile.R`, `README.md`, `docs/design/12-profile-likelihood-cis.md`, `docs/design/43-phase-18-interval-producer-contract.md`, and `docs/dev-log/known-limitations.md` separate direct Wald, profile-likelihood, public `confint()` bootstrap, and Phase 18 simulation-table intervals. | `summary(conf.int = TRUE, method = "bootstrap")`, `corpairs(conf.int = TRUE, method = "bootstrap")`, prediction-table bootstrap intervals, and derived-target bootstrap intervals are still unavailable. |
| Examples that keep weak-Hessian limits explicit | User-facing prose describes bootstrap as a slower simulation-refit audit, not a replacement for Wald or profile intervals. Non-positive-definite Hessian fits keep point estimates but do not advertise Hessian-based Wald intervals. | A bootstrap interval is only as useful as the fit, simulation path, refits, and target extraction. Users still need `check_drm()`, profile diagnostics, convergence checks, and enough successful refits. |

## Current Public Contract

The public contract is intentionally direct-target only.

- `confint(fit)` remains the fast default Wald route when `TMB::sdreport()` is
  available and positive definite.
- `confint(fit, method = "profile")` remains the likelihood-shape diagnostic
  route for explicit direct targets and row-specific `newdata` scale or
  residual-correlation targets.
- `confint(fit, method = "bootstrap")` is a simulate/refit percentile route for
  direct fitted-object targets that can be extracted by `profile_targets()`.
- Phase 18 bootstrap artifacts remain simulation evidence with their own
  artifact-grain, MCSE, coverage, and failure-ledger vocabulary.

The closeout deliberately leaves broader interval work open. Derived
nonlinear quantities need a separate fix-and-refit or reparameterized interval
method before they can become confidence intervals. Simulation recovery,
coverage, power, and Type I error claims still belong to #59.

## Closeout Decision

Issue #265 can close because its public-design prerequisites are implemented,
documented, and tested for the first direct `confint()` bootstrap boundary.
The remaining work is no longer the #265 design blocker; it is narrower
follow-up work on derived intervals, summary/extractor routing, prediction
tables, and Phase 18 operating-characteristic evidence.
