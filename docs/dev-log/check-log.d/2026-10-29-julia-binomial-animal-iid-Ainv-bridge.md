# Julia Binomial animal Ainv plus IID evidence

- Reran the existing source-pinned logit animal-plus-IID test with live Julia enabled. It passed one live bridge test with no failures or skips, including Ainv and equivalent A fits, a dense Laplace oracle, output comparisons, and marginal simulation.
- Added focused-test evidence for the exact Julia `animal:Ainv_precision + group_factor` required row. Evidence remains unreviewed and candidate-only.
- Reconciliation passed: 20,350 candidate rows, 211 linked, 20,139 unlinked, and 238 evidence records. No status promotion or interval coverage claim.
- Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-iid-Ainv-bridge.md`.
