# Arc 6.8 contract: cross-pair integration gate

Arc 6.8 is a source-level integration gate for the five separately admitted
post-fit latent-normal pair classes: Gaussian × literal-Bernoulli, Gaussian ×
ordinary NB2, literal-Bernoulli × literal-Bernoulli, literal-Bernoulli ×
ordinary NB2, and ordinary-NB2 × ordinary-NB2. It adds no likelihood, family,
parameter, or capability tier.

For each pair class, the matrix constructs two fixed-effect ML margins on the
same complete rows, calls `associate_pairs(..., kernel = latent_normal(),
association = ~1)`, and checks both input orders. It verifies that the stored
margin snapshots match the standalone fits, the log likelihood and latent
association `eta` are symmetric under pair order, response-scale `fitted()`
and frozen-row `predict()` retain input response names, and seeded joint
simulation is deterministic. The shared unsupported-method fences reject
`rho12()`, `vcov()`, and new-data prediction for every latent-normal object.

The integration matrix also checks that exact-special models remain separate:
`biv_lognormal()` retains its own rowwise `rho12` meaning and does not acquire
the post-fit `association()` extractor. Thus the common object contract does
not collapse `eta` into residual correlation.

This gate does NOT overturn Arc 6.5's all-attempt recovery HOLD. It is not
recovery, interval, coverage, uncertainty, random-effect, association-slope,
missingness, weighting, offset, REML, Julia, CRAN, generic discrete-pair, or
direct-kernel evidence.
