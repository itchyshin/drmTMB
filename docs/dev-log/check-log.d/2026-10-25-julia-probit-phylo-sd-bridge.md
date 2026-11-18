## 2026-10-25 - Julia probit phylogenetic Bernoulli SD bridge

- Goal: Admit the exact probit phylogenetic-intercept SD route through the R-to-Julia bridge.
- Changes: Scoped non-logit admission in `R/julia-bridge.R`; added a gated synthetic TMB/Julia comparison and refusal checks in `tests/testthat/test-julia-binomial-phylo-sd.R`.
- Checks: Focused phylogenetic bridge tests passed with two live Julia fits; adjacent non-logit intercept/slope bridge tests completed without failures; the logit Bernoulli SD bridge suite completed without failures with five live fits; `git diff --check` passed.
- Capability-universe regression: `python3 tools/general-sd-regression/tests/test_universe.py` passed, 17 tests in 38.015 seconds. Its blocked probit rows match the frozen DRM.jl pin; the candidate route is newer than that baseline.
- Limits: A Totoro JuliaCall startup attempt segfaulted before fitting. The Mac run used Julia 1.10.0. Two logit-suite fits warned of a boundary or singular Hessian; no interval-calibration claim is made.
- Evidence: `docs/dev-log/after-task/2026-10-25-julia-probit-phylo-sd-bridge.md`.
- Next: Synchronize the Julia guide and NEWS, add a route-specific capability-ledger exception, then continue the Bernoulli matrix.
