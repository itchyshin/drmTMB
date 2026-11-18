# Native Binomial phylogenetic and relatedness non-logit Q evidence

The native R/TMB Binomial q1 pair combines a tree-backed phylogenetic field with a relatedness field. For both probit and complementary-log-log links, the same simulated data are fit using relmat covariance K and precision Q = solve(K). The synthetic design crosses 30 tips with 48 populations and uses deliberately reversed matrix labels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 14 focused expectations passed without failures or warnings. Both K and Q fits converged for each link. Their log likelihoods, SD coefficients, and name-aligned population predictions matched within tolerance.

This is input-equivalence evidence for native Binomial probit and cloglog phylo-tree plus relmat Q precision. It does not establish interval coverage, Julia parity, or broader family support. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
