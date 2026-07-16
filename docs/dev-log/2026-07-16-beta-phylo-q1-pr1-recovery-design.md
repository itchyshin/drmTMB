# PR 1 Beta phylogenetic q1 recovery design

**Frozen:** 2026-07-16, before campaign launch  
**Estimator:** native R/TMB, ML  
**Claim ceiling:** `point_fit_recovery`

This campaign evaluates only the PR 1 constant-SD Beta phylogenetic location cell frozen in `2026-07-16-beta-phylo-q1-pr1-symbolic-alignment.md`. It evaluates neither direct-SD regression nor intervals or coverage.

## DGP

For each tree with `g` tips and `m` observations per tip, draw a unit-diagonal phylogenetic tip covariance `A`, then `a = tau * t(chol(A)) %*% z`. Generate standardized observation-level `x` independently of the tree and fit the same fixed predictor in `mu` and family `sigma`:

```text
logit(mu_i) = 0 + 0.35 x_i + a_s(i)
log(sigma_i) = log(0.25) + 0.20 x_i
phi_i = sigma_i^(-2)
y_i ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
tau = 0.30
```

The DGP contains no direct-SD predictor or phylogenetic precision effect. `sigma` remains the Beta family variability parameter and `tau` the latent phylogenetic location SD.

## Information grid and retained denominator

Run 400 deterministic replicates in each of three cells: `g = 64, 256, 1024`, always with `m = 2`. This is 1,200 attempted fits. The master seed is `2026071601`; derive each replicate seed deterministically from the cell and replicate. Retain every attempted row, including errors, non-zero optimizer codes, `pdHess = FALSE`, warnings, boundaries, and non-finite gradients.

Use the launch ladder: one local fit, one remote replicate in each cell, then the complete campaign. Run on Totoro with at most 32 workers and `OPENBLAS_NUM_THREADS=1`; use DRAC only if Totoro cannot run the bounded campaign. GitHub Actions must not run the campaign or store its output.

## Required attempt-level record

Each row records `g`, `m`, replicate, seed, elapsed time, error/warning text, convergence code, `pdHess`, maximum absolute fixed gradient, and estimates for `beta_mu`, `beta_sigma`, and `tau`. The summarizer reports all-attempted convergence, Hessian, boundary, and finite-gradient rates plus usable-count, bias, RMSE, empirical SD, and MCSE of bias for every target.

## Predeclared recovery gate

The campaign supports the PR 1 `point_fit_recovery` claim only when all 1,200 uniquely keyed attempts are retained and the high-information cells (`g >= 256`) satisfy all of the following:

1. optimizer convergence is at least 95% and `pdHess` is at least 90%;
2. absolute bias is at most 0.10 for `beta_mu[x]` and `beta_sigma[x]`;
3. absolute bias of `log(tau)` is at most 0.10; and
4. RMSE for every named target does not materially worsen from `g = 256` to `g = 1024`, allowing one paired cell-level MCSE.

A failed gate remains visible in the all-attempted summary and blocks promotion; it is never removed or repaired after inspecting results. This is not an interval, coverage, or general Beta random-effect claim.
