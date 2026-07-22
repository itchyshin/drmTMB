# Structural-dependence overview audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/structural-dependence.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The route matrix needs a narrow-screen reading container. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim audit | The overview distinguishes latent structured correlations (`corpairs()`) from residual `rho12()` correlation, identifies exact fitted rows versus planned neighbours, and withholds spatial sigma-slope interval support. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("structural-dependence", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/structural-dependence-desktop-1440x1000.png`
  and `renders/structural-dependence-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and a contained,
  horizontally readable route table.
- The article contains no generated scientific figures; the route matrix is its
  primary visual aid.
- `git diff --check` passed.

## What this repair does not establish

It does not promote additional structural-effect layouts, spatial sigma-slope
intervals, non-Gaussian routes outside the named ledger cells, combined
phylogenetic-plus-spatial models, or structured residual-`rho12` routes.
