# 2026-10-20: NB2 SD coefficient uncertainty outputs

The NB2 ordinary-intercept SD integration test now asserts that `vcov()` returns positive finite variances for both `sd(id)` coefficients and that `summary()` returns positive finite standard errors for those rows. This checks the public uncertainty output that the model-type 7 report path does not expose through `REPORT(beta_sd_mu)`; the implementation reads coefficient estimates and ML covariance from optimizer parameters.

Check: `Rscript -e "devtools::test(filter = '^nbinom2-sd-integration$', reporter = 'summary')"` passed. An initial broader filter also selected the truncated-NB2 suite and was interrupted; the exact rerun completed the NB2 file cleanly. No interval-calibration claim is made.
