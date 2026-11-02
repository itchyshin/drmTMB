# Native Binomial correlated q=4 SD recovery under probit and cloglog

This fixed-seed synthetic test fits one ordinary correlated random-effect block with an intercept and three numeric slopes. Each of the four coefficients has its own predictor-dependent SD formula. It fits the same design under probit and complementary log-log links and checks optimizer convergence, finite parameters, SD predictions reconstructed from fitted coefficients, log-SD slope recovery, and the six correlations against the known DGP.

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-q4-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

The captured corrected run exited 0 with 32 expectations passing. Source hashes matched before and after the fit. The first attempt found a non-positive-definite Hessian for the probit fit, which means Wald standard errors from that fit are not trustworthy. Two later attempts also exposed unsupported `info` arguments in this installed testthat version; the harness was corrected without changing any recovery tolerance. The final test checks point estimation only and does not assert Hessian positivity.

The evidence reconciler passes with 139 linked rows out of 19,678 candidates and 161 records. Four q>=2 candidate rows link this q=4 fixture; they remain unreviewed and the fixture does not establish the whole q>=2 domain. It does not establish interval calibration, Julia parity, or support in other families.
