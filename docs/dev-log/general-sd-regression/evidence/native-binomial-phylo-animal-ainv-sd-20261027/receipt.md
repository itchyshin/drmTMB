# Native Binomial phylogenetic and animal A-inverse SD evidence

The native R/TMB Binomial logit q1 pair combines a tree-backed phylogenetic field with an animal field. A fixed-seed synthetic dataset is fit using animal covariance A and its equivalent precision Ainv = solve(A), with the same observations and predictor-dependent SD formulas. Animal matrix labels are reversed relative to the factor levels.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-ainv-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; seven focused expectations passed without failures or warnings. Both fits converged, and log likelihood, both SD coefficient vectors, and animal-named predictions matched.

This is input-equivalence evidence for native Binomial logit q1 phylo-tree plus animal A-inverse precision. It does not establish interval coverage, Julia parity, or other links and animal inputs. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
