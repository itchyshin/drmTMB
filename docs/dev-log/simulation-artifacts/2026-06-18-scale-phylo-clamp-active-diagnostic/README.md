# Scale-Phylo Clamp-Active Diagnostic

This artifact is a narrow diagnostic for the `drmTMB#59` numerical-guard
sensitivity row. It asks whether an already fitted one-observation-per-tip
Gaussian scale-side phylogenetic model makes the `log(sigma)` guard and the
ordinary optimizer warnings visible. It does not test recovery, coverage,
power, or a recommended applied workflow.

The model uses `phylo(1 | species, tree = tree)` in both `mu` and `sigma`, with
one observation per tip. That is the weak-identification surface described in
`docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md`: the
scale-side phylogenetic random field can try to absorb single extreme
residuals. The runner compares three public control settings on the same data:
the default `log(sigma)` clamp, `logsigma_clamp = NULL`, and a wide
`logsigma_clamp = c(-25, 25)`.

The runner deliberately does not retry fits, force convergence, use fallback
optimizers, request `sdreport()`, profile intervals, bootstrap intervals, or
manual starts. It records warnings, optimizer status, fixed gradients, fitted
`log(sigma)` range, `check_drm()` rows, and session details.

## Outputs

- `scale-phylo-clamp-conditions.csv`: stress cells, clamp settings, seeds, and
  residual-shock magnitudes.
- `scale-phylo-clamp-fit-diagnostics.csv`: optimizer status, `log(sigma)`
  range, guard status, fixed gradients, objective, information criteria, and
  warning text.
- `scale-phylo-clamp-condition-summary.csv`: denominators for requested,
  attempted, fit-error, warning, convergence, Hessian, and `check_drm()`
  warning/error status.
- `scale-phylo-clamp-check-drm.csv`: full `check_drm()` rows for each fit.
- `scale-phylo-clamp-failures.csv`: unexpected fit errors, if any.
- `scale-phylo-clamp-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

The runner resolves the repository root from its own file path, so it can be
launched from outside the package working directory. The run summary and
session info record UTC timestamp, git SHA, branch, dirty state, command, and
data seed.

## Results

The diagnostic ran six requested fits: two residual-shock stresses crossed with
default, disabled, and wide `log(sigma)` clamp settings. There were no fit
errors. All six fits returned optimizer non-convergence with code 1
(`false convergence (8)`), all six had fixed-gradient warnings, and all six
emitted R warnings from the fit path. Because the runner used
`drm_control(se = FALSE)` to keep the stress artifact small, `sdreport()` and
positive-Hessian inference are intentionally absent.

The moderate-shock cell did not activate the upper clamp warning under any
setting. The extreme-shock cell with the default clamp reached
`log(sigma) = 13.93`, above the default identity-band upper bound of 12, and
`check_drm()` reported `logsigma_clamp_active = warning`. The same extreme
data with `logsigma_clamp = NULL` reached `log(sigma) = 14.288`, and the wide
band reached `log(sigma) = 14.288`; both still reported false convergence and
fixed-gradient warnings, but no clamp-active row because the default clamp was
not active in those control settings.

This is the intended diagnostic pattern. The default guard made an extreme
scale-side phylogenetic runaway visible, while the optimizer and fixed-gradient
rows still stopped the fit from looking inferentially clean.

## Boundaries

This artifact can show that a one-observation-per-tip scale-side phylogenetic
stress fit surfaces non-convergence, huge fixed gradients, fit-path warnings,
and one default upper-clamp warning through `check_drm()`.

It does not show scale-side phylogenetic recovery accuracy, interval coverage,
power, a valid applied scale-phylo workflow, q4/q8 covariance readiness,
bivariate scale-route readiness, Julia bridge parity, release readiness, CRAN
readiness, missing-data behavior, or non-Gaussian REML/AI-REML claims.
