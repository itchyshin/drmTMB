# Rendered Article Checklist

Date: 2026-05-22

## Purpose

This checklist starts the article audit sweep from rendered pkgdown pages rather
than source files alone. It records whether each article is present in the
rendered site, how it is grouped after the first navigation slice, whether
figures appear in the rendered HTML, and what the next audit action should be.

The inventory uses the current `_pkgdown.yml` article order and the rendered
`pkgdown-site/articles/*.html` files. Figure counts are rendered `<img>` tags in
the article body, not every stale PNG that may remain in an article figure
directory from an earlier build.

## Gates Used

- Pat: can an applied reader tell why the page exists and what to read next?
- Darwin: is the biological or scientific question visible before mechanics?
- Fisher: are interval, profile, bootstrap, and validation claims explicit
  about their evidence tier?
- Florence: are rendered figures present, labelled, and queued for direct
  visual inspection where needed?
- Grace: does the rendered HTML exist after `pkgdown::build_site()`?
- Rose: does the page risk stale fitted-versus-planned wording?

## Rendered Inventory

| Group | Article | Rendered title | Figures in HTML | First verdict | Next audit action |
| --- | --- | --- | ---: | --- | --- |
| Getting Started | `drmTMB` | Distributional regression with drmTMB | 0 | Start-page prose needed a calmer first-user entrance; edited in this slice. | Rebuild and verify first screen plus links to `model-map` and `distribution-families`. |
| Start Here | `model-map` | What can I fit today? | 0 | Correct authority page for fitted-versus-planned status; dense but purposeful. | Keep as capability authority; run stale scans for CI/bootstrap, q4, Poisson phylo q=1, `meta_V()`, and `gr()`. |
| Start Here | `model-workflow` | Checking and using fitted models | 5 | Correct post-fit hub; figure alt text is present for rendered figures. | Inspect rendered figures directly and check CI/profile/bootstrap wording against current code. |
| Choose Your Model | `which-scale` | Which scale are you modelling? | 2 | High-value vocabulary page; rendered figures now separate residual `sigma` from random-effect `sd(population)`. | Keep `sigma`, `sd(group)`, weights, and direct-SD language synchronized with current interval support. |
| Choose Your Model | `distribution-families` | Choosing response families | 0 | Family-status hub; status can drift quickly. | Compare family table to family registry, NEWS, and tests. |
| Choose Your Model | `location-scale` | When variance carries signal | 2 | Core applied tutorial; rendered figures now show raw-plus-fitted `mu` and a fitted residual-`sigma` contrast. | Keep equation/syntax/interpretation and figure captions aligned as this remains the main worked example. |
| Choose Your Model | `bivariate-coscale` | Changing residual coupling with rho12 | 2 | Important residual-correlation tutorial; alt text and clipped group-correlation plot fixed in the first figure triage. | Recheck `rho12` versus group-level correlation language during the full bivariate tutorial audit. |
| Choose Your Model | `meta-analysis` | Mean effects and residual heterogeneity in meta-analysis | 1 | Now has a variance-component figure separating known sampling variance from fitted extra heterogeneity. | Keep `meta_V(V = V)`, `meta_known_V(V = V)`, and dense-matrix scaling wording synchronized. |
| Applied Family Tutorials | `robust-student` | Robust continuous responses | 1 | Now has a raw-tail plus fitted-point figure comparing Gaussian and Student-t expected growth. | Keep `nu` shape wording and interval-free visual claims aligned. |
| Applied Family Tutorials | `count-nbinom2` | Count abundance and extra zeros | 1 | Now has a response-scale component figure for conditional mean, unconditional mean, NB2 `sigma`, and zero-inflation. | Scan for stale non-Gaussian structured-boundary claims. |
| Applied Family Tutorials | `proportion-beta-binomial` | Proportions and success rates | 1 | Now has a raw tray-proportion plus fitted extra-binomial scatter figure. | Keep beta versus beta-binomial boundary and zero/one support wording clear. |
| Structured Dependence | `structural-dependence` | Structural dependence overview | 0 | Correct route chooser after navigation split. | Make sure it sends readers to animal, phylo, spatial, and relmat leaf pages. |
| Structured Dependence | `animal-models` | Animal models and additive relatedness | 3 | Structured route page now has a relatedness heatmap, SD interval figure, and q=2 Confidence Eye. | Check animal q2/q4 fitted boundaries and interval rows as support changes. |
| Structured Dependence | `phylogenetic-models` | Phylogenetic structured effects | 2 | Structured route page now has a phylogenetic SD interval figure and q=2 Confidence Eye. | Check ordinary Poisson q=1, Gaussian q2/q4, and profile target wording. |
| Structured Dependence | `spatial-models` | Coordinate-spatial structured effects | 3 | Structured route page now has a fitted spatial field, SD interval display, and q=2 Confidence Eye. | Check q4 derived-only interval language and avoid overclaiming coverage evidence. |
| Structured Dependence | `relmat-known-matrices` | Known-matrix relatedness with relmat | 3 | Now has a supplied-matrix heatmap, SD interval figure, and q=2 Confidence Eye. | Monitor use-case clarity and matrix-layer split from meta-analysis. |
| Structured Dependence | `phylogenetic-spatial` | Structural dependence details | 2 | Long advanced page now has q=2 animal and `relmat()` Confidence Eyes. | Decide later whether to split or keep as technical detail page. |
| Inference, Diagnostics, and Figures | `convergence` | Improving convergence | 2 | Diagnostic page now has `check_drm()` status-map and gradient/budget figures; these are diagnostic statuses, not interval displays. | Keep status labels synchronized with `check_drm()` and avoid treating skipped uncertainty as failed optimization. |
| Inference, Diagnostics, and Figures | `large-data` | Working with large data | 1 | Control/scaling page now has an endpoint-profile timing figure; caption names it as local performance evidence, not uncertainty. | Keep benchmark rows synchronized with `docs/dev-log/benchmarks/profile-scalar-endpoint-v2.csv` and avoid general speed claims beyond successful direct scalar targets. |
| Inference, Diagnostics, and Figures | `figure-gallery` | Figure gallery | 21 | Main figure-quality surface; rendered figures need one-by-one Florence/Fisher audit. | Run direct figure inspection and record per-figure data grain, interval source, and fix. |
| Simulation and Validation | `implementation-map` | Implementation map | 0 | Evidence/status authority; overlaps model map by design. | Keep fitted status synchronized with validation-debt register. |
| Simulation and Validation | `testing-likelihoods` | Testing likelihoods | 0 | Contributor/reviewer page in public validation group. | Decide whether opening should explicitly say reviewer evidence rather than beginner tutorial. |
| Simulation and Validation | `simulation-plot-grammar` | Simulation plot grammar | 6 | Figure-heavy validation page; direct audit split shared accuracy alt text and separated mixed-unit readiness panels. | Keep as the current simulation display contract; rerun after Phase 18 result schemas stabilize. |
| Developer Notes | `formula-grammar` | Formula grammar | 0 | Parser contract page. | Check grammar against current parser and deprecated `gr()` direction. |
| Developer Notes | `adding-families` | Adding distribution families | 0 | Contributor path. | Check family-add instructions against source map and simulation-test rule. |
| Developer Notes | `source-map` | Implemented source map | 0 | Developer ownership map. | Keep synchronized with C++ modularization and structured-count boundary. |

## First Sweep Decisions

The first edit pass stays on the `Start Here` triad:

1. `drmTMB` should answer "how do I fit one model and where do I go next?"
   before listing many implemented surfaces.
2. `model-map` remains the fitted-versus-planned authority and now tells new
   readers to start with `drmTMB` if they have not fitted a model yet.
3. `model-workflow` remains the post-fit hub and now states its place in the
   `Start Here` path.

The figure audit should not be folded into this prose pass. The next
figure-heavy slice should inspect rendered images directly for `model-workflow`,
`figure-gallery`, `simulation-plot-grammar`, and `bivariate-coscale`, then
record per-figure data grain, interval source, label/alt-text status, and
whether the figure is publication-ready or only a temporary teaching scaffold.
