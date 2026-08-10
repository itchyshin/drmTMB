# Plan versus actual: experimental binomial-logit MSPL (2026-08-08)

| Planned commitment | Actual | Verdict |
| --- | --- | --- |
| Recycle released `drmTMB-rose-nit` | Reused the released worktree on `codex/mspl-binomial-glmm-experimental` from exact `origin/main` `efb5af4f`; primary and retained S0 worktrees were untouched | Met |
| Clean-room Jeffreys implementation | Implemented from the published equations; no v8 source was inspected or copied | Met |
| Freeze `c_n`, `n_eff`, offsets, and Cholesky coordinates | Symbolic design, R kernels, C++ objective, independent tests, and receipt use one contract | Met |
| Add ordinary q=2 correlated binomial path coherently | Likelihood, extraction, point prediction, fresh simulation, reporting, and tests use the stable tanh/sech map | Met |
| Add opt-in `estimator = c("ml", "mspl")` | Default ML is unchanged; MSPL is narrow, experimental, and point-only | Met |
| Reject unsupported cross-products | Engine, link/family, REML, penalty, missing response, rank, weights, q>=3, multiple groups, and unsupported structures are fenced | Met |
| Store penalized/unpenalized objectives and diagnostics | `fit$mspl` stores objective components, scaling, detector result, gradient, outer Hessian, and boundary facts; `fit$logLik` is unavailable | Met after review repair |
| Fence likelihood inference and intervals | `logLik()`, AIC/BIC, `anova()`, `vcov()`, Wald SEs, profiles, and confidence intervals fail loudly; point predictions remain | Met |
| Verify separation, transformations, multistart, and exact quadrature | q1/q2 deterministic fixtures, ML comparisons, objective rays, stable boundary probes, independent value/gradient oracle, and exact-criterion q1/q2 re-optimization pass locally | Met |
| Retain failures and independent reviews | Failed runs and first NOT-DONE reviews remain recorded; architecture, inference, and local mechanical re-reviews returned DONE | Met |
| Local toy verification only | No Totoro, DRAC, GitHub Actions, or interval calibration was launched | Met |
| No PR, push, or merge | No remote mutation occurred | Met |

## Material adaptations

- The symbolic draft originally required a remote recovery campaign inside
  Phase 3. That contradicted the approved local-only operational boundary. The
  corrected design distinguishes local implementation validation from a later,
  separately authorized recovery/calibration campaign.
- The initial quadrature spike measured exact likelihood only at the Laplace
  solution. Inference review correctly required independent full-criterion
  re-optimization and fixed-vector value/gradient agreement; both were added.
- The q=2 prerequisite changed a real ML model surface, so status documentation
  was synchronized despite the lane being experimental and branch-local.
- A fresh completion audit showed that the first synchronization was too
  narrow: the core rejection guidance and several current random-effect/model
  map surfaces still stated the old blanket prohibition. Those neighbours were
  reconciled, every pkgdown article was rebuilt and checked, and the full
  package check was rerun on the repaired snapshot.

## Safety and claim reconciliation

The earned claim is limited to an experimental, locally verified
binomial-logit MSPL point-estimation route for the declared q1/q2 ordinary
random-effect cells. It is not evidence of recovery, calibration, interval
validity, release readiness, or a general GLMM/latent-variable solution.

The branch stops before Totoro. A compute campaign, PR, push, merge, or package
support promotion requires a new authorization and evidence plan.
