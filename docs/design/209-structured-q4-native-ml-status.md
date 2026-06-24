# Structured q4 Native ML Status

## Purpose

This note records the SR031-SR040 q4 boundary for structured random effects.
It keeps constant all-four q4 point/extractor support separate from derived
correlation intervals, scale-side identifiability warnings, and native REML or
bridge claims.

## Current q4 Rows

The implemented native TMB ML q4 rows use matching labelled intercept-only
terms across `mu1`, `mu2`, `sigma1`, and `sigma2`:

- `phylo(1 | p | species, tree = tree)`;
- `spatial(1 | p | site, coords = coords)`;
- `animal(1 | p | id, pedigree = pedigree)`, `animal(1 | p | id, A = A)`,
  or `animal(1 | p | id, Ainv = Ainv)`;
- `relmat(1 | p | id, K = K)` or `relmat(1 | p | id, Q = Q)`.

The focused tests check finite fitted objectives, four endpoint SD names, six
latent correlation rows, `corpairs()`, `summary(fit)$covariance`, q4
diagnostic rows, and rejection of partial or unlabelled q4 formulas.

## Target Boundary

Endpoint SDs are direct model parameters. The six q4 correlations are derived
from the unstructured latent-correlation parameterization and are not direct
profile targets in the current native TMB surface. The tests expect q4
correlation rows to carry `target_type = "derived"`, `profile_ready = FALSE`,
and `derived_unstructured_correlation` notes.

That means q4 point/extractor support does not imply q4 interval support.

## Diagnostic Boundary

Scale-side q4 terms include `sigma1` and `sigma2` endpoint fields. They need
within-level replication to separate scale variation from residual noise. The
known limitations and scale-phylo diagnostic ledger keep this visible: weak
replication, false positive-definite Hessians, and clamp-active log-`sigma`
diagnostics are warning evidence, not support failures or interval evidence.

## Not Claimed

This note does not promote:

- native q4 REML;
- HSquared or AI-REML q4 support;
- R-to-Julia bridge parity;
- public optimizer controls;
- calibrated profile/bootstrap coverage;
- q4 count or non-Gaussian structured covariance;
- predictor-dependent q4 `corpair()` regressions.
