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

Slice 283 adds the family-level crosswalk in
`docs/design/02-family-registry.md`, listing each public family route,
distributional-parameter link, shape or coscale slot, fitted random-effect
allowance, and test-evidence state. Treat that map as the source check before
adding a family to a Phase 18 grid.

## Slice 291 Evidence-Ledger Gate

This gate maps the public stable-core rows to the evidence a Phase 18 report
writer must find before a surface enters a simulation grid. "Advertised" here
means a surface appears in README, the model-map article, a package reference
topic, or a Phase 18 DGP row as fitted, stable, first slice, or opt-in
control. Planned or blocked rows can appear only as failure-ledger rows.

| Public row | Implementation evidence | Test, diagnostic, or interval evidence | User-facing boundary | Simulation status after Rose/Fisher signoff |
| --- | --- | --- | --- | --- |
| Fixed-effect one-response families | Family registry entries and likelihood rows in `docs/design/02-family-registry.md` and `docs/design/03-likelihoods.md` | Family-specific tests listed in `docs/design/34-validation-debt-register.md`; fixed-effect Wald rows for count, proportion, ordinal, and continuous-shape paths where recently hardened | Distribution-family tutorial and stable-core matrix separate fitted fixed-effect families from random-effect extensions | Admit named fixed-effect families; do not borrow this evidence for non-Gaussian random effects |
| Gaussian ordinary random effects | Gaussian `mu` intercepts, independent slopes, one-slope correlated blocks, q > 2 numeric `mu` blocks, `sigma` intercepts, and independent `sigma` slopes are fitted | Random-effect, profile-target, comparator, weak-boundary, and `check_drm()` evidence in the validation-debt register and recent random-slope slices | README, model-map, and which-scale docs mark larger q blocks as fitted but sample-size hungry | Admit small Gaussian ordinary grids; label q > 2 grids as advanced |
| Random-effect scale `sd(group)` models | Unlabelled Gaussian `mu` random-intercept SD surfaces are fitted | Recovery and comparator tests exist; row-specific SD summaries remain derived | `sd(group) ~ x_group` is the public fitted syntax; coefficient-specific slope-SD formulas stay reserved | Admit only the unlabelled intercept-SD surface |
| Known sampling covariance | Gaussian `meta_V(V = V)` fits diagonal, dense, and row-paired bivariate known sampling covariance | Vector, dense, bivariate, interval-safety, and `check_drm()` evidence exist | Meta-analysis docs keep known sampling covariance `V` separate from latent relatedness and fitted residual `sigma` | Admit vector and dense known-`V` Gaussian grids with `V` treated as input data |
| Bivariate residual `rho12` | Two-response Gaussian models fit fixed and predictor-dependent residual `rho12` | `rho12()`, profile-target, row-specific profile, and tutorial evidence exist | Docs keep residual coscale separate from group, phylogenetic, spatial, and known-sampling covariance | Admit residual-correlation grids; do not treat `rho12` as a random-effect or structured-correlation layer |
| Ordinary bivariate covariance and `corpairs()` | Selected labelled intercept blocks and q=2 `corpair(..., level = "group") ~ x` surfaces are fitted | `corpairs()`, summary rows, direct profile targets for supported q=2 rows, and interval-source provenance exist | q=4 rows expose derived interval unavailability; bivariate random slopes remain planned | Admit selected intercept-block and q=2 rows; keep slope-level covariance out |
| Phylogenetic structured effects | Univariate `mu`, bivariate `mu1`/`mu2`, selected q=4 location-scale, direct-SD, and q=2 phylogenetic `corpair()` slices are fitted | Profile, direct-SD, covariance-row, diagnostic, and example evidence exist | Structural-dependence docs keep phylogenetic slopes and structured `rho12` planned | Admit intercept/direct-SD subsets; keep phylogenetic slopes out |
| Coordinate spatial structured effects | Univariate Gaussian `mu` intercepts and one numeric coordinate-spatial slope are fitted | Direct SD targets, `ranef("spatial_mu")`, one-slope smoke evidence, and diagnostics exist | Docs keep mesh/SPDE, multiple slopes, spatial `sigma`, bivariate spatial covariance, and spatial `corpair()` planned | Admit univariate coordinate-spatial `mu` intercept and one-slope grids only |
| Profile intervals and diagnostics | `summary()`, `confint()`, `profile_targets()`, `check_drm()`, `predict_parameters()`, and `corpairs()` expose target-specific status | Slice 278 records interval routes; Slice 289 records extractor and plot interval provenance | Docs state that bootstrap and many derived-summary intervals remain unavailable | Use as supporting infrastructure after the model surface itself is admitted |
| Large-data controls | Memory-light objects, `se = FALSE`, sparse Gaussian fixed-effect `mu`, and Gaussian sufficient-statistic aggregation are opt-in controls | `check_drm()` exposes sparse-design, aggregation, and `sdreport` diagnostics where fitted | Control docs state these are hardening or memory routes, not general scalability claims | Admit only as opt-in stress cells, not as broad performance evidence |
| Reserved, planned, or blocked neighbours | Parser, reference, or roadmap syntax may exist for future features | Boundary tests and error messages are evidence only that unsupported paths stay closed | README, model-map, family registry, and structural docs tell users what to fit instead | Keep in the failure ledger until likelihood, tests, diagnostics, docs, simulation status, and after-task evidence exist |

