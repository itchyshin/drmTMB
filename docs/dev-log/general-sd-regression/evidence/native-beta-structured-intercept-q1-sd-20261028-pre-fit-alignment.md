# Native Beta structured-intercept q1 SD: pre-fit contract

## Scientific model

For a single structured intercept field, let the supplied covariance be `K` and
`u ~ N(0, K)`. For group `g`, `s_g = exp(alpha0 + alpha1*z_g)` and
`b_g = s_g*u_g`. The response predictor is
`eta_i = X_i beta + b_group[i]`; the Beta mean is
`mu_i = 1e-12 + (1 - 2e-12)*plogis(eta_i)` and precision is
`phi = exp(-2*log_sigma)`. The DGP and likelihood use the established Beta
parameterization; the only mean adjustment is the existing epsilon transform.
The q1 Gaussian negative log density is
`0.5*u' solve(K) u + 0.5*G*log(2*pi) + 0.5*logdet(K)`.
The marginal negative log likelihood uses the Laplace correction
`0.5*logdet(H) - 0.5*G*log(2*pi)`, where `H` is the Hessian in the G latent
intercepts. These constants are frozen before fitting.

## Frozen data and acceptance checks

Use 64 named groups, 20 observations per group, balanced group-level `z` in
{-1, 1}, and within-group `x` spanning [-1.2, 1.2]. Fixed mean coefficients
are 0.2 and 0.3; `alpha = (log(0.5), 0.5)`; `log_sigma = log(0.35)`.
Relmat uses the independently defined non-unit AR-like covariance
`K_ij = 0.25^|i-j| * sqrt(d_i*d_j)`, with `d` linearly spanning 0.8 to 1.3.
The spatial covariance is independently constructed from Euclidean distances:
`range = median(positive unordered distances)` and
`K = exp(-distance/range) + 1e-6*I`, retaining its raw diagonal. Coordinates
are a fixed 8 by 8 grid.

Frozen simulation seeds are 2026102810 for relmat K and Q (the response data
are identical under both representations), and 2026102811 for coordinate
spatial. Use one BLAS and OpenMP thread. Recovery is a single-seed point-fit
smoke: convergence must be zero and the estimated `z` slope for the SD must
be within 0.4 of 0.5. The independent scalar oracle must match the reported
Laplace negative log likelihood and conditional predictor to absolute 1e-4;
its latent score at the mode must be below 1e-5, and central finite differences
must match analytic score and Hessian to 1e-4 and 2e-4. K and Q fits must
agree to 1e-4 in likelihood, fixed effects, SD coefficients, and predictions.
The constant-SD and no-SD baseline likelihoods must agree to 1e-4. No threshold,
seed, or DGP adjustment is permitted after seeing fit results.

## Boundaries

Only native Beta, complete responses, one unlabelled independent structured
intercept, and fixed-effect-only sigma are in scope. Existing supported
intercept-plus-one-slope q2 routes remain supported but are outside this q1
validation. Reject slope-only, multiple slopes, labelled covariance, a second random
layer, sigma random effects, missing-data handling, mesh input, and incomplete
coordinates. The coordinate kernel uses the existing fixed range; no range
estimation or unused-site prediction claim is made. Coverage, broad recovery,
Julia runtime parity, and public capability-map promotion are deferred.

## Runtime estimate

Estimate 100 seconds for the focused q1 fit check and 240 seconds for the
targeted q1 plus neighboring q2 suites. Stop and report if either estimate is exceeded.
