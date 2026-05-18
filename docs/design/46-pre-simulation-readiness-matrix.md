# Pre-Simulation Readiness Matrix After Slice 250

This note answers one practical question before broad Phase 18 simulation:
which model surfaces are ready for operating-characteristic grids, and which
surfaces still belong in the failure ledger?

The rule is stricter than "the model fits once". A surface is ready only when
the fitted likelihood, parser boundary, extractors, diagnostics, interval
status, focused recovery tests, and reader-facing boundary are all visible.
The matrix below keeps location, scale, shape, inflation, structured
dependence, and bivariate responses separate so simulation reports do not mix
evidence from one layer into another.

## Current Readiness Matrix

| Surface | Fitted status | Evidence now available | Phase 18 status |
| --- | --- | --- | --- |
| Gaussian fixed-effect location-scale | Fitted | DGP, smoke runner, Wald intervals for fixed formula coefficients, `sigma` summaries, manifests, and failure ledgers | Ready for first small grids |
| Gaussian ordinary `mu` random intercepts and q > 2 random slopes | Fitted | Focused recovery tests, q=3 smoke surface, `sdpars$mu`, random effects, direct profile targets, and diagnostics | Ready for focused grids |
| Gaussian `sigma` random slopes | Fitted for independent one-slope terms | Smoke surface for `(0 + w | id)` on `log(sigma)`, summaries, manifests, and failure ledgers | Ready only for independent one-slope grids |
| Gaussian location-scale covariance | Fitted for supported intercept blocks | `corpairs()`, `summary()` covariance rows, profile targets for direct rows, and diagnostics | Ready for small intercept-block grids, not slope-level covariance |
| Bivariate Gaussian `rho12` | Fitted | Constant and predictor-dependent residual coscale, `rho12()`, row-specific profile support, and tutorial examples | Ready for focused residual-correlation grids |
| Bivariate Gaussian random-effect intercept blocks | Fitted for selected labelled intercept blocks | `sdpars`, `corpars`, `corpairs()`, `summary()` covariance rows, direct profile targets, and diagnostics | Ready for selected intercept-block grids |
| Bivariate Gaussian random slopes | Planned | Explicit parser and error boundaries | Not ready |
| Mixed-response bivariate families | Planned | Clear errors for mixed composed families such as Gaussian plus Poisson | Not ready |
| Meta-analysis with known `V` | Fitted through `meta_V(V = V)` | Vector and dense `V` DGPs, smoke runner, Wald intervals for estimated targets, and safeguards that known `V` is not an interval target | Ready for first small grids |
| Coordinate spatial Gaussian `mu` | Fitted for intercept and one numeric slope | Spatial one-slope smoke surface, direct SD targets, and diagnostics | Ready for focused univariate Gaussian `mu` grids |
| Phylogenetic Gaussian `mu` | Fitted for intercept and selected bivariate intercept structures | Profile targets, direct-SD surfaces, bivariate phylogenetic covariance rows, and examples | Ready for intercept grids; one-slope parity remains planned |
| `animal()` and `relmat()` | Design/planned | ASReml efficiency note and structured-slope parity gate | Not ready |
| Poisson `mu` random effects | Fitted for ordinary non-zero-inflated intercepts and independent numeric slopes | Smoke runner, fixed-effect Wald intervals, direct SD profile intervals, weak-SD boundary test, and diagnostics | Ready for first small non-Gaussian `mu` grids |
| NB2 `mu` random effects | Fitted for ordinary non-zero-inflated intercepts and independent numeric slopes | Smoke runner, fixed-effect Wald intervals, direct SD profile intervals, weak-SD boundary test, and diagnostics | Ready for first small non-Gaussian `mu` grids |
| Zero-truncated NB2 `mu` random effects | Planned | Fixed-effect likelihood exists; random effects are blocked | Not ready |
| Non-Gaussian `sigma` random effects | Blocked | Fixed-effect `sigma` formulas exist for supported families; random-effect bars error clearly | Not ready |
| Shape or skewness random effects | Planned | Shape formulas exist only where already fitted as fixed effects; skewness remains design/research | Not ready |
| Zero-inflation, hurdle, zero-one inflation, and one-inflation random effects | Planned or blocked | Fixed-effect `zi` and `hu` exist for selected count families; random effects are blocked | Not ready |
| Ordinal random effects | Blocked | Cumulative-logit fixed-effect path exists; random effects error clearly | Not ready |
| Structured non-Gaussian dependence | Blocked | Ordinary count `mu` random effects now have first evidence; structured count effects remain blocked | Not ready |
| Cross-parameter non-Gaussian covariance | Blocked | Cross-distributional-parameter correlation gate records the boundary | Not ready |

## What This Means For Simulation

The first broad-looking simulation report should still be built as a set of
small named grids, not as one all-features grid. The ready first-wave surfaces
are Gaussian location-scale, selected Gaussian random-effect/covariance blocks,
meta-analysis with known `V`, coordinate spatial Gaussian `mu`, Poisson `mu`
random effects, and NB2 `mu` random effects. Each report should keep its own
failure ledger and should not borrow interval or diagnostic evidence from a
neighbouring surface.

The main blocked surfaces are not small omissions. Non-Gaussian scale random
effects, shape/skew random effects, inflation random effects, ordinal random
effects, mixed-response bivariate families, animal/`relmat()` models, and
structured non-Gaussian dependence can all change identifiability and runtime.
They should stay out of comprehensive Phase 18 tables until their own focused
gates close.

## Next Surface Decisions

The next implementation choices are therefore narrow:

1. Run tiny optional grids for Poisson and NB2 `mu` random effects, varying
   group count, repeats, true SD, and mean/overdispersion.
2. Return to a blocked model class such as zero-truncated NB2 `mu` random
   effects, ordinal random intercepts, or the first non-Gaussian `sigma`
   random-effect likelihood.
3. Build reader-facing examples for the ready surfaces, especially NB2 counts,
   meta-analysis with known `V`, and coordinate spatial Gaussian `mu`.

The simulation programme can start now for ready surfaces, but the package
should not claim "comprehensive non-Gaussian simulation" until the blocked rows
above have either implementation evidence or a deliberate exclusion rationale.
