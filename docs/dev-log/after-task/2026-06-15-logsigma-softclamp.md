# After Task: Gaussian log-sigma Soft-Clamp (numerical guard, #570/#555)

## Goal

Stop the catastrophic numerical blow-up of the Gaussian location-scale
PHYLOGENETIC model when a scale-side phylogenetic field is fit with (near) one
observation per group, so the fit returns a finite, assessable result instead of
`logLik = -499,839` / NaNs / "false convergence (8)". This is a numerical guard,
NOT a fix for the underlying statistical degeneracy.

## Root cause (Gauss review role; full detail in design doc 170)

Ayumi's beak data has one observation per tip, so a phylogenetic GMRF on
`log_sigma` estimates a per-tip scale effect from a single residual (a structural
near-degeneracy). With the unbounded log link on `sigma`, heavy-tailed residuals
(max standardized residual 22.6) make the inner Newton step overshoot
`log_sigma` to about +26 (`sigma` about 1.9e11); the inner Laplace Hessian over
the ~41,756 random effects becomes indefinite and the inner solve diverges. The
no-sigma-phylo model uses the identical phylogenetic precision and converges, so
branch-length conditioning is ruled out.

## Implemented

- `src/drmTMB.cpp`: a numerically stable, AD-safe `drm_softplus()` and a smooth
  two-sided `drm_softclamp_log_sigma(v, lo, hi)`; applied to `log_sigma` before
  `exp()` in the univariate Gaussian density (model_type 1) and to `log_sigma1`,
  `log_sigma2` in the main bivariate Gaussian density (the structured q4
  "Model E" path). Band `[-12, 12]` (so `sigma` in roughly `[6e-6, 1.6e5]`).
- `docs/design/03-likelihoods.md`: documents the guard under "Implemented
  Gaussian Location-Scale".
- `docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md`: the full
  diagnosis, remedy, band trade-off, and the necessary-but-not-sufficient caveat.
- `tests/testthat/test-logsigma-clamp.R`: fidelity (clamp inactive for a
  well-posed fit) + guard (a pathological scale-phylo fit stays finite).

## Mathematical Contract

This is formally a likelihood change: a smooth truncation of the Gaussian scale
in the extreme tails. It is consistent with the package's existing numerical
guards (the beta / zero-one-beta `1e-8` shape floors and the `0.99999999`
correlation bounds). Public terms `sigma`, `rho12`, `mu` are unchanged. The band
`[-12, 12]` is the single reviewable constant.

## Validation (real data)

- Smoke well-posed Gaussian location-scale fit: `convergence = 0`, clamp
  inactive (fitted `log_sigma` strictly inside the band).
- Full 10,440-tip beak culmen sigma-phylo (the catastrophic case), final
  identity-in-band clamp: `logLik -499,839 -> -12,673` (finite), `sd_phylo`
  (0.33, 0.29), `max|grad| 881,785 -> 1,587`, elapsed ~935 s. The fit is now
  FINITE and assessable, but still `convergence = 1` with the lower bound binding
  (`log_sigma -> -14.96`; floor -15) -- the honest signal that a per-tip scale
  field with one observation per tip is weakly identified. The clamp removes the
  overflow; it does not manufacture identifiability. (The well-posed smoke fit is
  unchanged: `logLik -72.57`, clamp inactive.)

## Honest Boundary

- Necessary but NOT sufficient. The clamp does not make the degenerate model
  converge cleanly; it makes it finite and honestly flaggable. The real
  recommendation is Model A (phylogeny on the mean only, fixed-effect scale) or
  multiple observations per group. (Curie's q4 validation showed a separable
  "Model D" also fails for the full sigma specification at pruned sizes -- the
  scale-side phylo SD hits its boundary regardless of block structure -- so the
  fix is to drop the scale-side phylo field, not to separate it.) This is stated
  in doc 03 and doc 170.
- The band is a guard, not a regularizer: `[-12, 12]` is wide enough never to
  bind for a well-posed fit, so a binding clamp is itself a degeneracy signal.

## Checks Run

```sh
Rscript /tmp/drmtmb-clamp-validate.R           # compile + smoke + real beak
Rscript -e "devtools::test(reporter='summary')" # full suite, no-regression gate
git diff --check
```

## What Did Not Go Smoothly

- The first naive softplus would overflow under AD `CondExp` (both branches
  evaluate); rewritten as the stable `max(z,0) + log1p(exp(-|z|))` form.
- A wider band `[-12, 12]` gives a less "healthy"-looking beak objective than
  Gauss's `[-7, 7]` because the tighter band silently regularizes the
  degeneracy; the wider band is preferred precisely because it is an honest
  overflow guard rather than a hidden regularizer.

## Known Limitations / Next Actions

- The probe-variant Gaussian density paths (model_type 95/96, the combined
  covariance-probe models) are not yet clamped; extend for consistency once the
  approach/band are approved.
- Pair with the honest convergence-diagnostic slice (`check_drm` guidance for the
  scale-side phylo SD hitting its boundary) and documentation of Model A
  (phylogeny on the mean, fixed-effect scale) as the tractable q4 path.
- This is a likelihood guard delivered as a draft PR for maintainer review; the
  band and the formal likelihood change are the maintainer's decision.
