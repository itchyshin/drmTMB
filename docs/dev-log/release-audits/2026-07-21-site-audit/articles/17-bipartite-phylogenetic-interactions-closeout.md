# Two-tree phylogenetic-interactions audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/bipartite-phylogenetic-interactions.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The fitted-route table needed the standard narrow-screen reading container. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim audit | The page accurately limits `phylo_interaction()` to univariate q=1 `mu` for Gaussian, ordinary Poisson, and ordinary NB2; it keeps main-effect-plus-interaction, binary incidence, structured slopes, and simultaneous structural layers explicitly planned. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("bipartite-phylogenetic-interactions", pkg = ".",
  lazy = FALSE, new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures:
  `renders/bipartite-phylogenetic-interactions-desktop-1440x1000.png` and
  `renders/bipartite-phylogenetic-interactions-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose, contained
  long source links, and horizontally contained mathematical/code displays.
- The article contains no generated scientific figure; its Kronecker covariance
  display and route matrix are its reader-facing visual aids.
- `git diff --check` passed.

## What this repair does not establish

It does not promote interval or coverage support for the pair SD, binary pair
models, partner main-effect plus interaction models, structured pair slopes,
or simultaneous spatial/animal interaction layers.
