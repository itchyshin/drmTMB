# Native Binomial phylo plus animal SD pair

Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; 22 focused expectations across logit, probit, and complementary-log-log links passed without warnings. The test checks convergence, both SD-slope recovery bounds, target-specific coefficient names, group-named predictions, and structured-effect labels for the native q1 phylogenetic tree plus animal A-covariance pair.

Evidence reconciliation and source hashes are retained in `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-animal-sd-20261027/`. This is one-seed point-recovery evidence only. It does not establish interval coverage or Julia parity.

Status-inventory search run for README.md, docs/dev-log/internal-roadmap.md, NEWS.md, docs/dev-log/known-limitations.md, docs/design/01-formula-grammar.md, vignettes/formula-grammar.Rmd, and _pkgdown.yml:

```sh
rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\([^V]|full.*rejected|only diagonal|planned.*implemented' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

This local audit found only historical/deprecation matches and a pre-existing formula-grammar support-table entry to reconcile in the documentation lane; it did not change public docs in this slice.
