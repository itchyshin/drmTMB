# Beta pedigree two-field SD contract

Owner: bounded native SD worker; source candidate codex/general-sd-regression, HEAD 425bee81572c625a634b2b083050c5c57c1dc1f1. Parent delegates R/drmTMB.R and will not edit concurrently.

For each independent coefficient k, u_k ~ N(0,A), b_gk = exp(W_gk alpha_k) u_gk. The observation predictor is X beta + b_g0 + x b_g1. A is computed independently by pedigree recursion: A_ij = (A_sire,j + A_dam,j)/2; A_ii = 1 + A_sire,dam/2, with missing parents contributing zero. Unobserved founders retain Gaussian latent values but have no observed SD design. Scaled founder extraction must be NA. Integration over founders gives observed covariance A[observed,observed], whose inverse is used by the independent dense Beta oracle, never a submatrix of full precision. Beta mean adjustment and phi=sigma^-2 remain unchanged.

Acceptance: pedigree/A/Ainv log-likelihood and SD coefficients agree within 1e-4; absolute dense Laplace objective and eta within 1e-4; analytic score/Hessian finite-difference checks as prior slice; named offspring predictions and ancestor extraction preserved. One seed 2026102707, 16 families x 4 offspring x 20 repeats. Log-SD truth .5,-.5; point recovery error <.4. No coverage claim. Initial test budget 90 seconds; neighbor regression 180 seconds. No native rebuild expected. Stop on budget overrun or unexplained numerical mismatch.
