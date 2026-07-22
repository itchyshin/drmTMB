# Structural-dependence details audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/phylogenetic-spatial.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | This long, table-heavy reader page lacked a consistent narrow-screen surface for its route maps. | Repaired with page-scoped heading rules and 720 px horizontally scrollable tables. |
| Claim/figure audit | The article repeatedly labels combined `phylo()` plus `spatial()` layers planned/rejected pending joint identifiability checks; retains the separation of latent `corpairs()` correlations from residual `rho12`; and labels diagnostic versus validated interval routes without promoting callable profiles. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("phylogenetic-spatial", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/phylogenetic-spatial-desktop-1440x1000.png`
  and `renders/phylogenetic-spatial-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  long links, code, and route tables.
- The two generated q=2 correlation displays are explicitly point-only; their
  captions withhold interval calibration. No figure turns a diagnostic profile
  or derived q=4 target into a reporting interval.
- `git diff --check` passed.

## What this repair does not establish

It does not admit combined phylogenetic-plus-spatial layers, mesh/SPDE inputs,
structured residual-`rho12` terms, predictor-dependent spatial correlations,
or broad q=2/q=4 interval and coverage claims.
