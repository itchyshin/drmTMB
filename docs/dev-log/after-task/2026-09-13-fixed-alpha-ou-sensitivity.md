# After Task: Experimental fixed-alpha phylogenetic OU sensitivity

## Goal

Promote the useful part of the parked OU-v1 work without claiming that free OU
rates, recovery, or the frozen full-capability census are complete.

## Implemented

`ou_sensitivity()` fits an unchanged BM comparator and a user-specified grid of
fixed location-side OU decay values for one complete-response univariate
Gaussian phylogenetic intercept model. It returns the fits, conditional
likelihood/AIC and diagnostics, and fixed effects for both `mu` and `sigma`.
The default alpha scale is the ultrametric root-to-tip depth; raw branch-length
rates can be requested explicitly.

## Mathematical Contract

For every displayed alpha, native TMB fixes
`log_decay_phylo = log(alpha / tree_height)` under root-depth scaling. The
only changed covariance assumption is the location-side OU decay; rows, tree,
fixed-effect formulae, controls, and ML fitting route are shared with the BM
comparator. Conditional AIC differences are therefore sensitivity summaries,
not alpha estimates, confidence intervals, or process-selection evidence.

## Files Changed

- `R/ou-sensitivity.R`, `man/ou_sensitivity.Rd`, and `NAMESPACE`
- `tests/testthat/test-ou-sensitivity.R`
- `docs/design/273-fixed-alpha-ou-sensitivity-api.md`
- `vignettes/formula-grammar.Rmd`, `NEWS.md`, `docs/dev-log/known-limitations.md`, and `_pkgdown.yml`
- this report and `docs/dev-log/check-log.md`

## Checks Run

`air format`, `devtools::document()`, and the focused `ou-sensitivity` test
file passed. The test suite exercised BM plus two fixed rates, both scaling
conventions, fixed-effect extraction, and five refusal paths. `git diff --check`
passed. A reference-index build found an existing missing `temporal` topic in
`_pkgdown.yml`; no site pass is claimed. A local `R CMD check --no-manual`
started and passed early source/namespace/dependency checks but terminated at
installation in this execution surface, so it is not a package-check pass.
The existing `phylo-ou` filter passed its covariance/parser files but its
unrelated retained sigma-recovery receipt failed its stale-provenance guard;
that evidence artifact was not changed. Re-running the native covariance and
parser files independently confirmed both pass alongside the focused helper
test.

## Tests Of The Tests

The positive test reads the native mapped `log_decay_phylo` value, so a grid
that only relabelled a free-rate fit would fail. Negative tests reject scale-side
OU, a phylogenetic slope, missing model data, duplicate alpha values, and a
non-ultrametric tree. The successful example combines the new helper with the
already supported fixed `sigma` regression.

## Consistency Audit

The status inventory was searched across README, roadmap, limitations, formula
grammar, phylogenetic tutorial, NEWS, and pkgdown configuration. New user text
consistently says “experimental fixed-alpha sensitivity”; it explicitly keeps
full OU v1 parked and does not claim that BM or OU is generally preferable.

## GitHub Issue Maintenance

Open phylogenetic/OU issues were inspected. No exact fixed-alpha sensitivity
issue was open. Issue #570 is a different Ayumi sigma-phylo optimizer problem,
so no issue was opened or updated.

## What Did Not Go Smoothly

The installed pkgdown version rejected the initially supplied `quiet` argument;
the compatible rerun then exposed a pre-existing missing `temporal` reference
topic. The sandboxed package check did not survive its installation stage.
Neither result changes the focused API/test evidence, but neither is hidden.

## Team Learning

An empirical AIC grid needs both explicit tree-depth units and the coefficient
trajectories users actually interpret. A user-facing helper is safer than
asking users to modify an internal TMB parameter map.

## Known Limitations

Only a univariate complete-response Gaussian location-side OU intercept is
admitted. There is no free alpha, scale-side OU, correlation, direct-SD,
random-effect, REML, missing-response, bivariate/non-Gaussian, newdata, or
forecast support. The full OU-v1 manifest remains parked.

## Next Actions

Use `ou_sensitivity()` for prespecified biological robustness grids, including
the retained Ayumi-style climate formula. Restart free-rate OU only as a new,
evidence-first arc; do not treat this wrapper as its replacement.
