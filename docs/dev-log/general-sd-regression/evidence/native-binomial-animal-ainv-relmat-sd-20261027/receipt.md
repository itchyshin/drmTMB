# Native Binomial animal A-inverse and relatedness SD evidence

The native R/TMB Binomial logit q1 pair combines animal A-inverse precision with relmat K covariance. A fixed-seed synthetic dataset is fit with animal A covariance and Ainv = solve(A) on identical observations. Both matrix inputs use names reversed relative to data factor order.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-ainv-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; seven focused expectations passed without failures or warnings. Both fits converged, and log likelihood, animal and relmat SD coefficient vectors, and named predictions matched.

This is input-equivalence evidence for native Binomial logit q1 animal A-inverse plus relmat K covariance. It does not establish interval coverage, Julia parity, or other links and kernel inputs. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
