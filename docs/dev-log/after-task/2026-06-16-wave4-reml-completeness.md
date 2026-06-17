# After-task — Wave 4: REML completeness

Date: 2026-06-16
Branch: `codex/honesty-guards`

## Why this wave

Base REML covered only the univariate Gaussian slice (ordinary `mu` random
effects, intercept-only `sigma`). Wave 4 extends it to the cases the
distributional/phylogenetic audience needs, each validated against an
independent restricted-likelihood reference. REML restricts the likelihood for
the mean fixed effects (TMB marginalises the `beta_mu*` blocks through the exact
Gaussian Laplace step); REML-on-scale is not a defined estimator, so the scale
side stays ML.

## Slices (each its own commit, each validated)

- **4.0 mean-side phylo** (`445d4634`). Relax the structured gate to allow a
  `phylo()` effect on `mu` (conservative: scale-side and non-phylo structured
  effects still rejected). Matches a hand-computed restricted Gaussian likelihood
  for the phylogenetic SD, residual `sigma`, and mean coefficients; REML SD
  >= ML SD (bias correction). Consolidates the earlier mean-phylo REML slice onto
  this branch.
- **4.1 heteroscedastic residual** (`eef270c9`). Remove the intercept-only-sigma
  gate: REML restricts the mean regardless of the scale model, and a Gaussian
  with `V = diag(sigma_i^2) + RE covariance` has an exact restricted likelihood.
  Matches a hand reference (RE SD, the `sigma` coefficients, mean coefficients);
  df counts the marginalised mean.
- **4.2 bivariate fixed-effect location** (`3f66a305`). Allow `biv_gaussian`
  under REML for fixed-effect `mu1`/`mu2`, marginalising `beta_mu1`/`beta_mu2`.
  With identical regressors GLS means = per-response OLS, so the REML residual
  covariance is exactly the OLS-residual cross-products over `n - p`; drmTMB
  matches this analytic reference (`sigma1`, `sigma2`, `rho12`, both mean blocks)
  to 1e-3.
- **4.3 bias simulation** (`6e7b7dbf`). A 40-replicate Monte Carlo replaces the
  single-seed inequality: the mean REML random-effect SD is larger than the mean
  ML SD and closer to the truth.

## Validation findings

- The bivariate validation surfaced (and resolved) a subtlety, not a bug:
  `fit$par$rho12` is the atanh-scale coefficient, so the response-scale
  correlation must be read via `rho12()`. And REML `rho12` == ML `rho12` because
  the `n - p` factor cancels in a correlation -- exactly as the analytic
  reference predicts. The early comparison used the wrong scale; once corrected,
  drmTMB matched the exact reference.
- A C2 follow-up (`34004cea`): the wave-level suite caught that C2 had dropped
  the `multistart` typo guard from the reserved control names; restored.

## Honesty / scope

- REML improves variance-component bias and convergence, NOT identifiability: a
  weakly identified block still needs the penalty MAP option or replication.
- Bivariate REML is scoped to fixed-effect means. Bivariate random-effect and
  structured (phylo) means -- the full Ayumi Model A+/D case -- are the next
  slice: they need a bivariate restricted-likelihood reference (a 2n-block
  phylo/RE covariance) to validate before they can be trusted, and that
  reference is the gating work, not the gate relaxation.
