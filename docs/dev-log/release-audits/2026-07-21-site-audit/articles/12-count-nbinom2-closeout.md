# Count-NB2 audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/count-nbinom2.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The count-component table needed a narrow-screen reading container. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim/figure audit | The article keeps fixed-effect ZI examples distinct from recovery-only ordinary/structured count routes and explicitly withholds interval/coverage promotion from structured sigma and diagnostic routes. The four-panel model-parts figure separates estimands and draws no intervals. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("count-nbinom2", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/count-nbinom2-desktop-1440x1000.png` and
  `renders/count-nbinom2-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  layout.
- Detailed original-resolution figure inspection confirmed distinct facets for
  conditional mean, unconditional mean, NB2 `sigma`, and structural-zero
  probability, with no interval bars.
- `git diff --check` passed.

## What this repair does not establish

It does not promote count random or structured effects, validate intervals or
coverage for them, add count `meta_V()`, or change NB2/ZI likelihoods.
