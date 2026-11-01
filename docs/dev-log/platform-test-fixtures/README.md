# Platform test fixture repairs

The main platform failures tracked by #1521 exposed two unsupported test assumptions and one missing diagnostic. The test repairs retain numerical tolerances. A subsequent runtime fix explicitly names the existing mean interpolation rule for tied profile objective values.

## Provenance

The Hessian-row-only assertion comes from f5cc6da165490e64a2d952aec57db39200c2b64b on the existing #1509 lane. The count pilot failure-row diagnostic comes from a6a3233077f4c513e191cf737ef9cc15703f7dc4 on the existing #1514 lane. Both changes are confined to their test hunks; no other lane code was copied.

## Objective fixture model

For tip g, the four endpoint effects are the rows of U = L_A Z L_S^T, where Z has independent standard normal entries, A is the tree correlation matrix, and S = D C D. D has diagonal (0.7, 0.6, 0.45, 0.4); C has unit diagonal and off-diagonal 0.15. There are 36 tips and 12 observations per tip. Sister tips share a 0.2 branch and have unit pendant branches, giving sister-tip correlation 1/6. The tree's raw covariance is 1.2 A; drmTMB divides by the tree height 1.2, so its fitted tree correlation equals A.

The observation equations are y1 = 0.4 + 0.3 x + U[g,1] + exp(-0.3 + U[g,3]) e1 and y2 = -0.2 + 0.2 x + U[g,2] + exp(-0.1 + U[g,4]) e2. The residual pair e has unit variances and correlation 0.25. This matches two location equations, two log-scale equations, a dense four-endpoint phylogenetic covariance block, and a constant residual correlation in the fitted formula. REML remains enabled.

The generator tests objective mapping at fitted values, not recovery of the generating coefficients. The previous fixture had independent response noise with no generated group signals. Locally its fitted raw Cholesky parameters reached 223, 201 and -257; it reported false convergence and a nonpositive Hessian. A new explicit convergence assertion fails on that old fixture, as retained in objective-premise-red.log. The replacement probe converged with a positive Hessian in 1.206 seconds and maximum gradient 1.47e-9. Its objective anchor difference was zero.

## Bounds

The unchanged anchor tolerance is 1e-8. Convergence and positive-definite Hessian assertions are now explicit; warnings are no longer hidden for this fixture. The conditioning test grades its Hessian rows while allowing the separate, correctly warned design rank deficiency. The pilot still requires zero failures, now with the cell, severity and warning text printed when it fails.

This does not resolve the unidentified Windows pilot warning, prove every covariance label independently, establish parameter recovery, or change an inference claim. The parent task verifies the next Windows run and handles merge.

## Windows pilot warning root cause and fix

The first full repair matrix passed Linux and macOS and confirmed that the generated q4 objective fixture passes Windows. The remaining Windows failure was poisson_mu_random_effect_001/warning: collapsing to unique 'x' values. All manifest rows were ok.

The shared profile interval wrapper delegated to TMB 1.9.21's confint.tmbprofile method. That method inverts each side by interpolating parameter coordinates against objective values. Its implicit stats::approx default averages tied coordinates, and R warns when that implicit choice is needed. The new wrapper independently performs the same inversion with explicit ties = mean. It preserves the first-minimum split, excludes the minimum from the right side, uses the same chi-squared cutoff, and returns NA outside the sampled range. Non-tmbprofile dispatch and the existing error wrapper remain intact.

The deterministic duplicate-objective fixture failed before the change because of the warning. Pure regression tests compare exact numerical results with TMB for unique points, duplicate points on both sides, repeated minima and outside-range thresholds. An analytic example checks the mean aggregation separately. Existing profile caller paths all use this wrapper; no other interpolation call exists in R/profile.R. Independent review checked the installed TMB convention and independently reproduced exact equality on the repeated-minimum fixture. The compatibility tests intentionally allow upstream TMB to fix its own warning later.

After the final R/profile.R change, the unchanged native/bridge/direct public parity runner was genuinely rerun with pinned DRM.jl da8b3f871 and Julia 1.13.0. It passed all eight checks in 51.75 seconds. The preceding source-specific receipt remains archived verbatim. This rerun refreshes source binding without extending the existing parity claim.
