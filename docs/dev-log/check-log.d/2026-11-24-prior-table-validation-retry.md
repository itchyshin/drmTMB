# Prior-table validation retry

The first eight-shard `R CMD check` on drmTMB commit `724ef0b22f178bdadc976d3553bdf11768785cee` exited 1 in all shards. The repeated vignette error came from `vignettes/convergence.Rmd`: its setup chunk was skipped under the check runner's inherited chunk options, leaving both `has_ggplot2` and the attached `drmTMB` functions unavailable. The setup chunk now sets `eval=TRUE`; a local `rmarkdown::render()` completed successfully.

The same check found that `test-julia-fixed-priors-v2.R` expected a Student-t coefficient prior combined with a mean random-intercept SD prior to require native-only targets. The current v5 bridge supports that composition, so the assertion now expects it to be admitted. The added opt-in call site was missing from `inst/extdata/env-skip-census.tsv`; the census was regenerated and checked.

Focused verification passed: `Rscript --vanilla tools/write-env-skip-census.R --check`; `Rscript --vanilla -e 'devtools::test(filter="env-skip-census|julia-fixed-priors-v2", reporter="summary")'` (20 assertions, 0 failures, 1 expected live-Julia skip); and `rmarkdown::render("vignettes/convergence.Rmd", ...)`. `git diff --check` passed. The first full check also reported its expected source-tarball skips and a warning from the animal slope oracle; these were not changed here.

The corrected source has not yet been through a full package check. The initial full-check logs and all shard outputs remain preserved at `/home/snakagaw/hsq_work/drmTMB-724ef0b-full-suite-20261124/attempt-02/`. The Student-t test file also exists on other active refs; this correction is confined to the isolated integration branch and must be reconciled with those owners before integration.
