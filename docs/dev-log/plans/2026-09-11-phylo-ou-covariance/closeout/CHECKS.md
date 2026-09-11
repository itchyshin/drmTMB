# Phylogenetic OU covariance closeout checks

- `PO3`, `PO4`, `PO5`, `PO6`, and `PO9` were rerun from the final source on
  2026-09-11 and emitted their expected pass markers. They cover parser/native
  compilation, the dense likelihood and derivative oracle, reductions and
  mutations, public methods, and rendered reader material.
- The source-package check is retained in `package-check-no-tests.log`. It ran
  `--no-tests --no-manual --no-build-vignettes`, completed with 0 errors, and
  executed all examples and package vignettes including `formula-grammar.Rmd`.
  It reported the established `checkbashisms`/`tools-scratch` warning and two
  environment notes. The full test run was stopped after no output progress in
  the unrelated Julia test stage; it is not used as a passing receipt.
