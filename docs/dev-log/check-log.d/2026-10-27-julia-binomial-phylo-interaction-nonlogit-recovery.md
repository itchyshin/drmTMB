# Julia Binomial phylogenetic-interaction non-logit recovery

- Totoro Julia 1.10.12, one thread: `test/test_binomial_phylo_interaction_sd.jl` passed 47/47 assertions in 21.87 seconds. The probit and cloglog cases use their matching link in the synthetic DGP and check positive SD-slope recovery, pair-level SD prediction, and binary simulation.
- 107 project, manifest, source and test hashes matched the Totoro snapshot. Receipt: `docs/dev-log/evidence/general-sd-regression/julia-binomial-phylo-interaction-nonlogit-totoro-20261027/`.
- The generated universe remains 19,230 rows; two exact Julia non-logit interaction-intercept rows are now admitted. Universe tests passed 19/19.
- After-task report structure passed. Acceptance-gate state remains UNKNOWN because its runner is unavailable. Prose lint found zero issues; scoped diff check passed.
- Inventory search: `rg -n 'phylo_interaction|phylogenetic interaction|probit|cloglog' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/src/families.md`. It found the potentially stale logit-only sentence at Julia `NEWS.md:12`; that file has nine divergent refs, so the finding was sent to the docs-audit lane.
- No interval-coverage, native parity, or independent dense covariance-oracle claim.
