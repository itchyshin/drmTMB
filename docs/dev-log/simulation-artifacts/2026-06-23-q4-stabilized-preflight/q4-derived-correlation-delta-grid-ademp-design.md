# Q4 Derived-Correlation Delta Grid ADEMP Design

This r53 design follows the ADEMP structure of Morris, White, and Crowther
(2019) and the transparent-reporting discipline of Williams et al. (2024). It
is a dry-run contract for the next q4 derived-correlation delta grid, not a
coverage result.

## A - Aims

Primary aim: evaluate whether finite-difference Wald delta intervals for the
six q4 phylogenetic derived correlations have acceptable diagnostic coverage
under the stabilized exact-Gaussian location-scale fixture.

Secondary aim: quantify fit failures, nonconvergence, `pdHess = FALSE` rows,
warnings, unavailable intervals, and boundary-clamped intervals without dropping
any seed-scale-target row from the denominator.

## D - Data-Generating Mechanism

The DGP is the stabilized q4 Gaussian phylo fixture used by r51 and r52. Each
replicate has 32 species, eight observations per species, two responses, two
location predictors, two scale predictors, a residual `rho12 = 0.10`, and a
four-axis phylogenetic random effect on `mu1`, `mu2`, `sigma1`, and `sigma2`.

The true phylogenetic standard deviations are 0.90 for `mu1`, 0.80 for `mu2`,
and either 0.35 or 0.50 for both scale axes. The true among-axis correlation is
0.05 for every off-diagonal pair. The planned grid uses 500 replicate seeds per
scale level, starting at seed 202607500, for 1000 seed-scale cells and 6000
derived-correlation target rows.

## E - Estimands

The six estimands are `cor_mu1_mu2`, `cor_mu1_sigma1`, `cor_mu1_sigma2`,
`cor_mu2_sigma1`, `cor_mu2_sigma2`, and `cor_sigma1_sigma2`. The true value is
0.05 for every target in every replicate.

Each fitted row must store the `corpairs(level = "phylogenetic")` estimate, the
`phylo_q4_corr` report reconstruction, the finite-difference delta standard
error, lower and upper endpoints when available, boundary-clamp status,
coverage indicator, warning context, and failure reason.

## M - Methods

The first calibrated run is native R/TMB exact-Gaussian ML for the q4
phylogenetic location-scale model. Direct DRM.jl and R-via-Julia bridge interval
routes remain separate until they have route-specific reconstruction and
denominator evidence.

The interval method for this contract is `wald_delta_finite_difference` using
the `theta_phylo` covariance block and full-vector `phylo_q4_corr` report
reconstruction. Profile and bootstrap intervals remain separate evidence
classes.

## P - Performance Measures

For each target and scale level, report coverage, finite-interval rate, failure
rate, warning rate, boundary-clamped rate, and wall time. Every proportion must
include MCSE and the denominator used.

For nominal 0.95 coverage and 500 replicates, the planned coverage MCSE is
`sqrt(0.95 * 0.05 / 500) = 0.009747`, which clears the 0.01 threshold. The
reference failure-rate MCSE at 0.05 is also 0.009747; observed failure-rate MCSE
must be reported from the realized failure rate.

## Williams-Style Self-Audit

| Item | r53 Coverage |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Hierarchy, random effects, scale levels, and replicate count are specified. |
| 3. Estimands | Six derived-correlation targets and true values are named. |
| 4. Methods | Native R/TMB exact-Gaussian ML and finite-difference delta intervals are named. |
| 5. Performance measures | Coverage, finite-interval, failure, warning, boundary-clamp, and timing measures are required. |
| 6. Software details | The future run must record package versions and session information next to outputs. |
| 7. Code availability | The dry-run script and validator-owned dashboard artifacts live in this repository. |
| 8. Data availability | All simulated inputs are generated from recorded seeds and fixture code. |
| 9. Applied case link | Not applicable to this local SR150 calibration gate. |
| 10. Results reporting | The future report must keep all failed, unavailable, warning, clamped, and finite rows in denominators. |
| 11. MCSE | Coverage and failure-rate MCSE fields are required before any coverage wording. |
