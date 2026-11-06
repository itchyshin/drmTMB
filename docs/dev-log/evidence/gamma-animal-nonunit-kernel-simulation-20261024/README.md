# Julia Gamma animal SD simulation with a non-unit kernel

This evidence records a focused marginal-simulation test for the Julia Gamma animal route with intercept and numeric-slope SD regressions. It checks that the supplied relationship matrix is used as the covariance kernel, including its non-unit diagonal.

The test fit one synthetic dataset through the R-to-Julia bridge and passed seven assertions. It verifies convergence, group order, target names, exact seeded draws against an independent R reconstruction using `t(chol(A))`, and repeatability at the same seed. The test does not estimate interval coverage or compare the non-unit-kernel fit against native TMB.

Run command and full console output are in `test-console.log`; exact source identities are in `source-manifest.md`.
