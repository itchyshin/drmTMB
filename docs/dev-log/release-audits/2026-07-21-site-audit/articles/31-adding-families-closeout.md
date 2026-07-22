# Adding distribution families: audit closeout

- **Audit date:** 2026-07-21
- **Pinned base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Source:** `vignettes/adding-families.Rmd`
- **Rendered route:** `articles/adding-families.html`
- **Scope:** contributor guide only; no family code, likelihood, or simulation
  claim was changed.

## Finding and repair

The guide correctly frames a new family as an equation-to-public-surface
contract, rather than a constructor-only change. Its Student-t likelihood,
parameter transform, tests, documentation, and after-task requirements were
checked against the current source and design references.

One P1 stale statement was repaired. The guide said Student-t shape random
effects were rejected outright. The package has a narrow, diagnostic-only
intercept phylogenetic `nu` path (`tests/testthat/test-nongaussian-structured-boundary.R`), so that absolute wording was false. The guide now separates unavailable ordinary `sigma`/scale and bivariate paths from the exact structured exceptions, and states that a fitted exception does not create blanket support.

## Render and checks

- Rebuilt locally with `pkgdown::build_article("adding-families", ...)` on
  2026-07-21.
- `git diff --check` passed.
- Fresh render evidence: `renders/adding-families-desktop-1440x1000.png` and
  `renders/adding-families-mobile-390x844.png`.
- Mobile inspection found readable prose, code examples, and checklist layout.

## Boundary retained

This repair does not validate a new Student-t random-effect route, add a
family, change its likelihood, promote an evidence tier, or authorize a
simulation campaign. It corrects the contributor-facing description of the
already implemented, row-specific boundary.
