# After Task: G13 joint independent phylogenetic OU fields

## Goal

Implement the exact univariate Gaussian ML formula with independent phylogenetic OU intercept fields in location and residual log-scale, retaining BM as the default and exposing separate `alpha_mu` and `alpha_sigma` rates.

## Implemented

Matching unlabelled OU intercepts in `mu` and `sigma` now fit independent fields. `decay_phylo` reports `alpha_mu`; `decay_phylo:sigma` reports `alpha_sigma`. The explicit joint route maps out BM's `eta_cor_phylo`, so no phylogenetic cross-field correlation appears in `corpars$phylo` or `corpairs()`.

## Mathematical Contract

Each registered field has its own stationary root density and normalized edge transition. Location and log-scale contributions are combined before the configured smooth log-scale clamp. The fitted objective is Laplace-approximated marginal ML. A small-tree R oracle independently evaluates dense all-node covariance densities for both conditional latent fields; its objective, score, and Hessian agree with native TMB. This does not establish exact marginal likelihood or recovery.

## Files Changed

Parser/provider routing: `R/drmTMB.R`, `R/temporal.R`; simulation: `R/methods.R`; native tree loop: `src/drmTMB.cpp`; focused tests: `tests/testthat/test-phylo-ou-covariance-{parser,native}.R`; formula, likelihood, reference, README, NEWS, limitations, and vignette surfaces were synchronized.

## Checks Run

Focused parser/native suites passed after final repairs. The unchanged BM phylogenetic suite passed with 354 expectations, three known deprecation warnings, and two CRAN skips. `devtools::document()` regenerated `man/phylo.Rd` and `man/simulate.drmTMB.Rd`. The controlled G1--G9 re-verification is recorded in the Unlazy ledger.

## Tests Of The Tests

The public parser test failed before admission was added. Dense-oracle tests mutate swapped rates, omitted root density, wrong edge variance, omitted scale contribution, registry ordering, and a value beyond the clamp identity band. Parser tests reject labels, known sampling covariance, bridge routing, REML, direct-SD, weights, and unmatched fields.

## Consistency Audit

Searched README, NEWS, limitations, design notes, affected vignettes, `R/`, and generated `man/` files for stale alpha-sigma-deferred claims. The public narrative now distinguishes location-only OU from the joint Laplace-ML local-fit/oracle route.

## GitHub Issue Maintenance

The supplied Ayumi issue tracker was inspected during orientation. No issue was updated: this local slice has no release or model-comparison claim.

## What Did Not Go Smoothly

The fixed-seed preflight did not recover either rate reliably, including a boundary-like `alpha_sigma` and non-positive-definite Hessians. Review also caught a missing clamp in the oracle contract and missing labels/known-covariance/Julia fences. All were retained or repaired rather than recast as positive evidence.

## Team Learning

Multi-field latent models must route observation columns, offsets, SDs, and rates by explicit field indices. An independent conditional covariance oracle and a recovery campaign answer different questions.

## Known Limitations

This route excludes slopes, labels, direct-SD formulas, known sampling covariance, REML, other random/structured effects, missingness, temporal terms, bivariate/non-Gaussian families, `newdata`, forecasts, intervals, and OU cross-field correlation. The retained simulation preflight is negative engineering evidence; a replicated campaign is required before recovery, interval, coverage, selection, or broad-support claims.

## Next Actions

Run an approved replicated recovery campaign with adequate species and within-species replication. Treat correlated OU fields, `alpha_sigma` slopes/direct-SD combinations, and temporal work as new mathematical arcs.
