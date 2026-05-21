# Forgotten Promises Status: 2026-05-20

Purpose: Rose's status table for promises that kept resurfacing during the
figure, Ayumi, confidence-interval, shape-model, structural-dependence, and
simulation discussions. This table is a planning and audit artifact; it should
not be read as a claim that planned items are fitted.

Merged integration target: PR #263. Current follow-up branch:
`codex/slices-1239-1278-actions-figures-audit`.

## Status Table

| Topic | Current status | Evidence checked | Remaining action |
| --- | --- | --- | --- |
| Figure quality and uncertainty displays | Partial, improved | Figure rescue report, `figure-visual-audit` skill, `docs/design/39-visualization-grammar.md`, figure gallery and simulation grammar edits | Keep rendered-image inspection as a hard gate for every changed figure; do not merge future figure work from source inspection alone. |
| Simulation coverage/power plots | Partial, improved | Simulation grammar now shows replicate-block proportions plus aggregate binomial MCSE intervals rather than required raindrops | Formal Phase 18 reports still need stored replicate rows or stored block summaries, not fixture-only examples. |
| Inference compatibility plots | Partial, improved | Figure gallery uses raindrop-style displays for coefficient and correlation compatibility, with interval provenance | Exported helper waits for a stable table contract across Wald, profile, bootstrap, and likelihood-derived compatibility objects. |
| Formula-only reference discoverability | Mostly current | `_pkgdown.yml` lists `random_effect_scale_formulas`, `animal`, `phylo`, `spatial`, `relmat`, `corpair`, `rho12`, `profile_targets`, `check_drm`, `confint.drmTMB`, and plotting helpers; matching `.Rd` files exist | A rendered reference-index pass from a new-user perspective is still useful after the next full site build. |
| Same-response bivariate `mu`/`sigma` covariance | Closed locally | New bivariate test covers `mu1`/`sigma1` label `p`, `mu2`/`sigma2` label `q`, and residual `rho12`; docs now say one or more response-specific blocks | Keep as intercept-only ordinary grouped support; bivariate random slopes and q=6/q=8 remain planned. |
| Residual `rho12` versus latent correlations | Current, but needs constant vigilance | README, formula grammar, known limitations, and figure gallery separate residual, ordinary group, and phylogenetic layers | Continue checking new examples so residual `rho12` is not described as group, spatial, animal, or phylogenetic covariance. |
| Profile intervals | Partial | `profile_targets()` and `confint()` support direct targets; docs use `derived_interval_unavailable` for q4 derived rows | Broaden hard-fit profile diagnostics, especially direct fallback targets that can still fail in boundary or one-sided profiles. |
| Public bootstrap intervals | Planned, not public | Public `method = "bootstrap"` still errors; private Phase 18 parametric-bootstrap helpers exist with worker provenance and 10-core caps | Design and test public bootstrap API only after refit target extraction, failure ledger, and parallel rebuild contract are stable. |
| Ayumi convergence and Hessian triage | Partial, evidence exists | ROADMAP and optimizer-start design notes record q2 locphylo successes, q4/fallback false convergence, boundary correlations, and 10-core bootstrap trials | Re-run the key Ayumi fits after this covariance and diagnostic work, keeping point estimates, Wald SEs, profiles, and bootstrap uncertainty separate. |
| Starting values and multistart | Prototype evidence only | `docs/design/35-optimizer-start-map-multistart.md` records source-start and jitter trials for Ayumi-style fits | Keep as developer-only until a source-fit contract and safety checks exist; do not expose warm-start control yet. |
| Student-t shape models | Implemented fixed-effect first slice | `student()` supports fixed-effect `nu`; Phase 18 has Student-t shape smoke/profile/bootstrap lanes | Expand formal coverage grids and examples before claiming broad shape-model robustness. |
| Skew-normal and skew-t shape models | Planned | Family registry, likelihood notes, and roadmap keep skew-normal/skew-t fixed-effect-first and design-only | Choose one density/parameterization, add likelihood comparators and recovery tests, then examples; no random effects or latent `skew(id)` until fixed-effect evidence passes. |
| Animal models | First fitted known-matrix slice | `animal(1 | id, A = A)` and `animal(1 | id, Ainv = Ainv)` now fit a univariate Gaussian `mu` intercept with diagnostics, profile targets, and recovery tests; pedigree construction, slopes, `sigma`, bivariate covariance, and `corpair()` parity remain planned | Add a small runnable example and keep the next parity steps scoped: pedigree-to-Ainv, slopes, then bivariate covariance only after recovery evidence. |
| `relmat()` models | First fitted known-matrix slice | `relmat(1 | id, K = K)` and `relmat(1 | id, Q = Q)` now fit the same univariate Gaussian `mu` intercept route for lower-level user-supplied relatedness or precision matrices | Keep `relmat()` distinct from `meta_V(V = V)`; add examples and diagnostics before expanding to slopes, `sigma`, bivariate covariance, or `corpair()` parity. |
| Phylogenetic models | Partial, fitted slices | Univariate `mu`, bivariate `mu1`/`mu2`, q4 labelled location-scale, direct `sd_phylo*()`, and q2 phylogenetic `corpair()` are documented | Phylogenetic slopes, standalone or partial phylogenetic scale terms, predictor-dependent q4 correlations, and broad profile diagnostics remain planned. |
| Spatial models | Partial, fitted coordinate `mu` path now includes q=2 bivariate location covariance | README and docs show `spatial(1 | site, coords = coords)`, one numeric `spatial(1 + x | site, coords = coords)` slope, and matching bivariate `mu1`/`mu2` `spatial(1 | p | site, coords = coords)` terms with `corpairs(level = "spatial")`; structural-dependence docs treat spatial as the phylo sibling, not an afterthought | Mesh/SPDE, multiple slopes, slope correlations, spatial `sigma`, spatial q=4 location-scale, spatial direct-SD, and spatial `corpair()` regression remain planned behind the q=2 gate. |
| Structural-dependence article split | Planned docs architecture | `docs/design/53-structural-dependence-article-split.md` records the future route order: animal, phylo, spatial, phylo+spatial, then `relmat()` | Split the current umbrella article into focused pkgdown pages after the next reference and learning-path audit. |
| Phase 18 simulations | Partial, active infrastructure | First-wave and interval-heavy smoke runners, grid writers, reports, manifests, and failure ledgers exist | Move from smoke and nrep2/nrep3 evidence to larger planned grids only for admitted surfaces; keep planned lanes in failure ledgers. |
| Long-run simulation Actions | Implemented as manual dispatch | `.github/workflows/phase18-simulation-grid.yaml` and `inst/sim/run/sim_run_actions_cell.R` provide first-wave and interval-heavy task dispatch, artifact upload, retention days, and 10-core caps | Run manually after the branch PR is green; use artifacts for Phase 18 report evidence rather than committing bulky local outputs. |
| Example coverage for animal, Student-t, skew-normal | Partial | Student-t examples exist; the first `animal()` known-matrix slice is fitted but still needs a runnable example; skew-normal remains design-only | Add a small animal example for precomputed `A`/`Ainv`; keep skew examples design-only until likelihood recovery passes. |

