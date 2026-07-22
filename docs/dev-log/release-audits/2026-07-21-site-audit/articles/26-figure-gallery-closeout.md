# Figure-gallery audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/figure-gallery.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P1 | The prose called the constant `rho12 ~ 1` profile interval a certified reporting target, contradicting the release manifest's no-coverage-evidence boundary. | Repaired: constant and row-specific intervals are described as computable, with coverage explicitly unestablished. |
| P2 | The table-heavy gallery lacked the shared narrow-screen reading treatment. | Repaired with page-scoped heading rules and a 720 px horizontally scrollable table surface. |

## Render and visual evidence

- `pkgdown::build_article("figure-gallery", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/figure-gallery-desktop-1440x1000.png` and
  `renders/figure-gallery-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed readable title/prose and contained
  gallery navigation and tables.
- Original-resolution inspection of the fitted constant-`rho12` Confidence Eye
  confirmed that it visibly identifies the fitted residual-correlation target;
  the accompanying source text now withholds coverage certification. Fixture
  figures remain labelled as fixtures, not fitted results.
- `git diff --check` passed.

## What this repair does not establish

It does not certify coverage for constant or regression-`rho12` intervals,
turn a figure fixture into evidence, or promote unvalidated structured,
derived, or random-effect uncertainty displays.
