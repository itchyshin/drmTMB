# Animal-models audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/animal-models.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The wide fitted-status table compressed its code and status columns into unreadable fragments on a narrow viewport. | Repaired with page-scoped heading rules plus a 720 px scrollable table surface, preserving columns rather than collapsing their contents. |
| Claim/figure audit | The tutorial distinguishes pedigree, covariance (`A`), and precision (`Ainv`) input representations; limits campaign coverage to the exact A-matrix REML domain; keeps q=2 and q=4 animal correlations point-only; and separates those correlations from residual `rho12`. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("animal-models", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/animal-models-desktop-1440x1000.png` and
  `renders/animal-models-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable prose/title and a
  horizontally scrollable status table rather than collapsed code fragments.
- Original-resolution inspection of the q=2 correlation display confirmed its
  explicit point-only subtitle and zero reference line, with no misleading
  interval eye. The relatedness heatmap and SD display are explicitly labelled
  as known-input structure and point estimates respectively.
- `git diff --check` passed.

## What this repair does not establish

It does not promote pedigree/Ainv multi-seed coverage, q=2 or q=4 animal
correlation intervals, additional structured-slope layouts, animal
`corpair()` regressions, sparse-pedigree construction, or non-Gaussian animal
routes beyond their exact ledger cells.
