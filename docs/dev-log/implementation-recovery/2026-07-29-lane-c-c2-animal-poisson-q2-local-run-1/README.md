# C2 animal Poisson q2 local receipt

This retained receipt covers exactly
`count ~ x + animal(1 + x | p | site, Ainv = Ainv)` with ordinary `poisson()`
and a named supplied precision matrix. It has three planned seeds
(`2026072901:2026072903`), 64 levels, eight observations per level,
within-level centred predictor, true fixed effects `(1.00, 0.35)`, latent SDs
`(0.60, 0.50)`, and latent correlation `0.50`. `raw-attempts.tsv` retains every
fit; `iid-dgp-control.tsv` is not an estimator attempt. PASS requires all three
fits with convergence 0, `pdHess = TRUE`, no boundary hit, fixed-effect mean
error <= 0.20, SD relative error <= 40%, and correlation mean error <= 0.25.
This receipt passed. It is point-fit recovery only: no profile, interval,
coverage, pedigree/covariance alternative, or broader grammar claim.
