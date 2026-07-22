# Julia-engine future-support audit closeout

**Status:** repaired and rendered 2026-07-21  
**Source:** `vignettes/julia-engine.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P1 | The 0.6 manifest defers `engine = "julia"`, while the former article mixed that warning with reader-facing parity, interval, and performance-admission claims. | Owner decision: Julia is halted; reduce the page to future support only. Replaced the prototype walkthrough with a concise deferred-scope page. |

## Render and visual evidence

- `pkgdown::build_article("julia-engine", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- Fresh full-page captures: `renders/julia-engine-desktop-1440x1000.png` and
  `renders/julia-engine-mobile-390x844.png`.
- A 390 x 844 viewport inspection confirmed the halt/deferment boundary is
  prominent before any code, and the native TMB path is the only current
  workflow presented.
- The reduced page contains no development benchmark, parity, or interval
  figure that could imply a released Julia capability.
- `git diff --check` passed.

## What this repair does not establish

It does not admit a Julia bridge model cell, install Julia-side dependencies,
claim parity, provide Julia-engine intervals, or change the native TMB model
surface.
