# C2 spatial Poisson q2 local rerun receipt

This is the corrected retained receipt for exactly
`count ~ x + spatial(1 + x | p | site, coords = coords)` with ordinary
`poisson()`. It has three planned seeds (`2026072901:2026072903`), 64 sites,
eight observations per site, within-site centred predictor, true fixed effects
`(1.00, 0.35)`, latent SDs `(0.60, 0.50)`, and latent correlation `0.50`.
`raw-attempts.tsv` retains every fit; `iid-dgp-control.tsv` is not an estimator
attempt. PASS requires all three fits with convergence 0, `pdHess = TRUE`, no
boundary hit, fixed-effect mean error <= 0.20, SD relative error <= 40%, and
correlation mean error <= 0.25. This receipt passed. It is point-fit recovery
only: no profile, interval, coverage, or broader spatial grammar claim.

The prior sibling directory without `rerun-1` retains a DGP-stage runner error
and is intentionally not overwritten.
