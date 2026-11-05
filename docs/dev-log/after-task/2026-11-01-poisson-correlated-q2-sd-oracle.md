# After Task: Tight Laplace oracle for the Poisson correlated q2 SD route

## Goal
The existing Poisson correlated q2 SD test compares the fitted log-likelihood with a Gauss-Hermite integral at tolerance 0.5. That is loose enough to hide a misaligned or swapped SD. This slice adds a tight, independent check without editing the old test.

## What was added
`tests/testthat/test-poisson-correlated-q2-sd-oracle.R` holds a dense Laplace oracle that does not call drmTMB. For each group it uses q = 2 random effects, a damped Newton search on the joint log-density with the exact Hessian, and the Laplace formula joint(b*) - 0.5 log det Sigma - 0.5 log det H. It is evaluated at the fitted fixed effects, fitted correlation and the fitted per-group SDs from predict(). The tolerance was fixed at 1e-4 absolute before the first run. Two seeds are used (20261027 and 20261101), with the intercept SD depending on w and the slope SD on v.

## Results
Fitted logLik minus oracle was 6.3e-9 (seed 20261027) and 9.7e-9 (seed 20261101). Emulated bugs moved the oracle by: swapped SD formulas -72.1 and -58.1; rho sign flip -8.2 and -16.0; one-level misalignment -32.2 and -11.1. All exceed 1, and the test asserts this.

## Checks run
`Rscript batch6-run.R test-poisson-correlated-q2-sd-oracle.R`: pass=14 fail=0 err=0 skip=0.

## Not covered
Only likelihood evaluation at fitted parameters, for native TMB Poisson, one unlabelled q2 block, complete data. Not covered: recovery or calibration, intervals, gradient or optimum agreement, q3 or labelled blocks, zero inflation, structured providers, Julia. The fitted optimum is not shown to maximise the oracle. The old test is unchanged.
