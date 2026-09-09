# C1 independent dense marginal profile

This profile marginalizes the Gaussian random effects analytically through the block covariance `s_b^2 11^T + s_a^2 R(phi) + sigma^2 I`, profiles the three mean coefficients by GLS, and optimizes only the variance/persistence coordinates. It is independent of the latent-state TMB optimizer.

For each declared residual SD, four persistence starts are retained. The free-sigma table is diagnostic only. A finite-grid profile cannot establish a finite MLE at a variance boundary; it records whether the direct marginal likelihood keeps decreasing toward that boundary.
