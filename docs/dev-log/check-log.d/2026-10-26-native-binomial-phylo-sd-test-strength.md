| Date | Task | Check | Result |
|---|---|---|---|
| 2026-10-26 | Native Binomial phylogenetic SD test-strength update | `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression", reporter = "summary")'` | Passed: 25 expectations. The logit SD-slope error bound is now 0.3; full predicted tip scales are checked against the fitted formula in tip order. Direct R/TMB evidence only. |
