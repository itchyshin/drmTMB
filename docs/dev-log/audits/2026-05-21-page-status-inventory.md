# Page Status Inventory Audit

## Scope

This is the first page-level audit after the fast CI slice and comprehensive
audit launch. It checks the current pkgdown article inventory, identifies
pages likely to carry stale interval or figure claims, and sets the order for
rendered review.

## Pkgdown Article Inventory

| Section | Pages | Audit priority |
| --- | --- | --- |
| Getting Started | `drmTMB` | Medium: landing tutorial should stay user-first and not become a status dump. |
| Model Guides | `model-map`, `implementation-map`, `which-scale`, `distribution-families`, `model-workflow`, `convergence`, `large-data` | High: these pages carry implemented/planned status, interval advice, and user decision flow. |
| Tutorials | `location-scale`, `robust-student`, `count-nbinom2`, `figure-gallery`, `proportion-beta-binomial`, `meta-analysis`, `bivariate-coscale`, `structural-dependence`, `animal-models`, `phylogenetic-models`, `spatial-models`, `relmat-known-matrices`, `phylogenetic-spatial` | High: these pages blend syntax, figures, examples, and status boundaries. |
| Simulation & Comparison | `testing-likelihoods`, `simulation-plot-grammar` | High for evidence claims and figure grammar; medium for beginner flow. |
| Developer Notes | `formula-grammar`, `adding-families`, `source-map` | Medium: mostly contributor-facing, but stale implementation claims can mislead future agents. |

## High-Risk Pages

| Page | Why it is high risk | First action |
| --- | --- | --- |
| `model-workflow` | It changed in the fast-CI slice and now teaches Wald/profile/bootstrap order. | Rendered successfully with local package loaded; include in stale scan after full site build. |
| `figure-gallery` | It has many figures, interval captions, and manually assembled visual examples. | Render and inspect figures one by one with Florence, Fisher, Pat, Rose, and Grace perspectives. |
| `model-map` | It is the public capability table and generated `pkgdown-site` can lag behind source. | Rebuild site before deploy; scan rendered table for old bootstrap wording. |
| `implementation-map` | It carries evidence tiers and can easily overstate fitted support. | Compare against validation-debt register and pre-simulation matrix. |
| `phylogenetic-spatial` | It combines structured syntax, profile targets, and derived interval boundaries. | Check q2/q4/status wording against current `profile_targets()` and `corpairs()` outputs. |
| `simulation-plot-grammar` | It defines visual conventions for coverage, MCSE, and simulation figures. | Check that all figures name replicate grain and uncertainty source. |

## Immediate Findings

1. The page set is broad enough that source-only inspection is not enough.
   Rendered review is required before any claim that figures or public pages
   are coherent.
2. The source `model-workflow` article now shows the fast CI route, and its
   rendered article was checked during the previous slice with the local
   package loaded.
3. The `figure-gallery` source had one interval-wording inconsistency around
   `sd(site) ~ reef_cover` surfaces. That wording is now corrected to
   "modelled random-effect SD surfaces"; the rendered plot still needs visual
   inspection.
4. The current audit should not focus too much on stacked-vector/storage
   language. Where stacking appears, it should be a mechanics note, not the
   headline for applied readers.

## Render Order For Step 3

1. `figure-gallery`
2. `model-workflow`
3. `model-map`
4. `implementation-map`
5. `simulation-plot-grammar`
6. `phylogenetic-spatial`

Each rendered page should be scanned for text overlap, stale status language,
unsupported-looking syntax, weak figure captions, poor uncertainty display,
and figures that are technically present but visually unhelpful.
