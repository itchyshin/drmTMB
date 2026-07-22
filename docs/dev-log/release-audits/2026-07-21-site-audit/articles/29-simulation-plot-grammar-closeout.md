# Simulation-plot-grammar audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/simulation-plot-grammar.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The fixture-table sections needed stable narrow-screen handling. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| Claim/figure audit | The page explicitly labels its data as illustrative fixtures, retains not-targeted and failed lanes, and uses MCSE intervals for aggregate bias/RMSE/coverage/power summaries rather than decorative confidence marks. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("simulation-plot-grammar", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures:
  `renders/simulation-plot-grammar-desktop-1440x1000.png` and
  `renders/simulation-plot-grammar-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  long links, code, and tables.
- Fixture figures consistently identify their typed/non-fitted nature and give
  MCSE provenance for aggregate uncertainty.
- `git diff --check` passed.

## What this repair does not establish

It does not promote any fixture value into recovery or coverage evidence, omit
failed replicates from a real campaign, or substitute a display grammar for a
predeclared simulation design and retained-result audit.
