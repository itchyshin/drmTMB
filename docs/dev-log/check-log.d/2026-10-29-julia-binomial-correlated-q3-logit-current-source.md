# Current-source Julia Binomial correlated q3 logit bridge

- Existing high-information q3 logit bridge test passed one live Julia test against current R/Julia source in 7:56, with no failures or skips. Checks include all three SD slopes, cross-engine coefficient/correlation agreement, group SD predictions, and marginal simulation.
- Added source-pinned recovery evidence for the intercept and two slope target rows. Evidence remains unreviewed and candidate-only.
- Evidence reconciliation passed: 20,350 candidate rows, 214 linked, 20,136 unlinked, and 241 records. No support promotion or coverage claim.
- An earlier smaller q3 attempt exceeded its four-minute estimate, was stopped before producing a result, and its test-source edit was reverted with the original hash restored.
- Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-correlated-q3-logit-current-source.md`.
