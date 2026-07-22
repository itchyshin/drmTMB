# Meta-analysis audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/meta-analysis.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | Known-variance, heterogeneity, and comparator tables can exceed a narrow reader surface. | Repaired with a page-scoped mobile table containment rule. |
| Claim audit | The article identifies `meta_V()` as an implemented syntax route but assigns no unsupported capability tier. Its exact additive known-variance, ML/REML, and `metafor` comparator statements are supported by local implementation/design and test surfaces. | No claim edit required. |

## Render and focused checks

- `pkgdown::build_article("meta-analysis", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/meta-analysis-desktop-1440x1000.png` and
  `renders/meta-analysis-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable prose and bounded tables;
  title line breaks occur at the semantic hyphens in “random-effects” and
  “meta-analysis,” not inside ordinary words.
- `git diff --check` passed.

## What this repair does not establish

It does not create a capability-ledger cell or maturity tier for `meta_V()`,
certify broad known-covariance interval coverage, add non-Gaussian
meta-analysis, or widen the known-covariance API.
