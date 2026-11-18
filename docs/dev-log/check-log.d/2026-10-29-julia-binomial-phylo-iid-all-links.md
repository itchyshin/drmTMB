# 2026-10-29: Julia Binomial phylogenetic plus IID bridge across links

- The focused live R-to-Julia test passed on Julia 1.10.0 for logit, probit, and cloglog. It checks convergence, target labels, positive SD-slope estimates, group-SD prediction agreement, likelihood agreement, and marginal simulation.
- No model source change was needed; this extends the existing route's test and evidence to logit. The slope checks are directional and broad-bound, so the evidence grade remains `focused_test`.
- The evidence reconciler passed with 20,350 candidate rows, 208 linked rows, and 235 evidence records. New records remain unreviewed; no capability status changed.
- Coverage validation and broad Julia parity remain open. Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-phylo-iid-all-links.md`.
