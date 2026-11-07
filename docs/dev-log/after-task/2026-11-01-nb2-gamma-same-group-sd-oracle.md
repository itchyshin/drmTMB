# After-task note: NB2 and Gamma same-group SD oracle

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression.

## What was added

One new file, tests/testthat/test-nbinom2-gamma-same-group-sd-oracle.R. It
fits y ~ x + (1 | id) + (0 + x | id) with sd(id, coef = "(Intercept)") ~ w1 and
sd(id, coef = "x") ~ w2 for NB2 and Gamma(log), then compares logLik(fit) with
an oracle written without drmTMB internals: per group, a dense Laplace
marginal (damped Newton for the conditional mode, observed information in log
mu, q = 2, independent normal latent effects). The two SD formulas use
different group-level predictors (w1, w2) and clearly different true
coefficients (intercept SD: log 0.55 and +0.8; slope SD: log 0.30 and -0.9).

## Tolerances (fixed before the first run)

Oracle versus logLik: absolute 1e-4. Each emulated bug must move the oracle by
more than 1 log-likelihood unit. No existing test or tolerance was changed.

## Evidence (scratch script, run once)

Scratch script: /private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/5434bfd0-269b-4d99-8fb2-7a44f4f856d9/scratchpad/run-oracle.R

Gap |logLik(fit) - oracle| at the fitted parameters:

| mode | NB2 | Gamma |
|---|---|---|
| correct | 5.6e-12 | 1.8e-11 |
| swapped SD formulas | 142.3 | 533.1 |
| swapped predictors | 107.3 | 226.2 |
| level misalignment (SDs shifted one group) | 106.7 | 150.3 |

The test file passes: 10 expectations, 0 failures, 0 skips, 0 errors (2 tests).

## Not covered

This pins the likelihood assembly at the fitted point only. It does not test
the optimiser, standard errors, recovery, calibration or parity with any other
engine. The Laplace oracle matches the same approximation drmTMB uses, so it
says nothing about Laplace accuracy against the exact marginal. The NB2 slope
SD intercept fitted at about -3.99 (slope variance barely identified in this
fixture); the oracle comparison is still exact, but the fit is not a recovery
check. Only a single fixture and seed per family; the regression file's
coarse recovery and nesting checks are unchanged.
