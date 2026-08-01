---
title: "Lane C C2 Poisson phylo q2: plan versus actual"
date: 2026-07-28
lane: C
---

# Lane C C2 Poisson phylo q2 — plan versus actual

## Authorized target

One internal ordinary-Poisson route:

```r
count ~ x + phylo(1 + x | p | species, tree = tree)
```

The estimands are two latent phylogenetic SDs and their latent intercept--slope
correlation; no dispersion parameter is part of the Poisson target.

## Actual delivery

- The parser admits only labelled Poisson phylogenetic `1 + x`; tests retain
  rejection of spatial, animal, relmat, zero-inflated, q1, slope-only,
  multiple-slope, and ordinary-RE neighbours.
- The Poisson TMB branch now evaluates the same explicit q2
  (Q^{-1}\otimes\Sigma) penalty as C0-04. Dense objective, `rho = 0`,
  nonzero-correlation, and AD-gradient tests pass.
- Internal extraction reports the two named SDs and
  `cor(mu:(Intercept),mu:x | p | species)`.
- The retained three-attempt local fixture passes `PASS_POINT_RECOVERY_LOCAL`;
  its IID DGP control passes separately.
- Adaptive deviation: an invalid runner formula was caught before a model fit,
  preserved under `initial-runner-error/`, then corrected without changing the
  frozen seeds, DGP, or decision rule.

## Reconciliation

The implemented route is C0-07 only. No capability ledger/dashboard, public
API/default, profile, interval, bootstrap, coverage, remote-compute, Lane A,
Lane B, or C0-08–10 work occurred.