The signoff result is conditional rather than global. The current evidence can
start Phase 18 on the admitted named surfaces, but it does not yet support a
comprehensive all-feature grid. Every new DGP row should cite the public row
above, the register row in
`docs/design/34-validation-debt-register.md`, and the specific tests or
after-task report that make the row admissible.

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
| Ordinal location | Implemented for fixed-effect univariate `cumulative_logit()` models with ordered cutpoints and fixed latent logistic scale | Tested for likelihood recovery, category probabilities, prediction, expected-score summaries, simulation, fixed-effect Wald intervals, internal cutpoint profile targets, malformed inputs, and unsupported random-effect boundaries | Ordinal random effects, ordinal scale/discrimination formulas, structured ordinal effects, bivariate ordinal, and mixed-response ordinal models remain planned or unsupported | Admit only the fixed-effect ordinal likelihood as a small grid; exclude ordinal mixed-model grids |
| Shape and skewness | Implemented only where fixed-effect shape formulas already exist, such as Student-t `nu`; Slice 286 records skew-normal and skew-t as fixed-effect-first design lanes | Tested for existing fixed-effect shape boundaries, not for shape random effects or skew-family likelihood recovery | `nu` random effects, future `tau`, skew-normal/skew-t likelihoods, and ID-level skewness random effects remain planned or unsupported | Do not admit shape or skewness random-effect grids |
| Inflation and hurdle parameters | Implemented as fixed-effect `zi` or `hu` formula paths for selected count models | Tested as fixed-effect response components and unsupported-boundary cases where applicable | `zi`, `hu`, `zoi`, `coi`, and hurdle random effects, plus cross-parameter covariance with inflation parameters, remain planned or unsupported | Keep inflation-random-effect and hurdle-random-effect surfaces in the failure ledger |
| Bivariate models | Implemented for two-response Gaussian models with separate `mu1` and `mu2` formulas, residual `rho12`, selected labelled random-intercept covariance blocks, and selected phylogenetic location correlations | Tested with bivariate Gaussian, `rho12`, `corpairs()`, profile-target, summary-covariance, and tutorial evidence for the fitted subsets | Mixed-response bivariate models, bivariate random slopes, `rho12` random effects, and broad q=4/q=8 slope covariance remain planned or unsupported | Admit constant or predictor-dependent residual `rho12` and selected intercept-block covariance grids |
| Post-fit extractor provenance | Implemented for interval-aware prediction tables, `summary()`, `confint()`, `corpairs()`, and the exported plotting consumers | Slice 289 verifies that `corpairs()` carries `conf.status` and `interval_source` beside profile-target metadata, while `plot_corpairs()` draws intervals only when those provenance columns mark a real interval source; existing `predict_parameters()` and `plot_parameter_surface()` tests cover the same rule for distributional-parameter surfaces | `vcov()` remains a covariance matrix with row and column-name provenance rather than a status table; `emmeans()` returns an external `emmGrid` for the narrow fixed-effect univariate `mu` path | Use these extractors as simulation and figure inputs only after the fitted surface itself is admitted |
| Random slopes | Implemented for ordinary Gaussian `mu` multi-slope blocks, independent Gaussian `sigma` one-slope terms, ordinary Poisson/NB2 `mu` independent numeric slopes, and coordinate spatial Gaussian `mu` one-slope fields | Tested with focused recovery, smoke, direct profile, weak-boundary, diagnostic checks, and parser-boundary checks for planned structured slopes | Correlated non-Gaussian slopes, bivariate random slopes, phylogenetic slopes, animal slopes, `relmat()` slopes, and spatial slope correlations remain planned or unsupported | Admit only the fitted ordinary, count-`mu`, and coordinate-spatial one-slope cases |
| Meta-analysis | Implemented for Gaussian models with known sampling covariance through `meta_V(V = V)` and the compatibility alias `meta_known_V(V = V)` | Tested for vector and dense `V`, summary-smoke output, Wald rows for estimated targets, and interval safety that keeps known `V` out of confidence-interval targets | Proportional sampling-variance models, multiple variance-component meta-analysis, and phylogenetic-plus-study extensions remain planned | Admit vector and dense known-`V` Gaussian grids, with `V` treated as input data |
| Phylogenetic models | Implemented for Gaussian `mu` intercept effects, selected bivariate `mu1`/`mu2` phylogenetic location correlations, constant q=4 location-scale blocks, and direct `sd_phylo*()` paths | Tested with profile targets, direct-SD surfaces, bivariate phylogenetic covariance rows, diagnostics, examples, and one-slope parser or rejection boundaries | Phylogenetic `mu` slopes, richer q=4 predictor-dependent `corpair()` regressions, and phylogenetic non-Gaussian effects remain planned or unsupported | Admit intercept and documented direct-SD subsets; keep slope grids out |
| Spatial models | Implemented for coordinate spatial Gaussian `mu` intercepts and one numeric slope with independent spatial fields | Tested with a coordinate-spatial one-slope smoke surface, direct SD targets, `ranef("spatial_mu")`, diagnostics, and reader-facing boundary text | Mesh/SPDE models, multiple spatial slopes, spatial slope correlations, spatial `sigma`, bivariate spatial q=4, spatial direct-SD, and spatial `corpair()` regressions remain planned | Admit only univariate Gaussian coordinate-spatial `mu` intercept and one-slope grids |
| `animal()` models | Exported and parsed as planned structured-effect markers, including intercept and one-slope grammar, but no fitted likelihood exists | Tested as reference/parser and unsupported-boundary surface, not as a fitted model | Pedigree, `A`, and `Ainv` animal-model likelihoods, diagnostics, profile targets, and recovery tests remain planned | Do not admit fitted animal-model grids |
| `relmat()` models | Exported and parsed as lower-level planned known-relatedness markers, including intercept and one-slope grammar, but no fitted likelihood exists | Tested as reference/parser and unsupported-boundary surface, not as a fitted model | User-supplied `K` or `Q` fitting, matrix validation, diagnostics, profile targets, and recovery tests remain planned | Do not admit fitted `relmat()` grids |

