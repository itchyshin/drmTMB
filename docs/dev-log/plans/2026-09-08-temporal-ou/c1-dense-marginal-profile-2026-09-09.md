# C1 dense marginal likelihood profile

This bounded diagnostic resolves the question raised by the retained C1 seed
`2026091002`: is its near-zero residual SD an artifact of the latent-state TMB
optimizer, or does the Gaussian marginal likelihood itself have a boundary?

The script `tools/diagnose-temporal-ar1-c1-dense-profile.R` regenerates the
frozen C1 data and independently evaluates the model after analytically
marginalizing the ordinary intercept and temporal AR1 field. For each fixed
residual SD it profiles the three mean coefficients by GLS and optimizes only
the ordinary-intercept SD, temporal-process SD, and signed persistence from
four starts. It also fits the same dense likelihood with residual SD free.

The selected fixed-SD objective was `618.883549144532` at `sigma = 1e-7`,
`618.883549173073` at `1e-4`, `618.883551998606` at `1e-3`, and
`618.913025096580` at `0.1`. The first four values differ by at most
`2.9e-8`, and the objective increases thereafter. All four free-SD starts
converged to `sigma` between `0.000131` and `0.000155`, with objectives
slightly above the finite-grid minimum by roughly `5e-8`.

The direct marginal profile agrees with the converged fixed-sigma native fits
(for example, both give `618.9130250966` at `sigma = 0.1`). It therefore
eliminates latent-state optimization as the explanation. The evidence supports
an active or practically flat residual-variance boundary: it does not establish
a finite regular MLE at the chosen numerical stopping tolerance.

The free-sigma full observed-Hessian Wald covariance remains invalid for this
dataset. Selecting a nearby positive-definite candidate would change the
objective and is not an inference repair. The remaining decision is scientific
and methodological: retain unavailable intervals at such boundaries and treat
them as uncovered in calibration; introduce a separately justified boundary
method; or alter the scientific model to fix residual scale and revalidate that
different estimand. Until then, G7 stays closed and OU Wald inference remains
guarded.

The raw attempts, selected profile, free fits, provenance, and session details
are retained under
`docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-c1-dense-marginal-profile/`.
