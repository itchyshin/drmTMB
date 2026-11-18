# Native Binomial ordinary and phylogenetic logit SD evidence

The native R/TMB Binomial logit route combines an ordinary iid intercept and a tree-backed phylogenetic intercept, each with its own SD regression. The fixed-seed test checks recovery of both slopes, simulation, save/reload prediction, and numerical equivalence between a base model without SD formulas and a constant-SD version.

Command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'`

Result: exit 0; 18 focused expectations passed without failures or warnings.

This is one-seed recovery and workflow evidence for native Binomial logit q1 `iid + phylo` intercepts. It does not establish interval coverage, Julia parity, or other response families. Source hashes are in `source-manifest.json`; console output is `focused-tests.log`.
