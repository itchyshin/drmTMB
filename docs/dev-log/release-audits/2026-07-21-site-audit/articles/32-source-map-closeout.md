# Implemented source map: audit closeout

- **Audit date:** 2026-07-21
- **Pinned base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Source:** `vignettes/source-map.Rmd`
- **Rendered route:** `articles/source-map.html`
- **Scope:** contributor source-map and navigation surface; no implementation
  or evidence tier was changed.

## Findings and repair

The article was checked as a source-to-test-to-document route map, including
the current model-type inventory, builders, TMB paths, formula markers,
validation-debt boundary, and the protected `bivariate-coscale` reference.
The bivariate article is linked as a dependency but was not modified.

One P1 historical claim was repaired. The Poisson structured-effect row said
that its simulation workflow supplied manual GitHub Actions artifacts. The
package policy prohibits simulation, recovery, power, and coverage campaigns
on GitHub Actions and prohibits their artifact storage there. The row now keeps
the DGP/fit/smoke/grid source map but states the current local or Totoro/DRAC
execution boundary.

Responsive table styling was added for the six-column implemented-path map.

## Render and checks

- Rebuilt locally with `pkgdown::build_article("source-map", ...)` on
  2026-07-21.
- `git diff --check` passed.
- Fresh render evidence: `renders/source-map-desktop-1440x1000.png` and
  `renders/source-map-mobile-390x844.png`.
- The mobile article remains legible and the intentionally wide source map is
  horizontally scrollable rather than squeezed into unreadable columns.

## Boundary retained

This repair neither runs nor certifies a simulation campaign, changes a source
path, promotes support, changes formula grammar, or modifies the
owner-held `bivariate-coscale` article. It corrects the contributor-facing
execution-policy statement only.
