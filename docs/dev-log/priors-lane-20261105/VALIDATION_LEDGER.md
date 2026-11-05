# Fixed-effect prior validation ledger

Reader: developers deciding what this first slice can claim. The goal is numerical correctness and usable coefficient selection. This ledger does not establish interval calibration, general R-Julia parity or full-posterior sampling.

| Claim | Evidence required | Current tier |
|---|---|---|
| Normal/ridge target, constants and derivatives on Gaussian mu/sigma and binomial-logit mu | Direct density and finite-difference tests in `tests/testthat/test-fixed-effect-priors.R`; Julia `test/test_fixed_priors.jl` | Validated on named predecessor fixtures; final optimized R rerun pending |
| Conditional Gaussian ridge coefficients | Exact independent matrix solution, tolerance 1e-7 | Passed bounded predecessor fixtures; final rerun pending |
| Selection, intercept handling, zero ridge, factors and rank checks | Public resolver/fitter fixtures in `test-fixed-priors-workflow.R`; Julia public preview and factor tests | Experimental until final-source checks finish |
| Known Gaussian coefficients | One seeded Gaussian data-generating example and bounded coefficient error | Bounded regression evidence only; no recovery campaign |
| R-TMB versus R-to-Julia agreement | Same-data Gaussian mu/sigma, binomial partial prior and Gaussian zero-ridge bridge fixtures | Passed on Julia aggregate source SHA-256 22ab4049778f7888f24509b3668adf3d50341178245e37786211015ba632dd00; final source rerun pending |
| Confidence intervals and posterior sampling | Separate scientific validation | Not admitted; active-prior interval methods refuse |
| Random-effect SD priors | Separate mathematical/API stage | Not implemented in this slice |

The cited Julia identifiers are aggregate source SHA-256 values, not Git commit IDs. Final receipts must name the source and compiler actually exercised. Earlier full-suite runs cannot be attributed to later guard or cache fixes.
