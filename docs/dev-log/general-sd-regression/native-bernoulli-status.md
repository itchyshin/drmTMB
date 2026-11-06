# Native Bernoulli SD-regression status

Date: 2026-10-17  
Status: the first native scalar-intercept slice passes 117 compiled assertions and a six-seed feasibility pilot. Programme-wide capability and calibration gates remain open.

For a Bernoulli response with a group random intercept, the tested model is

\[
Y_{ig}\mid b_g \sim \mathrm{Bernoulli}\{\mathrm{logit}^{-1}(\beta_0+\beta_1 x_{ig}+b_g)\},\qquad
b_g \sim N(0,\tau_g^2),\qquad
\log(\tau_g)=\alpha_0+\alpha_1 w_g.
\]

The R syntax is `bf(y ~ x + (1 | id), sd(id) ~ w)`, with a binary `binomial()` family. The interpretation is direct: a one-unit increase in the group-level predictor `w` multiplies the random-intercept standard deviation by `exp(alpha_1)`, holding the other SD predictors fixed. The mean formula retains its own predictor `x`. Bernoulli responses do not receive an independent residual `sigma` parameter.

The synthetic fixture supplies equally spaced group-level `w` values and generates the latent random intercepts and binary responses outside drmTMB's likelihood and simulation code. The targeted test checks that the two SD regression coefficients map to `beta_sd_mu` indices 1 and 2, and that an 80% native profile interval for `fixef:sd(id):w` is finite, ordered, on the log-SD coefficient scale, and contains the fitted coefficient. This is a plumbing and interval-existence check. It does not establish interval coverage or general inference calibration.

The tested slice is limited to an ordinary scalar random intercept in a univariate Bernoulli model with a fixed, group-constant SD predictor. It does not establish support for every response distribution, random-effect type, endpoint, provider, or R/Julia engine combination in the programme inventory. The broader per-cell implementation, recovery, and uncertainty-calibration gates remain open. Marginal simulation and two bootstrap refits pass freshly installed-package checks. Clamp and start diagnostics distinguish latent SD from residual scale. Two refits do not establish interval calibration.

## Verification receipt

The compiled test `tests/testthat/test-binomial-sd-profile.R` passed against `/private/tmp/drmtmb-general-sd-library/drmTMB` using `DRMTMB_SD_TEST_LIBRARY=/private/tmp/drmtmb-general-sd-library Rscript tools/general-sd-regression/run-native-tests.R tests/testthat/test-binomial-sd-profile.R` (about 30 seconds). The test checks target names, `beta_sd_mu` indices, log-scale reporting, and a finite ordered profile interval bracketing the fitted slope. It is evidence for this synthetic Bernoulli slice only; the interval was not evaluated for repeated-sampling coverage.

## Retained native checkpoint

The six new compiled test files passed 117 assertions against the isolated
installed package. Existing binomial response/link, Gaussian SD and clamp
regression tests passed. The older simulation tests passed in their required
pkgload context; a standalone installed runner failed because its local mock
requires pkgload. No full package check has run.

The feasibility pilot has six completed results from six unique seeds and
seven total fit attempts. The original 300-second run completed five fits and
was stopped during the sixth. Its interrupted attempt remains in the record.
A separate retry completed that seed in 78.54 wall-clock seconds. All six
completed fits had healthy recorded diagnostics and valid finite profile
intervals. Their independent scalar Laplace objective differences were below
1e-6. This checks implementation and runtime, not repeated-sampling coverage.

Text logs, attempt journals, source/binary hashes, environments and both
supervisor outcomes are retained in
`evidence/native-checkpoint-20261017/`. Ledger copies there are dated
snapshots; `.unlazy/general-sd-regression/` remains the live acceptance ledger.

The source-bound Totoro installation and six-seed pilot also completed under
the 15-minute cap. The full installation plus pilot took about 131 seconds;
individual fits plus profiles took 9.3 to 13.7 seconds. All six attempts
completed with valid recorded intervals. See `totoro/receipt.json` inside the
checkpoint evidence. This repeats the feasibility checks on the intended CPU
host and adds no coverage claim.
