# Check log: native Lognormal random-slope SD regression

## Scope

The native Lognormal route admits a predictor-dependent SD for one selected
independent numeric location slope. Responses must be complete; `sigma` may
have fixed effects but no random effects in this slice. Correlated and
structured effects, Julia parity, and interval calibration remain open.

## Checks

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "lognormal-sd-slope-assembly")'`: PASS, 17 expectations, 0 failures, 0 warnings, 0 skips, 6.2 seconds.
- Test-first receipt: the assembly test failed at the prior intercept-only admission guard before the Lognormal builder was widened to independent slopes; it passes after the builder change.
- The synthetic recovery test uses 96 groups and 10 observations per group with `log(tau_g) = log(0.4) + 0.35 w_g`. It checks convergence, positive-definite Hessian, coefficient recovery, group-level SD prediction, an independent groupwise Cholesky marginal-likelihood calculation including the lognormal Jacobian, and positive simulated responses.
- Constant-SD equivalence is checked against the ordinary independent-slope fit. Both fits are required to converge and have positive-definite Hessians before comparing log likelihoods.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/drmTMB-predictor-dependent-random-sd.html", quiet = TRUE, envir = globalenv()); writeLines("PASS", "/private/tmp/drmTMB-lognormal-vignette-render.status")'`: PASS. The render emitted the existing Pandoc `--mathjax` deprecation warning; the output includes executed Lognormal slope fit and prediction results.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'`: PASS, no problems found; existing Pandoc `--mathml` deprecation warnings were emitted.
- `git diff --check -- R/drmTMB.R tests/testthat/test-lognormal-sd-slope-assembly.R docs/dev-log/general-sd-regression/lognormal-sd-contract.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md docs/design/18-random-effect-scale-models.md docs/design/01-formula-grammar.md vignettes/predictor-dependent-random-sd.Rmd NEWS.md`: PASS.

## Consistency and issue audit

The direct SD capability row, Lognormal family row, design contract, adapter
map, vignette, and NEWS now describe the same narrow slice. The status
inventory command was:

`rg -n -i 'lognormal.*(random.effect|random slope|SD regression)|random.effect.*lognormal|random slope.*lognormal' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`

The formula-grammar and scale-model design tables were updated; no pkgdown
navigation change was needed. Open-issue search:
`gh issue list --state open --search 'lognormal random-effect SD regression' --limit 10`.
It found no matching feature issue (the sole result was a general test-sweep
issue), so no issue was opened, edited, or closed.

## Limitations and next work

This is native point-recovery and workflow evidence, not calibrated uncertainty.
No Julia fit or same-data engine comparison was run. The current slope slice
does not cover correlated blocks, structured providers, missing responses, or
random effects on `sigma`. The broader programme still needs family/effect
inventory rows and implementation/recovery evidence.
