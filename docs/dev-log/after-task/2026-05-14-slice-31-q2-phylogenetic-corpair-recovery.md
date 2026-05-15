# After Task: Slice 31 q2 phylogenetic corpair recovery

## Goal

Add evidence that the fitted q=2 phylogenetic `corpair()` regression can recover
a species-level correlation trend, without pretending that the small package
test gives exact coefficient recovery or confidence-interval coverage.

## Implemented

- Added a deterministic bivariate Gaussian phylogenetic simulation with 16
  species and 10 observations per species.
- Simulated a positive species-level predictor effect on the local q=2
  phylogenetic `mu1`-`mu2` correlation.
- Fitted the implemented syntax:
  `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ z_species`.
- Checked convergence, positive fitted slope, fitted correlations away from the
  guard, and strong agreement between the fitted and simulated response-scale
  correlation ordering.
- Updated `NEWS.md`, `ROADMAP.md`, and the check-log to describe this as
  broad-trend recovery evidence.

## Mathematical Contract

The slice uses the same two-field loading contract as Slices 28-30:

```text
rho_l = tanh_guard(W_l alpha)
a1_l = tau1 (c_l z1_l + d_l z2_l)
a2_l = tau2 (c_l z1_l - d_l z2_l)
```

The recovery target is the monotone species-level correlation surface, not exact
finite-sample recovery of each link-scale coefficient.

## Files Changed

- `tests/testthat/test-phylo-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `devtools::test(filter = "phylo-gaussian", reporter = "summary")`: passed.

## Tests Of The Tests

The test uses a known simulated positive `z_species` effect and verifies that
the fitted response-scale phylogenetic correlations track the simulated ordering
with `cor(rho_hat, rho_true) > 0.95`, while also checking convergence and that
the fitted correlations stay away from the tanh guard. This is stronger than the
Slice 28-30 smoke test, which only checked plumbing and reporting.

## Consistency Audit

The package now has three layers of evidence for the q=2 phylogenetic
`corpair()` path:

- Slice 27 algebra: positive-definite loading contract and constant-correlation
  equivalence.
- Slices 28-30 implementation: TMB/R plumbing, reporting, profile-target names,
  docs, and smoke tests.
- Slice 31 recovery: deterministic broad-trend recovery for a positive
  species-level correlation predictor.

## What Did Not Go Smoothly

The first eight-species smoke design could fit extreme coefficients and saturate
the response-scale correlations. Curie separated that test from recovery and
used a moderate 16-species design for recovery instead.

## Team Learning

- Ada: keep recovery as its own slice, even when the implementation slice is
  tempting to call complete.
- Curie: tune simulation size and signal so tests check the scientific target
  without making CRAN or CI slow.
- Fisher: trend recovery is useful evidence, but interval coverage and exact
  coefficient recovery are later simulation-study work.
- Gauss: the loading contract behaves well in a moderate deterministic design;
  future q=4 work still needs its own positive-definite parameterization.
- Grace: run the focused phylogenetic test before adding docs or moving to
  spatial.
- Rose: label the evidence honestly: broad trend recovery, not full validation.

## Known Limitations

- No q=4 phylogenetic location-scale or scale-scale `corpair()` regression is
  fitted.
- No spatial random effect or spatial `corpair()` regression is fitted.
- No profile-likelihood coverage simulation is added.

## Next Actions

Move to the spatial foundation lane. Before implementing spatial likelihoods,
decide the dependency/provenance route for mesh and SPDE/GMRF infrastructure,
including explicit citations for any sdmTMB/fmesher/INLA-inspired machinery.
