# Native Binomial phylogenetic and animal pedigree SD evidence

The native R/TMB Binomial logit q1 pair combines a tree-backed phylogenetic field with an animal field. A fixed-seed synthetic dataset is fit with animal relationship matrix A and the equivalent pedigree input on the same observations. The pedigree has unrelated founders and full-sibling offspring groups; matrix and factor orders differ.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-pedigree-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; seven focused expectations passed without failures or warnings. Both fits converged, and likelihood, both SD coefficient vectors, and animal-named predictions matched.

This is input-equivalence evidence for native Binomial logit q1 phylo-tree plus animal pedigree. It does not establish interval coverage, Julia parity, or other links and animal inputs. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
