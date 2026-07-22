# Phylogenetic-models audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/phylogenetic-models.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | General tables outside the existing capability-table wrapper lacked the standard narrow-screen containment rule. | Repaired with page-scoped table containment and word-boundary heading wrapping. |
| Claim/figure audit | The article correctly distinguishes its response-scale log-SD Wald Confidence Eyes from a posterior density, limits each phylogenetic route to its named capability tier, and withholds blanket interval/coverage claims. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("phylogenetic-models", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/phylogenetic-models-desktop-1440x1000.png`
  and `renders/phylogenetic-models-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  page tables.
- Original-resolution inspection of `gaussian-figure-1.png` (1497 x 633)
  confirmed two labelled response-scale SD Confidence Eyes with visible hollow
  raw estimates; it does not imply a posterior distribution or a zero-SD test.
- `git diff --check` passed.

## What this repair does not establish

It does not promote phylogenetic routes beyond their exact ledger cells,
validate generic SD intervals or coverage, enable public `A` matrix input,
admit simultaneous phylogenetic-plus-spatial layers, or add structured
residual-`rho12` effects.
