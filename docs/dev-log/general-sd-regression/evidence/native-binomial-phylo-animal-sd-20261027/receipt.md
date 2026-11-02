# Native Binomial phylogenetic and animal SD evidence

The native R/TMB Binomial q1 intercept route combines a tree-backed phylogenetic field and an animal field using covariance matrix A. The synthetic data cross 30 tips with 48 animal groups and six replicates. Each field has its own binary group predictor and log-SD regression; animal covariance labels are deliberately reversed relative to data factor levels. The test generates independent responses under logit, probit, and complementary-log-log links.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 22 focused expectations passed without failures or warnings. Across the three links, checks cover optimizer convergence, recovery bounds for both SD slopes, target-specific coefficient names, and group-named SD predictions.

This is one-seed point-recovery and output evidence for native Binomial logit, probit, and cloglog q1 phylo-tree plus animal A-covariance intercepts. It does not establish interval coverage, Julia parity, or broader family support. Source hashes are recorded in `source-manifest.json`; console output is in `focused-tests.log`.
