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

The current-source fit for this historical data now reports a
positive-definite Hessian and finite fixed-effect covariance at residual SD
`0.000224`; its objective agrees with this dense oracle. Thus this particular
historical non-PD result was a numerical artifact of the earlier AR1 transition
calculation, even though its marginal likelihood remains very flat at the
residual boundary. It is not evidence that the interval route is calibrated.

A disjoint current-source C1 seed has both unavailable covariance and an
independent dense profile that reaches the residual boundary. That is the live
G7 blocker; see `c1-current-source-reconciliation-2026-09-09.md`.

The raw attempts, selected profile, free fits, provenance, and session details
are retained under
`docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-c1-dense-marginal-profile/`.
