# Native Binomial animal pedigree plus relatedness SD evidence

The native R/TMB Binomial logit q1 pair combines an animal field defined by pedigree with a relmat field using K covariance. A fixed-seed synthetic dataset is fit again with the additive relationship matrix A generated from the same pedigree. Both fits use the same responses and reversed matrix/factor ordering.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-pedigree-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; seven focused expectations passed without failures or warnings. Both fits converged, and log likelihood, animal and relmat SD coefficient vectors, and named predictions matched.

This is input-equivalence evidence for native Binomial logit q1 animal pedigree plus relmat K covariance. It does not establish interval coverage, Julia parity, or other links and kernel inputs. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
