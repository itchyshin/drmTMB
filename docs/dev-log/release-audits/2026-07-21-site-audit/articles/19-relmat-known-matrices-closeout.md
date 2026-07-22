# Known-matrix `relmat()` audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/relmat-known-matrices.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The matrix-choice and fitted-status tables need a stable narrow-screen reading surface. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| Claim/figure audit | The tutorial correctly separates latent relatedness `relmat()` from observation-level sampling covariance `meta_V()`, distinguishes K covariance from Q precision, bounds K/Q REML claims, and keeps q=2/q=4 correlations point-only where interval evidence is absent. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("relmat-known-matrices", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/relmat-known-matrices-desktop-1440x1000.png`
  and `renders/relmat-known-matrices-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose, contained
  equations, and a horizontally scrollable table surface.
- Original-resolution inspection of `relmat-sd-figure-1.png` confirmed that
  node marginal SD is explicitly distinguished from residual sigma and that
  its bars are labelled transformed 95% Wald intervals. The q=2 plot remains
  point-only where calibration is planned.
- `git diff --check` passed.

## What this repair does not establish

It does not register `meta_V()` in the capability ledger, promote broader K/Q
or REML routes, validate q=2/q=4 correlation intervals, admit multiple or
labelled structured slopes, or establish coverage for the named non-Gaussian
point-estimate routes.
