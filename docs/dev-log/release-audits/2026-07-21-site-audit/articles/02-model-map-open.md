# Model-map audit: open P1

**Page:** `vignettes/model-map.Rmd`  
**Audit base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`  
**Status:** repaired and ready for closeout

## P1: `meta_V()` status has no ledger authority

The stable-core matrix calls Gaussian `meta_V(V = V)` “Stable, with
dense-storage guardrails.” The capability ledger contains no `meta_V` model
surface cell. The nearest applicable record, `mc-0260`, says known-variance
meta-analysis is outside the census effect/provider axes and preserves the
core Gaussian fixed-effect row at a conservative tier for exactly that reason.

The implementation and tests support the factual statement that Gaussian
`meta_V()` fits exist, but they do not supply a registered ledger tier for the
page’s “Stable” label. The page has therefore been downgraded to
“Implemented, source-tested; ledger tier unregistered.” This removes an
unsupported maturity claim without changing package capability or fabricating
a ledger cell. A separate evidence review may later register a bounded cell.

## Other observed repair candidate

The rendered 390 px page had several wide tables that overflowed the reader
surface. A page-scoped small-screen table rule now makes each table a bounded,
horizontally scrollable reader region. The repaired page rebuilt successfully;
the refreshed 390 x 844 viewport capture confirms that the page itself stays
within the mobile viewport. This P2 repair does not resolve the open status
claim above.

The bivariate `rho12` rows now also say that interval availability is not
bivariate fixed-effect CI-coverage certification, consistent with `mc-0181`.

## Closeout evidence

- `pkgdown::build_article("model-map", pkg = ".", lazy = FALSE,
  new_process = TRUE)` completed successfully on 2026-07-21.
- The rendered HTML contains the source-tested/ledger-unregistered label, the
  corrected `rho12` provenance, and the small-screen table rule.
- Fresh full-page screenshots were captured at 1440 x 1000 and 390 x 844 in
  `renders/model-map-desktop-1440x1000.png` and
  `renders/model-map-mobile-390x844.png`.
- `git diff --check` passed before closeout.

This repair does not create a `meta_V()` capability-ledger cell, establish
interval coverage for known-covariance fits or bivariate `rho12`, or widen any
model surface.
