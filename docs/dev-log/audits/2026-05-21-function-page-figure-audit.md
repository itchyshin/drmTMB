# Audit Launch: Function, Page, Figure, and CI Consistency

## Purpose

Start the comprehensive audit requested after the CI/profile discussion. This
is the initial ledger, not the final audit report. It records the first slice
set, the scans that exposed stale wording, and the next artifacts that should
be filled before the audit is called complete.

## First Slice Set

1. CI workflow article: update the model-workflow article so users see the
   fastest path first: `confint(fit)`, `confint(fit, parm =
   "variance_components")`, targeted `method = "profile"` with
   `profile_precision = "fast"`, and direct-target `method = "bootstrap"`.
2. Sister-package source audit: record what the local `gllvmTMB` source does
   for profile controls, Fisher-z correlation intervals, and Sigma bootstrap
   refits without copying code into `drmTMB`.
3. Roadmap consistency: remove current-roadmap contradictions that still said
   public bootstrap was unavailable after the new direct-target `confint()`
   route landed.
4. Comprehensive map: create the function/page/figure audit map and queue the
   rendered figure gate.

## Stale-Wording Scan

Initial scan:

```sh
rg -n 'bootstrap intervals are not implemented|method = "bootstrap"|Fisher-z|fixed-effect intervals only|direct random-effect SD|profile_precision|wald_unavailable|profile_ready|parametric-bootstrap intervals' README.md ROADMAP.md NEWS.md docs/design vignettes R man tests/testthat -S
```

Important current-surface fixes from that scan:

- `vignettes/model-workflow.Rmd` still said parametric bootstrap was not a
  public `method` value and that `confint(fit, method = "bootstrap")` stopped
  before interval work. That is now stale for direct `confint()` targets.
- `vignettes/model-workflow.Rmd` still framed fitted-model Fisher-z intervals
  as not a public default for fitted correlation rows. That is now stale for
  direct fitted correlation targets because the Wald route uses the TMB
  covariance on the guarded correlation-link scale.
- `ROADMAP.md` rows 170-174 still described bootstrap as deferred and
  unsupported. Those rows need to be superseded by the new direct-target
  `confint()` route while keeping `summary()`, `corpairs()`, prediction
  tables, and derived summaries out of scope.

Historical NEWS rows and after-task reports that were true when written are
not edited solely for history. Current public pages and current roadmap rows
must match the live package.

## Figure Audit Queue

The next rendered-figure pass should inspect:

- `vignettes/figure-gallery.Rmd`, especially the random-effect SD surface,
  correlation displays, and any figure that mentions uncertainty.
- `vignettes/model-workflow.Rmd`, especially prediction-surface figures and
  interval-status examples.
- Simulation or implementation-map figures that summarize coverage, profile,
  bootstrap, smoke-only, or unsupported cells.

Each rendered figure should get a row with source chunk, estimand, visual data
grain, uncertainty source, missing-cell display, reader risk, verdict, and fix.
This launch note does not claim any figure was visually inspected after render.

## Next Tables To Fill

Function/reference table columns:

- exported name
- S3 class or generic
- help page
- pkgdown location
- example status
- focused tests
- known limitation or next action

Page/status table columns:

- page
- main reader
- implemented claims
- planned claims
- figures present
- stale-wording risk
- render/check status
- next action

Figure table columns:

- page and chunk
- figure purpose
- visual data grain
- uncertainty source
- missing or unsupported cells
- accessibility notes
- verdict
- fix

## Current Boundary

The CI implementation is in place, but this audit launch does not certify that
all functions, pages, and figures are consistent. It creates the map and fixes
the highest-priority interval contradictions exposed by the Bergmann report.
