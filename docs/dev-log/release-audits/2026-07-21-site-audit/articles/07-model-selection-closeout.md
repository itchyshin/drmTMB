# Model-selection audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/model-selection.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The criterion tables can exceed 390 px, and the title hyphenated “selection” inside a word on mobile. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim audit | The article properly limits AIC/BIC comparison to a fixed candidate set and same analysis rows, requires ML for different Gaussian fixed-effect structures, and confines the REML example to the stated Gaussian intercept-only-`sigma` slice. | No claim edit required. |

## Render and focused checks

- `pkgdown::build_article("model-selection", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/model-selection-desktop-1440x1000.png`
  and `renders/model-selection-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed the heading wraps as “Model /
  selection with / AIC and BIC” and the formula block remains legible.
- `git diff --check` passed.

## What this repair does not establish

It does not validate any selected model scientifically, expand REML support,
endorse automatic model selection, or change model likelihoods or the AIC/BIC
calculation.
