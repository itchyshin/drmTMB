# General latent-normal association sandwich: plan versus actual

The owner approved only private implementation, documentation, and deterministic
tests after the narrow Bernoulli × ordinary-NB2 reference merged through PR
#844. The planned result was a common two-stage assembler plus five explicit
adapters, with public inference, full-refit comparisons, simulations, and
compute deferred.

Actual work matched that boundary. The existing reference was factored through
the shared assembler; Gaussian × Bernoulli, Gaussian × ordinary-NB2, Bernoulli
× Bernoulli, and ordinary-NB2 × ordinary-NB2 adapters were added; and an
unexported router selects only those five classes. Deterministic tests cover
the independent row oracles, analytic margin blocks, eta signs and zero
factorization, order/side labels, tails, provenance, unavailable paths, and
the real router. The reference adapter gained the full frozen-provenance gate
after the initial Rose review identified that its numerical regression test had
not yet preserved the shared contract.

No divergence authorized a broader claim: there is no public covariance or
interval interface, no full-refit comparator, no simulation/recovery/coverage
evidence, no Totoro/DRAC job, no capability promotion, and no direct-rho12
work. The final disposition is **private implementation frozen pending final
review**, not validated inference.
