# Check log: zero-one beta location slope SD regression

## Scope

Native TMB now admits a predictor-dependent SD formula for one ordinary zero-one beta location intercept or one independent numeric location slope. The intercept route in native TMB and Julia remains as before. Julia slope support and interval calibration remain open.

## Checks

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zero-one-beta-sd-slope")'`: PASS, 17 tests, 0 failures, 0 warnings, 0 skips, 14.7 s.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zero-one-beta-sd-regression")'`: PASS, 14 tests, 0 failures, 0 warnings, 0 skips.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); out <- rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "predictor-sd.html", output_dir = tempdir(), quiet = TRUE); cat("RENDERED:", out, "\n")'`: PASS on the current source in the prior turn. Pandoc printed its existing deprecated `--mathjax` option warning.
- The current-source formula-grammar vignette rendered successfully; Pandoc printed its existing deprecated `--mathjax` warning. `pkgdown::check_pkgdown()` passed with only existing `--mathml` deprecation warnings.
- Test-first evidence: the new assembly test failed at the prior intercept-only admission check before the builder change, then passed after the change.
- `devtools::test(filter = "zero-one-beta")` was stopped after the existing quadrature integration exceeded the brief run estimate. It did not complete and is not counted as a pass.

## Documentation and consistency

Updated `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, `NEWS.md`, `vignettes/formula-grammar.Rmd`, `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`, and `vignettes/predictor-dependent-random-sd.Rmd`. The exact status inventory search was:

`rg -n -i 'zero.one beta|zero-one beta|zero_one_beta' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`

The scale-status design page, NEWS, formula-grammar vignette, and main check log were updated after reviewing the current local diffs and confirming no child agent remained active. README, roadmap, known-limitations, and pkgdown navigation were checked in the status inventory; no additional change was needed for this slice.

## Issue maintenance

Searched open drmTMB issues for zero-one beta, random-effect SD, and predictor-dependent scale terms. The closest results were general response-family or repeatability issues, not a tracked issue for this implementation slice. No issue was opened, commented on, or closed.

## Limits

The slice covers one complete-response zero-one beta location target, either an ordinary intercept or one independent numeric slope, with other distributional parameters fixed and no structured or additional random effects. The zero-one beta family-wide quadrature test did not finish. The Julia slope route, interval calibration, and broader package checks remain outstanding.

- Targeted `git diff --check` passed. Full `git diff --check` reports an unrelated existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`; that file was not changed in this slice.
