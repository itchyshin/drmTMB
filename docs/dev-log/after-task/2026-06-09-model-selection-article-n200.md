# After Task: Model Selection Article And AIC/BIC n200 Support Run

## Goal

Add a useful model-selection article for `drmTMB` users and back it with a
200-replicate seeded article-support simulation that compares AIC and BIC
without claiming more than the simulation design supports.

## Implemented

- Added `vignettes/model-selection.Rmd`.
- Added `docs/design/167-model-selection-aic-bic-simulation-design.md`.
- Added the Phase 18 model-selection DGP, fitter, runner, writer, report CSV,
  and focused tests under `inst/sim/` and `tests/testthat/`.
- Routed the article through `_pkgdown.yml`.
- Updated NEWS, `docs/design/37-worked-example-inventory.md`, and
  `inst/sim/README.md`.
- Added `save_results = FALSE` to the model-selection writer so the 200-run can
  write compact tables without saving 1,200 per-replicate RDS files.
- Wrote local article-support artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-09-model-selection-n200/`.

## Mathematical Contract

The article compares explicit candidate sets by
`AIC = -2 * logLik + 2 * k` and
`BIC = -2 * logLik + log(n) * k`. It keeps comparisons on the same response
scale and analysis rows, and it treats convergence, Hessian status, warnings,
and errors as separate diagnostics rather than as hidden selection details.

The article-support design has six paired cells: Gaussian versus Student-t
tails, NB2 versus ZINB2 structural zeros, and constant versus
predictor-dependent Gaussian `sigma` formulas. Each cell stores a
`selection_target` so AIC/BIC truth-selection rates can be summarized.

## Files Changed

New files:

- `docs/design/167-model-selection-aic-bic-simulation-design.md`
- `vignettes/model-selection.Rmd`
- `inst/sim/dgp/sim_dgp_model_selection.R`
- `inst/sim/fit/sim_summarise_model_selection.R`
- `inst/sim/run/sim_run_model_selection_smoke.R`
- `inst/sim/run/sim_write_model_selection_smoke.R`
- `inst/sim/reports/model-selection-article-summary.csv`
- `tests/testthat/test-phase18-model-selection-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-09-model-selection-n200/`

Updated existing files:

- `_pkgdown.yml`
- `NEWS.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla -e 'parse(file="inst/sim/dgp/sim_dgp_model_selection.R"); parse(file="inst/sim/fit/sim_summarise_model_selection.R"); parse(file="inst/sim/run/sim_run_model_selection_smoke.R"); parse(file="inst/sim/run/sim_write_model_selection_smoke.R"); parse(file="tests/testthat/test-phase18-model-selection-smoke.R"); cat("parse ok\n")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phase18-model-selection-smoke", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'styler::style_file(c("inst/sim/dgp/sim_dgp_model_selection.R", "inst/sim/fit/sim_summarise_model_selection.R", "inst/sim/run/sim_run_model_selection_smoke.R", "inst/sim/run/sim_write_model_selection_smoke.R", "tests/testthat/test-phase18-model-selection-smoke.R"))'
/usr/local/bin/Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); # sourced sim helpers; phase18_write_model_selection_smoke_outputs(output_dir = "docs/dev-log/simulation-artifacts/2026-06-09-model-selection-n200", n_rep = 200L, master_seed = 20260609L, overwrite = TRUE, cores = 6L, backend = "multicore", save_results = FALSE)'
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 /usr/local/bin/Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/model-selection.Rmd", output_dir = tempdir(), quiet = TRUE); cat("render ok\n")'
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 /usr/local/bin/Rscript --vanilla -e 'pkgdown::check_pkgdown()'
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 /usr/local/bin/Rscript --vanilla -e 'pkgdown::build_article("model-selection", quiet = TRUE)'
rg -n "best model|AIC.*proves|BIC.*proves|formal.*model-selection|formal.*AIC|formal.*BIC|calibrated.*model-selection|operating-characteristic|power grid|same data|same analysis rows|same response" vignettes/model-selection.Rmd docs/design/167-model-selection-aic-bic-simulation-design.md NEWS.md docs/design/37-worked-example-inventory.md inst/sim/README.md
rg -n "model-selection|model selection|AIC|BIC" README.md ROADMAP.md NEWS.md docs vignettes inst/sim --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!docs/dev-log/simulation-artifacts/**'
rg -n "[[:blank:]]$|^<<<<<<<|^=======$|^>>>>>>>" vignettes/model-selection.Rmd docs/design/167-model-selection-aic-bic-simulation-design.md inst/sim/dgp/sim_dgp_model_selection.R inst/sim/fit/sim_summarise_model_selection.R inst/sim/run/sim_run_model_selection_smoke.R inst/sim/run/sim_write_model_selection_smoke.R tests/testthat/test-phase18-model-selection-smoke.R inst/sim/reports/model-selection-article-summary.csv
git diff --check -- NEWS.md _pkgdown.yml docs/design/37-worked-example-inventory.md inst/sim/README.md
```

Focused tests passed. The n200 run wrote 2,400 candidate rows, 1,200 manifest
rows, six selection-summary rows, and an empty failure ledger. The direct
vignette render passed with
`RSTUDIO_PANDOC` set to RStudio's bundled Pandoc. `pkgdown::check_pkgdown()`
reported no problems, and `pkgdown::build_article("model-selection")` wrote
the page successfully.

## Tests Of The Tests

The focused test file checks the condition registry, DGP truth object, summary
rate calculation, writer outputs, manifest existence, overwrite refusal, and
the `save_results = FALSE` table-only path. The writer tests fit
one-replicate `sigma_formula` cells, so they exercise the actual DGP, fitting,
summary, output, and failure-path contract rather than only checking object
names.

## Consistency Audit

The article, design sheet, inventory, simulation README, NEWS entry, and n200
artifacts all use the same boundary: this is a 200-replicate article-support
run, not a formal operating-characteristic grid. The article tells readers to
compare models on the same response scale and analysis rows, keep diagnostics
beside AIC/BIC, and report criterion differences rather than only the winner.

The stale-claim scans searched for overstatements such as `best model`,
`AIC.*proves`, `BIC.*proves`, formal AIC/BIC claims, calibrated
model-selection claims, and missing same-row language. The only relevant hits
were the intended caveats and article text.

## GitHub Issue Maintenance

GitHub issue searches in `itchyshin/drmTMB` for `model selection AIC BIC` and
`AIC BIC logLik model-fit extractors` returned no overlapping open issue, so
no issue comment or new issue was added.

## What Did Not Go Smoothly

Plain `rmarkdown::render()` initially failed because this shell could not find
Pandoc. Setting `RSTUDIO_PANDOC` to
`/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64`
fixed the render. The first `pkgdown::build_article()` attempt also failed
because the vignette helper used `is_converged()`, which was not visible in
that pkgdown render environment. A local helper reading
`fit$opt$convergence == 0` fixed the page without changing package code.

## Team Learning

For documentation pages that use small helper functions, prefer helpers that
depend only on objects shown in the article unless the exported function is the
lesson being taught. That makes direct render, pkgdown render, and installed
package render behave more similarly.

## Known Limitations

The article-support run used 200 replicates per cell. That is enough to make
the documentation table much less noisy than the initial plumbing smoke, but
it is still not a formal AIC/BIC selection-probability, power, false-positive,
or sample-size grid.

The `normal_tail` row deliberately shows that the unnecessary Student-t
candidate can produce warnings or weak Hessian status even when AIC/BIC mostly
select Gaussian. The `heavy_tail` and `extra_zeros` rows show that BIC can
prefer the simpler model more often under this sample size. These are
diagnostic and criterion-penalty cautions, not failures of the article.

## Next Actions

If model-selection evidence becomes a publication-facing claim, design a
larger grid with explicit ADEMP factors for sample size, effect size, tail
strength, zero-inflation strength, scale-slope strength, and candidate-set
misspecification. Keep MCSEs and warning/error ledgers beside every selection
rate.
