---
name: tmb-likelihood-review
description: Review TMB likelihoods and parameterizations before merging.
---

# TMB Likelihood Review

Use this skill for any change to C++ templates, density functions, or parameter
transforms.

## Review Checklist

- Are all constrained parameters represented internally on unconstrained scales?
- Are positive parameters on log scales?
- Are correlations on tanh/atanh or another stable bounded transform?
- Are constants included consistently in likelihoods?
- Are gradients finite for simulated data?
- Does `sdreport()` report interpretable transformed parameters?
- Does simulation recover truth under ordinary sample sizes?
- Are boundary and weak-identification cases tested?

For bivariate Gaussian models, verify that each observation's covariance matrix
is positive definite:

```text
Omega_i = [sigma1_i^2, rho12_i * sigma1_i * sigma2_i;
           rho12_i * sigma1_i * sigma2_i, sigma2_i^2]
```
