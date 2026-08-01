# Lane C Z7 — corrected zero-one-beta sigma spatial q1 recovery

```r
bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1)
```

This run corrects the prior fixture’s DGP order: the Gaussian spatial draw is
named by `rownames(coords)` before being matched to `site`. Its only estimand
is \(\tau_\sigma=\exp(\ell_\sigma)\). At source
`27d7ab86de50ecd040b4126374f2273b2b4353cd` and runner MD5
`ecc4b3a6a63385de499627ae6d9461f7`, all four retained attempts pass: mean SD
relative error 0.21509, gradients <= 0.00798, `pdHess = TRUE`, no clamp or
boundary flags, and mode correlations 0.948--0.974. The independent oracle
separately constructs the coordinates-derived precision and full mixture.

The retained run-1 artifact is invalid-runner evidence only. This run does NOT
cover mesh/range estimation, slopes, labels, other providers/dpars, profiles,
intervals, bootstrap, coverage, or inference readiness.
