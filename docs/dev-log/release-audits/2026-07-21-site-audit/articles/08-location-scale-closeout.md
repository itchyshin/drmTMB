# Location-scale audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/location-scale.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | Mobile tables could overflow and the long title hyphenated “location.” | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim/figure audit | The article correctly separates residual `sigma`, mean-side random-effect SD, and scale-side random effects. Its residual-SD contrast uses explicitly requested 95% Wald intervals and does not place raw responses on a scale axis. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("location-scale", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/location-scale-desktop-1440x1000.png`
  and `renders/location-scale-mobile-390x844.png`.
- The 390 x 844 viewport now wraps the title between words and keeps body prose
  within the reader surface.
- Both generated figures were inventoried at original resolution. Detailed
  inspection of the residual-SD contrast confirmed that point estimates and
  95% Wald intervals are named directly and visual encodings are clear.
- `git diff --check` passed.

## What this repair does not establish

It does not certify Wald coverage beyond the example’s fixed-effect setting,
create inference for random-effect-SD surfaces, add `sd()` slope grammar, or
alter a likelihood or formula contract.
