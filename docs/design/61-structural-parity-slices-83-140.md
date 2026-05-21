# Structural Parity Slices 83-140

This ledger records the post-0.1.3 continuation after the fitted structured
one-slope parity lane. The user-facing question is whether the next ordinary
bivariate random-slope slice helps an applied ecology or evolution user fit a
real plasticity-syndrome model without implying that the full p8/q8
location-scale endpoint is fitted.

## Active Roles

Ada coordinates code, tests, docs, and git state. Boole watches the formula
grammar. Gauss and Noether keep the fitted covariance block and mathematical
claim aligned. Curie owns focused recovery and boundary tests. Fisher keeps
profile-target and Phase 18 admission claims narrow. Pat asks whether a new
applied user can see what is fitted. Grace watches pkgdown, release hygiene,
and CI risk. Rose records stale wording, after-task evidence, and the next
learning loop. Darwin keeps the slope-slope route tied to biological
questions about individual plasticity across two responses.

No spawned subagents were running for this slice set.

## Slice Table

| Slice | Lane | Status | User-facing result |
| --- | --- | --- | --- |
| 83 | Branch and release handoff | Completed | The 0.1.3 prep branch was merged before new post-release work started. |
| 84 | Ordinary bivariate slope parser | Completed | Matching `(0 + x | p | id)` terms in `mu1` and `mu2` now pass the bivariate covariance gate. |
| 85 | Slope design values | Completed | The random-effect design matrix stores the observed numeric slope values instead of intercept-only ones. |
| 86 | Coefficient-aware labels | Completed | SD and correlation names use `mu1:x`, `mu2:x`, and `cor(mu1:x,mu2:x | p | id)`. |
| 87 | Covariance registry | Completed | The fitted row is registered as `slope-slope` with `from_coef = "x"` and `to_coef = "x"`. |
| 88 | Extractors | Completed | `sdpars$mu`, `corpars$mu`, `ranef()`, `corpairs()`, and `summary()$covariance` can expose the slope-slope row. |
| 89 | Profile targets | Completed | The two slope SDs and the slope-slope correlation are direct profile targets. |
| 90 | Diagnostics | Completed | `check_drm()` reports the bivariate `mu` covariance row with `class=slope-slope`. |
| 91 | Focused recovery test | Completed | A seeded bivariate Gaussian simulation checks convergence, extractors, registry rows, profile targets, and diagnostics. |
| 92 | Boundary refresh | Completed | Unsupported bivariate slope combinations now say broader slope covariance remains planned, not that the slope-only route is absent. |
| 93 | Formula grammar | Completed | The grammar marks matching slope-only `mu1`/`mu2` as fitted and p8/q8 endpoints as planned. |
| 94 | README and model map | Completed | High-traffic status tables show the slope-only route in the fitted column. |
| 95 | Family registry | Completed | `biv_gaussian()` status now includes matching slope-only ordinary `mu1`/`mu2` covariance. |
| 96 | Random-effect design notes | Completed | The random-effect design note says Slice 83 opens the first bivariate one-slope route. |
| 97 | Cross-dpar gate | Completed | The cross-parameter gate keeps residual-scale and p8/q8 slope covariance separate from the new route. |
| 98 | Phase 6c status | Completed | The older Phase 6c boundary now records that the first slope-only route has moved from planned to fitted. |
| 99 | Pre-simulation readiness | Completed | Phase 18 admission now allows a small slope-only `mu1`/`mu2` smoke grid, not broader slope grids. |
| 100 | Residual `rho12` separation | Completed | The bivariate residual-correlation sheet keeps residual `rho12` separate from slope-slope group covariance. |
| 101 | Double-hierarchical endpoint map | Completed | The endpoint note marks p8/q8 as planned and the slope-only q=2 row as fitted. |
| 102 | Coscale pair map | Completed | The slope-slope row is described as useful for plasticity-syndrome questions. |
| 103 | Bivariate tutorial boundary | Completed | The bivariate coscale vignette points to the new slope-only route without teaching p8. |
| 104 | Source map | Completed | The source map distinguishes the ordinary slope-only slice from broader cross-parameter covariance. |
| 105 | Which-scale wording | Completed | Planned-neighbour wording now says broader bivariate slopes, not all bivariate slopes. |
| 106 | Validation debt | Completed | The debt register keeps p8/q8 and predictor-dependent slope correlations in the debt ledger. |
| 107 | NEWS | Completed | `NEWS.md` records the user-facing fitted surface and its planned neighbours. |
| 108 | Stale wording scan | Completed | Current high-traffic docs no longer say the matching slope-only route is planned-only. |
| 109 | Direct-SD naming audit | Completed as guardrail | Existing `sd_phylo*()` implementation remains, but generic `sd*()` unification is not claimed in this slice. |
| 110 | Direct-SD product decision | Completed as guardrail | Future direct-SD work should design generic `sd()`/`sd1()`/`sd2()` level targeting across phylo, spatial, animal, and `relmat()`. |
| 111 | Spatial direct-SD boundary | Completed as guardrail | No spatial direct-SD surface is claimed until syntax, likelihood, and diagnostics are added. |
| 112 | Animal direct-SD boundary | Completed as guardrail | No animal-model direct-SD surface is claimed until dense and sparse pedigree scaling are settled. |
| 113 | Relmat direct-SD boundary | Completed as guardrail | No `relmat()` direct-SD surface is claimed until matrix-scale interpretation is explicit. |
| 114 | Coefficient-specific `sd()` boundary | Completed as guardrail | Slope-specific SD formulas such as `sd(id, coef = "x") ~ z` remain reserved. |
| 115 | Bivariate `sd1()`/`sd2()` boundary | Completed as guardrail | Existing bivariate direct-SD routes target location random intercepts, not slope-specific SDs. |
| 116 | Compatibility wording | Completed as guardrail | Current phylogenetic direct-SD names are treated as existing implementation, not a precedent for new structured copies. |
| 117 | Reference discoverability | Completed as guardrail | Future direct-SD unification needs a reference-index pass from a new user perspective. |
| 118 | Syntax collision check | Completed as guardrail | Future generic `sd()` design must avoid ambiguity with ordinary group-level SD models. |
| 119 | Documentation promise | Completed as guardrail | Direct-SD unification stays planned until docs and tests exist, not only parser names. |
| 120 | Phase 18 admission | Completed as guardrail | Direct-SD siblings are not admitted to broad simulations in this slice. |
| 121 | User usefulness check | Completed | The first useful value here is fitting a two-response slope-slope covariance, not renaming syntax midstream. |
| 122 | Direct-SD handoff | Completed | After 140, the generic `sd*()` plan should start with grammar and compatibility design before code. |
| 123 | Non-Gaussian status audit | Completed as inventory | Ordinary Poisson and NB2 `mu` random intercepts and independent slopes remain the fitted non-Gaussian random-effect path. |
| 124 | Non-Gaussian structured boundary | Completed as guardrail | `phylo()`, `spatial()`, `animal()`, and `relmat()` remain Gaussian-only structured routes. |
| 125 | Non-Gaussian slope covariance boundary | Completed as guardrail | Correlated count slopes and labelled count covariance remain planned. |
| 126 | Non-Gaussian scale boundary | Completed as guardrail | Non-Gaussian `sigma` random effects remain blocked or planned by family. |
| 127 | Shape and skew boundary | Completed as guardrail | Shape/skew random effects stay fixed-effect-first and simulation-gated. |
| 128 | Inflation and hurdle boundary | Completed as guardrail | `zi`, `hu`, `zoi`, and `coi` random effects stay outside the fitted surface. |
| 129 | Ordinal boundary | Completed as guardrail | Ordinal random effects remain blocked behind a separate mixed-ordinal design. |
| 130 | Mixed-response boundary | Completed as guardrail | Non-Gaussian bivariate families remain planned until a joint likelihood contract exists. |
| 131 | Structured count fallback | Completed as guardrail | Applied users should use ordinary count random effects when a plain grouping factor is enough. |
| 132 | Simulation admission | Completed | Slope-only bivariate Gaussian can enter a small smoke grid; non-Gaussian structured dependence stays in the failure ledger. |
| 133 | p8 status answer | Completed | True p8/q8 location-scale random slopes have not been fitted. |
| 134 | p8 design risk | Completed | Full p8 would require eight SDs and 28 unstructured correlations, so it needs planning before implementation. |
| 135 | p8 first design gate | Completed | After 140, start with a design table separating slope-only, q4, q6, and p8/q8 endpoints. |
| 136 | p8 user route | Completed | Applied users can use slope-only `mu1`/`mu2` now and wait for p8 until recovery evidence exists. |
| 137 | p8 diagnostics requirement | Completed | Any p8 implementation needs profile-target, Hessian, boundary, and recovery diagnostics before tutorial claims. |
| 138 | p8 documentation requirement | Completed | Any p8 syntax change must update formula grammar, likelihood notes, examples, and known limitations. |
| 139 | After-task protocol | Completed | Check-log and after-task notes record the implementation, checks, boundaries, and next design question. |
| 140 | Handoff boundary | Completed | Next work should plan p8/q8 location-scale and generic `sd*()` unification before adding new broad covariance code. |

## Current Boundary

The newly fitted syntax is intentionally narrow:

```r
bf(
  mu1 = y1 ~ x + (0 + x | p | id),
  mu2 = y2 ~ x + (0 + x | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

This estimates two group-level slope SDs and one ordinary slope-slope
correlation. It does not add intercept-slope correlations, residual-scale
slope covariance, all-four p8/q8 location-scale slope covariance,
predictor-dependent slope `corpair()` regression, random effects in `rho12`,
or non-Gaussian structured dependence.

## Next Design Question

The next location-scale question is p8/q8. Planning should come first. A full
unstructured p8 block has eight endpoint SDs and 28 latent correlations, so the
package should decide whether users first need a smaller block-diagonal route,
a q4 location-only slope block, or a constrained p8 route before any public
syntax is opened.
