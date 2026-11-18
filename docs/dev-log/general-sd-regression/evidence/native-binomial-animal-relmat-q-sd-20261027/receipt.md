# Native Binomial animal and relatedness Q-precision SD evidence

The native R/TMB Binomial logit q1 pair has an animal field using covariance matrix A and a relatedness field using Q = solve(K). A fixed-seed synthetic dataset crosses 32 animals with 36 populations and six replicates. Matrix labels are reversed relative to data factor levels. The model is fit using both K covariance and Q precision on the same observations.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-precision-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; eight focused expectations passed without failures or warnings. They check convergence for both fits and equality of log likelihood, both SD coefficient vectors, and name-aligned predicted SDs.

This is input-equivalence evidence for native Binomial logit q1 animal A-covariance plus relmat Q precision. It does not establish interval coverage, Julia parity, or other link and kernel combinations. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
