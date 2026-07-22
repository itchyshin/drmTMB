# Reference Julia-boundary repair: audit closeout

- **Audit date:** 2026-07-21
- **Pinned base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Roxygen sources:** `R/drmTMB.R`, `R/julia-bridge.R`
- **Regenerated topics:** `drmTMB`, `confint.drmTMB_julia`,
  `predict.drmTMB_julia`, `summary.drmTMB_julia`, `rho_latent`

## Finding and repair

The authoritative fitting help and the four retained Julia topics still
described an experimental supported engine, including bridge REML, profile,
bootstrap, prediction, and a runnable cross-family example. This contradicted
the current public decision: the Julia bridge is halted/deferred future work.

The regenerated help now states that `engine = "tmb"` is the current fitting
route. The `"julia"` bridge is retained solely for compatibility inspection of
existing objects and code; it is not a fitting, inference, REML, or
cross-family capability. The cross-family runnable example was removed.

## Render and checks

- `devtools::document()` regenerated all five Rd topics and completed a debug
  package compilation (existing compiler warnings only).
- `pkgdown::build_reference(pkg = ".")` rendered the reference index and all
  68 Rd topics successfully (69 HTML files including the index).
- `git diff --check` passed before rendering.
- Fresh evidence: `renders/reference-index-desktop-1440x1000.png` and
  `renders/reference-julia-mobile-390x844.png`.

## Boundary retained

This documentation repair does not remove the compatibility implementation,
test a Julia fit, validate a legacy interval, or claim current Julia parity.
The remaining Rd batches still require their topic-by-topic content audit.