## Reference Discoverability Evidence

The following source reference topics are listed in `_pkgdown.yml` and have
generated `.Rd` files:

```text
random_effect_scale_formulas
animal
phylo
spatial
relmat
corpair
meta_V
rho12
check_drm
profile_targets
confint.drmTMB
plot_corpairs
plot_parameter_surface
```

`pkgdown::check_pkgdown()` found no problems after the covariance and figure
documentation edits. The remaining reference task is qualitative: inspect the
rendered reference index as a new user and confirm the navigation answers
"where do I learn this syntax?" without needing the roadmap.

## Immediate Next Queue

1. Keep the structural parity target explicit: animal, spatial, and `relmat()`
   should eventually support the same q=2, q=4, `corpairs()`, direct-SD, and
   `corpair()` classes as phylo where scientifically sensible.
2. Split the structural-dependence article into animal, phylo, spatial,
   phylo+spatial, and `relmat()` pages instead of letting one umbrella article
   absorb every planned route.
3. Run a rendered reference-index audit after the next full site build.
4. Re-run the Ayumi convergence stress set with the current diagnostics and
   same-response two-block support.
5. Design the public bootstrap API only after the private refit harness has a
   clear target and failure-ledger contract.
6. Keep skew-normal/skew-t and animal/relmat examples planned-only until their
   likelihood and recovery evidence exists.
7. Use the new manual Phase 18 Actions workflow for larger first-wave or
   interval-heavy grids once the PR branch has passed ordinary R-CMD-check.
