---
title: "Lane C C1 NB2 phylo q2: plan versus actual"
date: 2026-07-28
lane: C
---

# Lane C C1 NB2 phylo q2 — plan versus actual

## Authorized target

One internal ordinary-NB2 route:

```r
count ~ x + phylo(1 + x | p | species, tree = tree)
```

The promised estimands were the two latent phylogenetic SDs and their latent
intercept--slope correlation; fixed-effect `sigma` remained distinct.

## Actual delivery

- The parser admits only the labelled NB2 phylogenetic `1 + x` route.
- The NB2 TMB branch now uses the joint q2 `Q`-precision penalty, including
  determinant normalization and cross-precision term; `rho = 0` reduces to
  the independent q-vector penalty.
- Internal extraction reports the two named SDs and
  `cor(mu:(Intercept),mu:x | p | species)`.
- Focused formula, dense-oracle, AD-gradient, zero-correlation, nonzero
  sentinel, extractor, and negative-route tests pass.
- The predeclared all-attempt local fixture is retained at
  `docs/dev-log/implementation-recovery/2026-07-28-lane-c-c1-nb2-phylo-q2-local/`;
  it returned `PASS_POINT_RECOVERY_LOCAL` for 3/3 retained attempts.

## Reconciliation

The work finished well below the 600-minute ceiling. It implements and
provides a local technical point-recovery receipt for C0-04 only. The other 39
intake rows remain deferred. No capability ledger, dashboard, public API,
defaults, profile, interval, bootstrap, coverage, remote-compute, Lane A
association, or Lane B scale/clamp work occurred.
