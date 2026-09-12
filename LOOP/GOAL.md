# GOAL — reusable predictor-aware phylogenetic OU foundation

Implement and validate a reusable phylogenetic OU provider foundation in an
isolated worktree. Brownian motion remains the default; the first public route
is an explicit `phylo(..., model = "ou")` univariate Gaussian location
intercept with fixed-effect residual `sigma` and optional direct phylogenetic
SD amplitude. Ayumi's all-species body-mass model is the empirical feasibility
acceptance example.

## Definition of done

- [x] A field-keyed OU provider allocates a separate positive alpha per latent field without silently sharing a rate.
- [x] Parser, native likelihood, independent oracle/mutations, BM parity, source-pinned empirical ladder, and sparse-resource preflight are retained.
- [x] Public wording says `decay_phylo` is `alpha_mu`, distinguishes fixed residual `sigma`, and defers sigma-side phylogeny/`alpha_sigma`.
- [ ] Independent mathematical, inference, and systems review plus an after-task reconciliation establish the earned scope.

## Invariants

- `model = "bm"` and an omitted model remain Brownian covariance.
- Fixed-effect `sigma ~ x` changes independent residual variation, not the OU covariance process.
- Do not admit sigma-side OU, bivariate/missing-response OU, temporal work, recovery/coverage, intervals, or an OU-preference claim without a separate validated arc.
- Preserve the all-node sparse tree representation; do not build all-tip dense covariance for the empirical or scalability fit.

## Pre-authorisation

Scoped edits, local tests, source-pinned local feasibility fits, resource preflights, documentation, and local commits are authorised. A retained simulation/calibration campaign over 30 minutes, remote computation, merge, push, release, external messaging, or the deferred `alpha_sigma` arc requires separate authority.
