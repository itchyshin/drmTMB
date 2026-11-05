| Date | Slice | Evidence | Result | Owner |
|---|---|---|---|---|
| 2026-10-20 | Bernoulli SD formula design matrix | R testthat and DRModels.jl Julia test on independent synthetic group-level factor and numeric predictors; after-task structure check | R passed 4 expectations; Julia passed 5/5. Both preserve treatment coding and the factor-by-numeric interaction, compute group SDs as `exp(Z %*% alpha)`, and reject within-group factor variation. Report structure passed; the overall ledger remains open on programme gates. No fits or calibration runs. | Codex |
