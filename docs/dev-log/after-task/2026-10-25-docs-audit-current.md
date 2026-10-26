## 1. Goal

Repair current R documentation, API help, executable examples, and evidence limits.

## 2. Implemented

Correct public examples, document Julia-backed S3 methods, qualify interval and validation claims, restore mathematical rendering, and repair the generated 404 MathJax script tag. Three refusal messages now describe existing restrictions accurately. Diagnostic subsetting now forwards its existing drop argument, fixing a reproduced mismatch between the declared default and the returned single-column result.

The final local site audit also found a duplicated argument anchor for `tree1` and `tree2`. The builder now retains the first target for incoming links and assigns unique targets to later arguments.

## 3a. Decisions and Rejected Alternatives

Preserve existing numerical algorithms, signatures, and admission boundaries. State the limits of recorded numerical evidence rather than add scientific claims. Keep historical benchmark reports unchanged.

## 4. Files Touched

- `.gitignore`
- `DESCRIPTION`
- `NEWS.md`
- `R/adequacy-plots.R`
- `R/associate-pairs.R`
- `R/check.R`
- `R/coevolution-accessors.R`
- `R/drmTMB.R`
- `R/formula-markers.R`
- `R/julia-bridge.R`
- `R/julia-fit-methods-docs.R`
- `R/methods.R`
- `R/penalty.R`
- `R/predict-parameters.R`
- `R/profile.R`
- `README.md`
- `_pkgdown.yml`
- `docs/dev-log/after-task/2026-10-25-docs-audit-current.md`
- `docs/dev-log/check-log.d/2026-10-25-docs-audit.md`
- `inst/extdata/env-skip-census.tsv`
- `man/associate_pairs.Rd`
- `man/check_drm.Rd`
- `man/coevolution-accessors.Rd`
- `man/confint.drmTMB.Rd`
- `man/confint.drmTMB_julia.Rd`
- `man/corpairs.Rd`
- `man/drmTMB.Rd`
- `man/drm_phylo_penalty.Rd`
- `man/is_converged.Rd`
- `man/julia-fit-methods.Rd`
- `man/mi.Rd`
- `man/phylo.Rd`
- `man/predict_parameters.Rd`
- `man/rho12.Rd`
- `man/worm_plot.Rd`
- `tests/testthat/test-docs-audit-semantics.R`
- `tests/testthat/test-newton-polish-guard.R`
- `tools/build-pkgdown.R`
- `vignettes/animal-models.Rmd`
- `vignettes/articles/distributional-outputs-and-adequacy.Rmd`
- `vignettes/articles/model-workflow.Rmd`
- `vignettes/articles/phylogenetic-spatial.Rmd`
- `vignettes/bipartite-phylogenetic-interactions.Rmd`
- `vignettes/capability-and-limits.Rmd`
- `vignettes/convergence.Rmd`
- `vignettes/cross-family.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/julia-engine.Rmd`
- `vignettes/missing-data.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/relmat-known-matrices.Rmd`
- `vignettes/robust-student.Rmd`
- `vignettes/spatial-models.Rmd`

## 5. Checks Run

The current source passes 27 focused documentation, builder, subsetting, and help regressions. The pre-integration local site build exited zero and produced 241 HTML pages. The final build must include the merged interval default and added method aliases. Public vignette, ordinary-fence, and Rd examples have raw execution receipts in the task audit. The contributor document command completed. The initial source-tree test returned failures because the disposable export omitted tracked design fixtures. The new subsetting regression failed before its one-line fix (four failures) and passed afterward. Independent review caught a missing generic usage line; its new test failed before regeneration and passed afterward. The affected test batch passed 70 assertions. The HTML test dependency and generated skip census are now declared, and the existing subprocess test resolves source paths in Rcheck layouts. The full-source retry and package check found setup defects; the final reruns remain required. Historical fixtures and genuine Git metadata are restored in the disposable source copy. Upstream bf634ab was integrated without conflicts. Its two affected default-interval examples were rerun in their actual article setup; the ordinary SD rows are profile intervals and the remaining rows are Wald. Roxygen configuration now agrees with the contributor pin of 7.3.2.

The argument-anchor regression failed on the duplicate target before the fix. Six source-test assertions now pass, including a reserved-ID collision and idempotence. Applying the postprocessor to the 245-page artifact changes only the affected reference page; all 11,334 internal references resolve and no duplicate IDs remain.

## 6. Tests of the Tests

The task verification harness passed 19 disposable controls, including missing tutorials, soft 404 responses, malformed tables, missing example logs, stale API defaults, incorrect diagnostics, protected-path changes, and build success without deployment. Julia AST controls reject changed executable code and unrelated string edits. R builder tests reject the malformed script while preserving adjacent scripts and idempotence.

## 7a. Issue Ledger

Corrected source findings are part of this patch. Final inventory reconciliation, independent review, required checks, deployment, and direct live checks remain open. The complete task ledger records these as unmet.

## 8. Consistency Audit

Reviewed adjacent reference pages, manual navigation, constructor examples, family restrictions, parameter scales, named interval targets, and retained evidence. Generated pages are checked separately from source pages and aliases.

## 9. What Did Not Go Smoothly

Sparse source exports initially omitted needed assets or extensions. Those exports were corrected and affected checks rerun. Some task runners initially used the wrong fixture or installed package; corrected runs bind the loaded source and preserve earlier failures. Environment failures do not count as successful execution.

The final package check exposed a duplicate Julia method usage in the generic rho12 help topic. The dedicated Julia methods topic retains the method signature and alias. Removing the duplicate clears the invalid local usage contract; a regression checks all 102 Rd topics and passed 103 assertions after reproducing the failure. The source-tree test manifest now includes the documentation regression file.

Running the documented roxygen2 7.3.2 command also regenerated seven Rd files. The changes resolve existing aliases to their canonical help topics, rewrap unchanged prose, remove a duplicate author listing, and align the quantile help wording with its source. These generated changes are retained for a clean regeneration comparison.

## 10. Known Residuals

This report describes a prepared patch, not a completed site audit or publication receipt. Final deployment and full acceptance reconciliation are still required. No package release, scientific calibration, or new capability admission is claimed.

## 11. Team Learning

Memory receipt: exact-source deployment and scoped ownership guidance applied. The task retains raw logs, source hashes, negative controls, and independent review reports outside the package.

Golden Set: the catalog and detector self-tests were checked; the self-tests discriminate their saved good and bad cases. This does not certify the audit transcript or package methods. The task-specific negative controls are recorded separately above.

## 12. Cross-Product Coverage

Covers: current public documentation and the bounded corrections listed above. The paired package has a separate source patch and execution ledger.

Does NOT cover: historical documentation rewrites, releases, tags, new methods, parity or coverage campaigns. Julia docs/design/capability-status.md is excluded and unchanged by this lane.
