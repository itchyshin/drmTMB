# 2026-10-29: Julia Binomial animal q2 pedigree bridge

- The focused live R-to-Julia test passed on Julia 1.10.0 for logit, probit, and cloglog. It compares the exact observed-animal covariance payload, native and Julia fits, both coefficient-specific SD outputs, and marginal binary simulation.
- The fixed-seed DGP used 72 related offspring from 12 sire/dam pairs, 32 observations per animal, one numeric slope, and separate group-level SD predictors for the intercept and slope.
- This is candidate-level point-recovery and workflow evidence. No source change was needed, no capability row was promoted, and no interval-calibration or coverage claim is made. The public capability wording remains with the documentation audit lane.
- Receipt and source hashes: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-pedigree-bridge-20261029/`. Full report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-q2-pedigree-bridge.md`.
