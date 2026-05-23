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
| Choose Your Model | `which-scale` | Which scale are you modelling? | 0 | High-value vocabulary page; no figure burden. | Check `sigma`, `sd(group)`, weights, and direct-SD language. |
| Choose Your Model | `distribution-families` | Choosing response families | 0 | Family-status hub; status can drift quickly. | Compare family table to family registry, NEWS, and tests. |
| Choose Your Model | `location-scale` | When variance carries signal | 0 | Core applied tutorial; needs equation/syntax/interpretation pass. | Audit first after Start Here because it is the main worked example. |
| Choose Your Model | `bivariate-coscale` | Changing residual coupling with rho12 | 2 | Important residual-correlation tutorial; alt text and clipped group-correlation plot fixed in the first figure triage. | Recheck `rho12` versus group-level correlation language during the full bivariate tutorial audit. |
| Choose Your Model | `meta-analysis` | Mean effects and residual heterogeneity in meta-analysis | 0 | Needs clear split from latent `relmat()` structure. | Audit `meta_V(V = V)` and `meta_known_V(V = V)` wording. |
| Applied Family Tutorials | `robust-student` | Robust continuous responses | 0 | Focused family tutorial. | Check `nu` shape wording and interval claims. |
| Applied Family Tutorials | `count-nbinom2` | Count abundance and extra zeros | 0 | Count support changed recently through random effects and Poisson phylo q=1. | Scan for stale non-Gaussian structured-boundary claims. |
| Applied Family Tutorials | `proportion-beta-binomial` | Proportions and success rates | 0 | Focused family tutorial. | Check beta versus beta-binomial boundary and zero/one support wording. |
| Structured Dependence | `structural-dependence` | Structural dependence overview | 0 | Correct route chooser after navigation split. | Make sure it sends readers to animal, phylo, spatial, and relmat leaf pages. |
| Structured Dependence | `animal-models` | Animal models and additive relatedness | 0 | Structured route page; q2/q4 status can drift. | Check animal q2/q4 fitted boundaries and interval rows. |
| Structured Dependence | `phylogenetic-models` | Phylogenetic structured effects | 0 | Structured route page; Poisson q=1 and Gaussian routes must stay distinct. | Check ordinary Poisson q=1, Gaussian q2/q4, and profile target wording. |
| Structured Dependence | `spatial-models` | Coordinate-spatial structured effects | 0 | Structured route page; q2/q4 fitted status recently changed. | Check q4 derived-only interval language and avoid overclaiming coverage evidence. |
| Structured Dependence | `relmat-known-matrices` | Known-matrix relatedness with relmat | 0 | Recently clarified; good candidate for follow-up examples later. | Monitor use-case clarity and matrix-layer split from meta-analysis. |
| Structured Dependence | `phylogenetic-spatial` | Structural dependence details | 0 | Retitled in the navigation slice; long advanced page. | Decide later whether to split or keep as technical detail page. |
| Inference, Diagnostics, and Figures | `convergence` | Improving convergence | 2 | Diagnostic page now has `check_drm()` status-map and gradient/budget figures; these are diagnostic statuses, not interval displays. | Keep status labels synchronized with `check_drm()` and avoid treating skipped uncertainty as failed optimization. |
| Inference, Diagnostics, and Figures | `large-data` | Working with large data | 0 | Control/scaling page; easy to overclaim. | Check `se = FALSE`, sparse design, and aggregation boundaries. |
| Inference, Diagnostics, and Figures | `figure-gallery` | Figure gallery | 21 | Main figure-quality surface; rendered figures need one-by-one Florence/Fisher audit. | Run direct figure inspection and record per-figure data grain, interval source, and fix. |
| Simulation and Validation | `implementation-map` | Implementation map | 0 | Evidence/status authority; overlaps model map by design. | Keep fitted status synchronized with validation-debt register. |
| Simulation and Validation | `testing-likelihoods` | Testing likelihoods | 0 | Contributor/reviewer page in public validation group. | Decide whether opening should explicitly say reviewer evidence rather than beginner tutorial. |
| Simulation and Validation | `simulation-plot-grammar` | Simulation plot grammar | 5 | Figure-heavy validation page; one source alt-text hit appears missing. | Florence/Fisher audit of replicate grain, MCSE, missing cells, and alt text. |
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
