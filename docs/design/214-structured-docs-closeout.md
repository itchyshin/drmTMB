# Structured Random-Effect Docs Closeout

## Purpose

This note banks SR081-SR090 for the structured random-effect balance arc. It
records the documentation and review decision after the matrix/ledger pass.

## Formula Grammar And Limitations

The implementation scope did not change in this tranche, so the formula grammar
does not need a new syntax rule. The current source of truth remains
`docs/design/01-formula-grammar.md`, with the structured balance matrix adding
machine-readable status around the existing grammar.

Known limitations must continue to show the gaps:

- no mesh/SPDE spatial field;
- no large sparse pedigree construction claim;
- no generic direct-SD structured grammar outside existing routes;
- no residual `rho12` structured random effect;
- no non-Gaussian q2/q4 structured covariance support;
- no calibrated interval coverage for the structured balance rows;
- no public R-via-Julia bridge promotion for structured routes.

## Applied Route Table

For an applied reader, the route table is:

| Goal | Run-now route | Status |
| --- | --- | --- |
| q1 Gaussian structured location or scale point fit | native ML with `phylo()`, `spatial()`, `animal()`, or `relmat()` where the matrix row says fitted | fitted point/status evidence |
| q2 bivariate location covariance | native ML labelled `mu1`/`mu2` rows for the structured type | fitted point/extractor evidence |
| q4 all-four location-scale covariance | native ML labelled all-four row | diagnostic point/extractor evidence |
| scale-only q2 structured covariance | use q4 all-four when scientifically required | scale-only q2 remains rejected for spatial, animal, and `relmat()` |
| exact-Gaussian native REML | mean-side `phylo()` q1 only | partial native REML |
| interval coverage | replicated pilot needed | not evaluated |
| R-via-Julia bridge | row-specific experimental or planned rows | not broad support |

## Review Notes

Rose: the stale-claim risk is collapsing point support, inference status, and
bridge status into one word such as "balanced". The dashboard rows now force the
claim to name route, dimension, estimator, and evidence.

Pat: the user-facing answer should start with a run-now route and then name the
diagnostic caveat. A fitted q4 row is not the same thing as an interval an
applied user can interpret.

Gauss and Noether: the equations/code contract remains unchanged in this pass.
The q4 correlation targets are derived from the fitted covariance; they are not
direct profile targets unless a row-specific method says so.

Fisher: profile-target readiness, bootstrap bookkeeping, and interval coverage
remain separate. Coverage rows require replicated known-truth evidence with
Monte Carlo uncertainty.

## Decision

SR081-SR090 are banked as documentation synchronization and review rows. No
README, NEWS, roxygen, pkgdown navigation, or formula-grammar change was needed
because no public API or syntax changed in this tranche. The dashboard README
and this note carry the synchronized story for the new matrix and 100-slice
ledger.
