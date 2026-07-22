# Coordinate-spatial structured-effects audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/spatial-models.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P2 | The route table compressed formula and status cells into unreadable fragments on a narrow viewport. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |
| Claim/figure audit | The page limits REML to its exact fixed-coordinate cells, keeps q=2 correlations and spatial SDs point-only when interval calibration is planned, and keeps q=4 correlations derived/unavailable for intervals. | No claim edit required. |

## Render and visual evidence

- `pkgdown::build_article("spatial-models", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/spatial-models-desktop-1440x1000.png` and
  `renders/spatial-models-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and a
  horizontally scrollable route table rather than compressed formula fragments.
- Original-resolution inspection of `spatial-sd-figure-1.png` confirmed that
  intercept and depth-slope SDs carry different units and are explicitly
  point-only; site-field and q=2-correlation displays likewise avoid interval
  marks where calibration remains planned.
- `git diff --check` passed.

## What this repair does not establish

It does not promote spatial interval/coverage support, estimate a spatial
range, admit mesh/SPDE inputs, enable multiple or labelled spatial slopes,
support broader non-Gaussian spatial effects, or add structured residual
`rho12` routes.
