# Fixed-effect prior validation ledger

Reader: developers deciding what this first slice can claim. The goal is numerical correctness and usable coefficient selection. This ledger does not establish interval calibration, general R-Julia parity or full-posterior sampling.

| Claim | Evidence required | Current tier |
|---|---|---|
| Normal/ridge target, constants and derivatives on Gaussian mu/sigma and binomial-logit mu | Direct density and finite-difference tests in `tests/testthat/test-fixed-effect-priors.R`; Julia `test/test_fixed_priors.jl` | Passed on final optimized R source 64956560 and final Julia source a30e3472 |
| Conditional Gaussian ridge coefficients | Exact independent matrix solution, tolerance 1e-7 | Passed final-source independent matrix and derivative checks |
| Selection, intercept handling, zero ridge, factors and rank checks | Public resolver/fitter fixtures in `test-fixed-priors-workflow.R`; Julia public preview and factor tests | Passed final-source focused, affected-regression and live selector fixtures |
| Known Gaussian coefficients | One seeded Gaussian data-generating example and bounded coefficient error | Bounded regression evidence only; no recovery campaign |
| R-TMB versus R-to-Julia agreement | Five same-data fixtures: Gaussian mu/sigma, binomial partial prior, zero ridge, factor interaction and no-intercept factors | Passed on final R 64956560 and Julia a30e3472; maximum coefficient gap 4.30e-11 and data log-likelihood gap 1.07e-12 |
| Confidence intervals and posterior sampling | Separate scientific validation | Not admitted; active-prior interval methods refuse |
| Random-effect SD priors | Separate mathematical/API stage | Not implemented in this slice |

The cited Julia identifiers are aggregate source SHA-256 values, not Git commit IDs. Final receipts must name the source and compiler actually exercised. Earlier full-suite runs cannot be attributed to later guard or cache fixes.

Broad regression disposition: the R c53a0357 full run failed; introduced omissions were fixed and the affected modules passed on closeout source 64956560. Three remaining assertions reproduce exactly on optimized baseline 9fea303. The final Julia a30e3472 full run timed out after 90 minutes (exit 124), so full-suite success is not admitted. These broader results do not replace the source-pinned numerical, focused, affected and five paired checks above.
