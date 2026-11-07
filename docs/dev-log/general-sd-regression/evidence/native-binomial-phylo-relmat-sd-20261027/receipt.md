# Native Binomial phylogenetic and relatedness SD evidence

The native R/TMB Binomial q1 intercept pair combines a tree-backed phylogenetic field and a relatedness field with separate predictor-dependent SD formulas. Under logit, the test uses relmat covariance `K` and equivalent precision `Q = solve(K)`, checking equality of likelihood, SD coefficients, and name-aligned predictions. Under probit and complementary-log-log, it fits the pair with `K`. The synthetic data cross 30 tips with 48 populations and use reversed matrix labels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 32 focused expectations passed without failures or warnings. Checks cover convergence, positive, non-negligible recovery bounds for both SD slopes, target names, group-named predictions, and the logit K/Q equivalence.

This is one-seed point-recovery and output evidence for native Binomial q1 phylo-tree plus relmat K covariance under logit, probit, and cloglog; the logit route also has Q precision equivalence evidence. It does not establish non-logit Q precision, interval coverage, Julia parity, or broader family support. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