## Current Readiness Matrix

| Surface | Fitted status | Evidence now available | Phase 18 status |
| --- | --- | --- | --- |
| Gaussian fixed-effect location-scale | Fitted | DGP, smoke runner, Wald intervals for fixed formula coefficients, `sigma` summaries, manifests, and failure ledgers | Ready for first small grids |
| Gaussian ordinary `mu` random intercepts and q > 2 random slopes | Fitted | Focused recovery tests, q=3 smoke surface, q=4 output-name check, `sdpars$mu`, random effects, direct profile targets, and diagnostics | Ready for focused grids, with larger q treated as advanced |
| Gaussian `sigma` random slopes | Fitted for multiple independent one-slope terms, including separate grouping factors | Smoke surface for `(0 + w | id)` on `log(sigma)`, cross-group output-contract checks, summaries, manifests, and failure ledgers | Ready only for independent one-slope grids |
| Gaussian location-scale covariance | Fitted for supported intercept blocks | `corpairs()`, `summary()` covariance rows, profile targets for direct rows, and diagnostics | Ready for small intercept-block grids, not slope-level covariance |
| Bivariate Gaussian `rho12` | Fitted | Constant and predictor-dependent residual coscale, `rho12()`, row-specific profile support, and tutorial examples | Ready for focused residual-correlation grids |
| Bivariate Gaussian random-effect intercept blocks | Fitted for selected labelled intercept blocks | `sdpars`, `corpars`, `corpairs()`, `summary()` covariance rows, direct profile targets, and diagnostics | Ready for selected intercept-block grids |
| Bivariate Gaussian random slopes | Planned | Explicit error boundaries for matching slope-only `mu1`/`mu2`, intercept-plus-slope q=4 location, residual-scale slope, same-response location-scale slope, and all-four q=8-style slope requests | Not ready |
| Mixed-response bivariate families | Planned; Slice 288 keeps Gaussian-count, Gaussian-proportion, count-proportion, ordinal mixed, and other two-response combinations out of the fitted surface | Clear errors for mixed composed families in both `c()` and `list()` spellings, plus the all-Gaussian composed-family positive path | Not ready until a joint likelihood or copula/latent-variable contract, prediction, simulation, extractors, intervals, examples, and comparator or independent-likelihood tests exist |
| Meta-analysis with known `V` | Fitted through `meta_V(V = V)` | Vector and dense `V` DGPs, smoke runner, Wald intervals for estimated targets, and safeguards that known `V` is not an interval target | Ready for first small grids |
| Coordinate spatial Gaussian `mu` | Fitted for intercept and one numeric slope | Spatial one-slope smoke surface, direct SD targets, and diagnostics | Ready for focused univariate Gaussian `mu` grids |
| Phylogenetic Gaussian `mu` | Fitted for intercept and selected bivariate intercept structures | Profile targets, direct-SD surfaces, bivariate phylogenetic covariance rows, and examples | Ready for intercept grids; one-slope parity remains planned |
| `animal()` and `relmat()` | Parser/planned only for intercept and one-slope markers; no fitted likelihood | ASReml efficiency note, structured-slope parity gate, parser checks, and unsupported-boundary tests | Not ready |
| Poisson `mu` random effects | Fitted for ordinary non-zero-inflated intercepts and independent numeric slopes | Smoke runner, fixed-effect Wald intervals, direct SD profile intervals, weak-SD boundary test, and diagnostics | Ready for first small non-Gaussian `mu` grids |
| NB2 `mu` random effects | Fitted for ordinary non-zero-inflated intercepts and independent numeric slopes | Smoke runner, fixed-effect Wald intervals, direct SD profile intervals, weak-SD boundary test, and diagnostics | Ready for first small non-Gaussian `mu` grids |
| Zero-truncated NB2 `mu` random effects | Planned | Fixed-effect likelihood exists; random effects are blocked | Not ready |
| Non-Gaussian `sigma` random effects | Blocked | Fixed-effect `sigma` formulas exist for supported families; random-effect bars error clearly | Not ready |
| Shape or skewness random effects | Planned | Shape formulas exist only where already fitted as fixed effects; Student-t `nu` random-intercept and random-slope requests are blocked with a shape-specific test gate; skewness remains design/research | Not ready |
| Zero-inflation, hurdle, zero-one inflation, and one-inflation random effects | Planned or blocked | Fixed-effect `zi` and `hu` exist for selected count families; random-intercept and random-slope requests in `zi`, `hu`, future `zoi`, and future `coi` are blocked | Not ready |
| Ordinal random effects | Blocked | Cumulative-logit fixed-effect path exists; random effects error clearly | Not ready |
| Structured non-Gaussian dependence | Blocked | Ordinary count `mu` random effects now have first evidence; structured count effects remain blocked | Not ready |
| Cross-parameter non-Gaussian covariance | Blocked | Cross-distributional-parameter correlation gate records the boundary | Not ready |
| Post-fit extractor and plotting inputs | Supporting infrastructure | `prediction_grid()`, `predict_parameters()`, `marginal_parameters()`, `corpairs()`, `summary()`, `confint()`, `profile_targets()`, `vcov()`, the narrow fixed-effect univariate `mu` `emmeans()` bridge, `plot_parameter_surface()`, and `plot_corpairs()` have explicit status, provenance, or naming contracts; Slice 289 adds default `corpairs()` interval provenance and plot-side source checks | Ready as supporting infrastructure, but not evidence that any blocked model surface is simulation-ready |

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
