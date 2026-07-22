# Large-data guide audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/large-data.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | Benchmark and capability tables need stable narrow-screen reading treatment. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| Claim/figure audit | The article distinguishes fitted-object memory reduction from construction-time memory limits, bounds sparse and aggregation paths to their exact Gaussian routes, and makes local benchmark timing non-generalizable. It also states the retained-object requirements of Wald, profile, and bootstrap intervals. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("large-data", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/large-data-desktop-1440x1000.png` and
  `renders/large-data-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  code and tables.
- Original-resolution inspection of the profile benchmark plot confirmed that
  it is a local elapsed-seconds comparison, uses point marks only, labels its
  log scale, and explicitly disclaims uncertainty interpretation.
- `git diff --check` passed.

## What this repair does not establish

It does not certify million-row, bivariate, factor-heavy, non-Gaussian, or
10,000-species performance; make memory-light fits inference-ready; or turn
local timing benchmarks into platform-wide guarantees.
