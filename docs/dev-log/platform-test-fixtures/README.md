# Platform test fixture repairs

The main platform failures tracked by #1521 exposed two unsupported test assumptions and one missing diagnostic. Runtime code and numerical tolerances are unchanged.

## Provenance

The Hessian-row-only assertion comes from f5cc6da165490e64a2d952aec57db39200c2b64b on the existing #1509 lane. The count pilot failure-row diagnostic comes from a6a3233077f4c513e191cf737ef9cc15703f7dc4 on the existing #1514 lane. Both changes are confined to their test hunks; no other lane code was copied.

## Objective fixture model

For tip g, the four endpoint effects are the rows of U = L_A Z L_S^T, where Z has independent standard normal entries, A is the tree correlation matrix, and S = D C D. D has diagonal (0.7, 0.6, 0.45, 0.4); C has unit diagonal and off-diagonal 0.15. There are 36 tips and 12 observations per tip. Sister tips share a 0.2 branch and have unit pendant branches, giving sister-tip correlation 1/6. The tree's raw covariance is 1.2 A; its fitted endpoint standard deviations absorb that scalar.

The observation equations are y1 = 0.4 + 0.3 x + U[g,1] + exp(-0.3 + U[g,3]) e1 and y2 = -0.2 + 0.2 x + U[g,2] + exp(-0.1 + U[g,4]) e2. The residual pair e has unit variances and correlation 0.25. This matches two location equations, two log-scale equations, a dense four-endpoint phylogenetic covariance block, and a constant residual correlation in the fitted formula. REML remains enabled.

The generator tests objective mapping at fitted values, not recovery of the generating coefficients. The previous fixture had independent response noise with no generated group signals. Locally its fitted raw Cholesky parameters reached 223, 201 and -257; it reported false convergence and a nonpositive Hessian. A new explicit convergence assertion fails on that old fixture, as retained in objective-premise-red.log. The replacement probe converged with a positive Hessian in 1.206 seconds and maximum gradient 1.47e-9. Its objective anchor difference was zero.

## Bounds

The unchanged anchor tolerance is 1e-8. Convergence and positive-definite Hessian assertions are now explicit; warnings are no longer hidden for this fixture. The conditioning test grades its Hessian rows while allowing the separate, correctly warned design rank deficiency. The pilot still requires zero failures, now with the cell, severity and warning text printed when it fails.

This does not resolve the unidentified Windows pilot warning, prove every covariance label independently, establish parameter recovery, or change an inference claim. The parent task verifies the next Windows run and handles merge.
