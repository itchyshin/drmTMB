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

## Slice 268 Capability Audit

This audit condenses the readiness matrix into the model classes that a Phase
18 report writer is most likely to ask about. "Implemented" means a fitted
likelihood or exported parser surface exists. "Tested" means there is focused
test, smoke-simulation, profile, diagnostic, or rendered-document evidence for
the implemented surface named in the row. "Planned" and "unsupported" rows stay
out of operating-characteristic tables except as failure-ledger entries.

| Capability area | Implemented status | Tested status | Planned or unsupported boundary | Phase 18 admission |
| --- | --- | --- | --- | --- |
| Gaussian models | Implemented for fixed-effect location-scale, ordinary `mu` random intercepts and q > 2 random slopes, independent `sigma` random slopes, selected location-scale covariance blocks, and all-Gaussian bivariate `mu1`/`mu2` surfaces | Tested with focused recovery tests, smoke runners, direct profile targets, diagnostics, and reader examples for the fitted subsets | Bivariate random slopes, slope-level location-scale covariance, q=6/q=8 endpoint blocks, and richer structured Gaussian covariance remain planned | Admit the named fitted subsets as small grids, not as a blanket "all Gaussian" claim |
| Non-Gaussian models | Implemented for fixed-effect count, bounded, positive-continuous, and ordinal families, plus ordinary non-zero-inflated Poisson and NB2 `mu` random intercepts and independent numeric slopes | Tested for the fixed-effect paths and for Poisson/NB2 `mu` random-effect smoke surfaces, Wald rows, profile SD rows, and weak-SD diagnostics | Non-Gaussian `sigma` random effects, structured non-Gaussian effects, mixed-response bivariate families, and most non-Gaussian random-effect covariance remain planned or unsupported | Admit only the ordinary Poisson and NB2 `mu` random-effect smoke grids for non-Gaussian mixed models |
| Shape and skewness | Implemented only where fixed-effect shape formulas already exist, such as Student-t `nu`; skew-family work remains a design lane | Tested for existing fixed-effect shape boundaries, not for shape random effects or skew-family likelihood recovery | `nu` random effects, a second shape parameter, skew-normal/skew-t likelihoods, and ID-level skewness random effects remain planned or unsupported | Do not admit shape or skewness random-effect grids |
| Inflation and hurdle parameters | Implemented as fixed-effect `zi` or `hu` formula paths for selected count models | Tested as fixed-effect response components and unsupported-boundary cases where applicable | `zi`, `hu`, `zoi`, `coi`, and hurdle random effects, plus cross-parameter covariance with inflation parameters, remain planned or unsupported | Keep inflation-random-effect and hurdle-random-effect surfaces in the failure ledger |
| Bivariate models | Implemented for two-response Gaussian models with separate `mu1` and `mu2` formulas, residual `rho12`, selected labelled random-intercept covariance blocks, and selected phylogenetic location correlations | Tested with bivariate Gaussian, `rho12`, `corpairs()`, profile-target, summary-covariance, and tutorial evidence for the fitted subsets | Mixed-response bivariate models, bivariate random slopes, `rho12` random effects, and broad q=4/q=8 slope covariance remain planned or unsupported | Admit constant or predictor-dependent residual `rho12` and selected intercept-block covariance grids |
| Random slopes | Implemented for ordinary Gaussian `mu` multi-slope blocks, independent Gaussian `sigma` one-slope terms, ordinary Poisson/NB2 `mu` independent numeric slopes, and coordinate spatial Gaussian `mu` one-slope fields | Tested with focused recovery, smoke, direct profile, weak-boundary, and diagnostic checks for those fitted paths | Correlated non-Gaussian slopes, bivariate random slopes, phylogenetic slopes, animal slopes, `relmat()` slopes, and spatial slope correlations remain planned or unsupported | Admit only the fitted ordinary, count-`mu`, and coordinate-spatial one-slope cases |
| Meta-analysis | Implemented for Gaussian models with known sampling covariance through `meta_V(V = V)` and the compatibility alias `meta_known_V(V = V)` | Tested for vector and dense `V`, summary-smoke output, Wald rows for estimated targets, and interval safety that keeps known `V` out of confidence-interval targets | Proportional sampling-variance models, multiple variance-component meta-analysis, and phylogenetic-plus-study extensions remain planned | Admit vector and dense known-`V` Gaussian grids, with `V` treated as input data |
| Phylogenetic models | Implemented for Gaussian `mu` intercept effects, selected bivariate `mu1`/`mu2` phylogenetic location correlations, constant q=4 location-scale blocks, and direct `sd_phylo*()` paths | Tested with profile targets, direct-SD surfaces, bivariate phylogenetic covariance rows, diagnostics, and examples for the fitted intercept and direct-SD paths | Phylogenetic `mu` slopes, richer q=4 predictor-dependent `corpair()` regressions, and phylogenetic non-Gaussian effects remain planned or unsupported | Admit intercept and documented direct-SD subsets; keep slope grids out |
| Spatial models | Implemented for coordinate spatial Gaussian `mu` intercepts and one numeric slope with independent spatial fields | Tested with a coordinate-spatial one-slope smoke surface, direct SD targets, `ranef("spatial_mu")`, diagnostics, and reader-facing boundary text | Mesh/SPDE models, multiple spatial slopes, spatial slope correlations, spatial `sigma`, bivariate spatial q=4, spatial direct-SD, and spatial `corpair()` regressions remain planned | Admit only univariate Gaussian coordinate-spatial `mu` intercept and one-slope grids |
| `animal()` models | Exported and parsed as planned structured-effect markers, but no fitted likelihood exists | Tested as reference/parser and unsupported-boundary surface, not as a fitted model | Pedigree, `A`, and `Ainv` animal-model likelihoods, diagnostics, profile targets, and recovery tests remain planned | Do not admit fitted animal-model grids |
| `relmat()` models | Exported and parsed as a lower-level planned known-relatedness marker, but no fitted likelihood exists | Tested as reference/parser and unsupported-boundary surface, not as a fitted model | User-supplied `K` or `Q` fitting, matrix validation, diagnostics, profile targets, and recovery tests remain planned | Do not admit fitted `relmat()` grids |

## Current Readiness Matrix

| Surface | Fitted status | Evidence now available | Phase 18 status |
| --- | --- | --- | --- |
| Gaussian fixed-effect location-scale | Fitted | DGP, smoke runner, Wald intervals for fixed formula coefficients, `sigma` summaries, manifests, and failure ledgers | Ready for first small grids |
| Gaussian ordinary `mu` random intercepts and q > 2 random slopes | Fitted | Focused recovery tests, q=3 smoke surface, q=4 output-name check, `sdpars$mu`, random effects, direct profile targets, and diagnostics | Ready for focused grids, with larger q treated as advanced |
| Gaussian `sigma` random slopes | Fitted for multiple independent one-slope terms, including separate grouping factors | Smoke surface for `(0 + w | id)` on `log(sigma)`, cross-group output-contract checks, summaries, manifests, and failure ledgers | Ready only for independent one-slope grids |
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
