# Native Binomial ordinary and phylogenetic non-logit SD evidence

The native R/TMB Binomial route combines an ordinary iid random intercept and a tree-backed phylogenetic intercept. A fixed-seed synthetic dataset has 384 ordinary groups nested within 48 tips, with a group-level predictor for each SD. Responses are independently generated under probit and complementary-log-log links.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 20 focused expectations passed without failures or warnings. Both links check convergence, positive and bounded recovery of both SD slopes, coefficient names, predicted SD counts, and structured-effect labels.

This is one-seed point-recovery/output evidence for native Binomial probit and cloglog `iid + phylo` q1 intercepts. It does not establish interval coverage, Julia parity, or other response families. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
