# Core drmTMB article audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/drmTMB.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`  
**Claim authority:** `docs/dev-log/dashboard/capability-ledger/cells.tsv`,
including `mc-0181` and the ledger’s explicit absence of a `meta_V()` cell.

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P1 | The high-level status table called known-covariance meta-analysis “stable” although no `meta_V()` ledger cell exists. | Repaired to “implemented, source-tested; ledger tier unregistered.” |
| P1 | The table called fixed-effect bivariate Gaussian `rho12` “stable,” despite `mc-0181` being `interval_feasible` with no committed bivariate fixed-effect CI-coverage simulation. | Repaired to “implemented; interval-feasible, but CI coverage unregistered.” |
| P2 | The learning-path and status tables could widen the 390 px reader surface. | Repaired with page-scoped table containment and word-boundary heading wrapping. |

## Render and focused checks

- `pkgdown::build_article("drmTMB", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/drmTMB-desktop-1440x1000.png` and
  `renders/drmTMB-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable landing-page prose and
  word-boundary heading wrapping.
- The rendered HTML contains both corrected status labels; `git diff --check`
  passed.

## What this repair does not establish

It does not create a `meta_V()` ledger cell, promote bivariate `rho12` CI
coverage, alter package installation/release status, or widen any likelihood,
family, or formula support.
