# Lane C Z4b — zero-one-beta coi q1 local recovery blocker

Source commit: `1c2b68870243fc50c2e250a774ee236207b565c0`.

Target: `bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))` under ML
`zero_one_beta()`. The estimand is the latent ordinary conditional-one SD on
the logit-`coi` scale. It is separate from the zoi atom effect.

The fixed four-seed local fixture uses 32 groups x 50 observations, true SD
0.45, and rejects a DGP draw unless every group has at least two observed zeros
and two observed ones. Its frozen pass rule requires all four fits to converge
with `pdHess`, maximum gradient <= 0.01, an interior SD, inactive clamp,
conditional-mode correlation > 0.45, and mean SD relative error <= 40%.

Result: **BLOCKED_LOCAL_FIXTURE**. Seeds 3601, 3602, and 3604 pass; seed 3603
has `tau_hat = 0.0002166`, so it hits the predeclared lower-boundary rule even
though its convergence, Hessian, gradient, and mode-correlation diagnostics are
otherwise acceptable. `raw-attempts.tsv` retains every attempt and
`fixed-coi-boundary-diagnostic.tsv` is diagnostic-only. This is neither
interval nor coverage evidence, and it does not change the capability ledger.
