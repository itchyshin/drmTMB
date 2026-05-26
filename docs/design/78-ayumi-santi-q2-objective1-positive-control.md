# Ayumi/Santi q2 Objective 1 Positive Control

Reader: Ayumi, Santi, and `drmTMB` contributors checking whether the Objective
1 q2 phylogenetic runner behaves sensibly before real data are available.

This is a small positive-control simulation, not a broad Monte Carlo study. It
uses the ADEMP structure from Morris, White, and Crowther (2019) and the
transparent simulation-reporting checklist from Williams et al. (2024) as a
compact guardrail.

## A: Aims

Primary aim: check that the developer runner for the Objective 1 q2
phylogenetic location model can recover the direction and approximate magnitude
of a known phylogenetic location-location correlation, while keeping residual
`rho12` separate.

Secondary aim: check that the runner writes the same diagnostics needed for
Santi's mammal and avian fits: convergence, `pdHess`, gradients, `corpairs()`,
`rho12()`, `sdpars`, `profile_targets()`, and `check_drm()` rows.

## D: Data-Generating Mechanism

The simulation creates one row per species:

```text
u = [u_1, u_2] ~ matrix normal(0, A, Sigma_phylo)
e_i = [e_i1, e_i2] ~ normal(0, Sigma_residual)
y_i = alpha + u_i + e_i
```

`A` is the phylogenetic correlation matrix from a simulated ultrametric tree.
`Sigma_phylo` contains the trait-specific phylogenetic SDs and the
phylogenetic `mu1`-`mu2` correlation. `Sigma_residual` contains `sigma1`,
`sigma2`, and residual `rho12`.

The default positive-control cell uses 220 species, phylogenetic correlation
`-0.55`, residual `rho12 = 0.15`, phylogenetic SDs `1.20` and `1.00`, and
residual SDs `0.25` and `0.25`. This is deliberately a strong-signal cell; it
tests the runner and extractor path before real one-row-per-species datasets
add weaker information and tree uncertainty.

## E: Estimands

The true estimands are:

- phylogenetic location-location correlation;
- residual `rho12`;
- phylogenetic SD for response 1;
- phylogenetic SD for response 2.

The estimator outputs are the matching `corpairs(level = "phylogenetic")`,
`rho12()`, and `sdpars` rows written by
`tools/ayumi-santi-q2-objective1-runner.R`.

## M: Methods

The only fitted method is the `drmTMB` bivariate Gaussian q2 phylogenetic
location model:

```r
bf(
  mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
  mu2 = log_reproductive_output ~ 1 + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1
)
```

The script `tools/ayumi-santi-q2-positive-control.R` simulates data and calls
the shared Objective 1 runner. The runner is the unit under test, so the
positive control uses the same CLI surface as the future Santi and Ayumi
prepared-data runs.

## P: Performance Measures

This smoke reports absolute error for the four estimands, plus convergence,
`pdHess`, maximum absolute gradient, and `check_drm()` rows. It does not report
Monte Carlo standard errors because it is one positive-control replicate, not a
replicated simulation grid.

The current run wrote:

```text
phylo_mu1_mu2_cor: truth -0.55, estimate -0.673, abs_error 0.123
residual_rho12:    truth  0.15, estimate  0.177, abs_error 0.027
sd_phylo_mu1:      truth  1.20, estimate  1.277, abs_error 0.077
sd_phylo_mu2:      truth  1.00, estimate  0.926, abs_error 0.074
```

The fit converged with code 0, `pdHess = TRUE`, maximum absolute gradient
`5.91e-05`, finite fixed-effect standard errors, and no boundary warnings.
`check_drm()` still notes the one-row-per-species structure, which is expected
for species-level protocol data and should remain visible in applied reports.

## Williams Checklist

| Item | Status in this smoke |
| --- | --- |
| 1. Aim | Stated above as a runner positive control. |
| 2. Data-generating mechanism | Stated above with tree, phylogenetic covariance, residual covariance, and defaults. |
| 3. Estimands | Four truth-versus-estimate targets are written to `truth-vs-estimate.csv`. |
| 4. Methods | One `drmTMB` q2 Objective 1 method, matching the protocol runner. |
| 5. Performance measures | Absolute error plus convergence, Hessian, gradient, and diagnostics. |
| 6. Software details | The runner saves `fit.rds`; session information is not yet saved for this smoke. |
| 7. Code availability | Code lives in `tools/ayumi-santi-q2-positive-control.R`. |
| 8. Data availability | Simulated data, tree, and truth are written under `docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/`. |
| 9. Applied case study | Not covered; real Ayumi/Santi data are deliberately not used here. |
| 10. Simulation results | One-replicate positive-control results are recorded, including diagnostics. |
| 11. Monte Carlo uncertainty | Not applicable to this one-replicate smoke; a later grid should add MCSE columns. |

## Next Use

Run this smoke whenever the q2 Objective 1 runner or bivariate phylogenetic
extractors change. Then run the same runner on Santi's prepared mammal and
avian Objective 1 datasets with `--dry-run true` before fitting representative
trees.
