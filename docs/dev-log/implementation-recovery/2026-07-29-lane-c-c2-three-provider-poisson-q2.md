---
title: "Lane C C2: three-provider Poisson q2 local recovery receipt"
date: 2026-07-29
status: PASS_POINT_RECOVERY_LOCAL
scope: "mc-0446 spatial, mc-0450 animal, mc-0454 relmat only"
---

# C2 three-provider Poisson q2 local recovery receipt

## Exact target

This receipt covers exactly ordinary univariate `poisson()` fits with a
labelled structured `mu` intercept--slope block:

```r
count ~ x + spatial(1 + x | p | site, coords = coords)
count ~ x + animal(1 + x | p | site, Ainv = Ainv)
count ~ x + relmat(1 + x | p | site, Q = Q)
```

The latent estimands are two provider-specific SDs and the intercept--slope
correlation `0.999999 * tanh(eta_cor_phylo)`. The three direct targets are
visible but use `profile_ready = FALSE` and
`profile_note = "point_fit_only_count_q2"`.

## Source and numerical contract

The implementation source is `ea147cd077a49b45d05e1304eb88bd7ef85d700e`, with
runner MD5 `ddbff7a177bd2b1916fb5cfceed11986`. The focused tests construct a
spatial precision directly from coordinates and supplied provider precision
matrices in fitted level order; they check dense objective equality, central-FD
against AD gradients, the exact `rho = 0` independent-q-vector reduction, and
a nonzero-correlation objective-dependency sentinel.

## Retained local attempts

| Provider | Receipt | Result |
|---|---|---|
| spatial | `2026-07-29-lane-c-c2-spatial-poisson-q2-local-rerun-1/` | 3/3 fit, convergence 0, `pdHess = TRUE`, no boundary hit; PASS |
| relmat | `2026-07-29-lane-c-c2-relmat-poisson-q2-local-run-1/` | 3/3 fit, convergence 0, `pdHess = TRUE`, no boundary hit; PASS |
| animal | `2026-07-29-lane-c-c2-animal-poisson-q2-local-run-1/` | 3/3 fit, convergence 0, `pdHess = TRUE`, no boundary hit; PASS |

Every passing receipt contains its three raw attempts, fixed seed, source SHA,
runner SHA, DGP digest, convergence, gradient, Hessian and boundary records,
plus a separate IID DGP control. The predeclared mean thresholds were fixed
effect error <= 0.20, SD relative error <= 40%, and correlation error <= 0.25;
all three passed.

## Retained runner correction

The first spatial invocation is retained at
`2026-07-29-lane-c-c2-spatial-poisson-q2-local/`. Its three attempts fail in
the DGP stage because the new independent spatial-precision helper assigned
two coordinate-column names to a 64-column precision matrix. Commit
`ea147cd07` corrects the dimnames and forces a new receipt directory, so the
successful rerun does not overwrite the defect. This was a fixture-construction
error before a model fit, not a failed recovery attempt or evidence for a
capability claim.

## Claim boundary

This is technical point-fit recovery only. It does not support profile or
other intervals, calibration, coverage, inference readiness, `supported`,
NB2 provider q2, q4+, scale-side random effects, zero inflation, bivariate
models, alternate precision representations, or any other formula form.
