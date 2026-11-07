# Native Binomial animal and relmat kernel equivalence under probit and cloglog

This focused test checks whether six supported input representations produce the same fitted model for two non-logit Bernoulli links. It generates independent synthetic animal and population effects with predictor-dependent SDs, then fits animal `A`, `Ainv`, or pedigree input crossed with relmat `K` or `Q` input. Each fit uses the same response for a given link. The test checks convergence, log likelihood, both SD coefficient vectors, and label-aligned predicted SDs against the `A + K` reference.

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-kernel-equivalence-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'
```

The first focused run exited 0 with 62 expectations passed in 135.2 seconds. A second run was captured in `focused-tests.log` and also exited 0. The second transcript ends with the testthat `DONE` marker; the first run reported the explicit pass count.

This is native R/TMB input-equivalence and fit/output evidence for Binomial probit and complementary log-log, with additive animal and relmat latent fields. It does not establish point-recovery accuracy, uncertainty calibration, Julia parity, or support for other families, links, or effect structures. The evidence reconciler currently passes, Eight direct-SD evidence rows were linked for the animal A-inverse and pedigree inputs crossed with relmat K and Q under both links. The reconciled ledger now contains 135 linked rows out of 19,678 candidates, with 157 evidence records. The receipt remains unreviewed and is not an interval-calibration claim.
