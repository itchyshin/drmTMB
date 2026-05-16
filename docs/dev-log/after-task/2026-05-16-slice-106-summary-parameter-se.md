# After Task: Slice 106 Summary Parameter Standard Errors

## Goal

Answer the `summary()` standard-error follow-up by adding honest
delta-method standard errors to direct response-scale parameter rows when
`TMB::sdreport()` supplies an optimized-parameter covariance matrix.

## Implemented

- Added `std_error` to `summary(fit)$parameters`.
- Filled `std_error` only for direct one-parameter targets that already appear
  in the `profile_targets()` namespace and map to one optimized TMB parameter.
- Used the delta method on the response-scale transformation:
  `exp()` for scale and SD rows, guarded `tanh()` for random-effect
  correlations, and the `rho12` guard for residual correlations.
- Kept `std_error = NA` for descriptive fitted ranges and derived summaries
  such as repeatability or phylogenetic signal.
- Updated the printed parameter table so finite parameter standard errors are
  visible next to the estimate.
- Updated the `summary()` reference page, model-workflow article, NEWS,
  ROADMAP, profile-CI design note, and known limitations.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-151225-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, optimizer, formula grammar, or TMB parameterization changed.
The new values are local delta-method approximations derived from
`fit$sdr$cov.fixed`. They are not profile-likelihood intervals, they are not
Bayesian credible intervals, and they are not reported for nonlinear derived
variance ratios. Profile-likelihood confidence intervals remain the preferred
interval route for fitted SD and correlation targets.

## Files Changed

- `NEWS.md`
- `R/methods.R`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-106-summary-parameter-se.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-151225-codex-checkpoint.md`
- `man/summary.drmTMB.Rd`
- `tests/testthat/test-summary.R`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = '^summary$')"`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 174`.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e 'devtools::load_all(quiet=TRUE); ... print(summary(fit)$parameters)'`:
  confirmed a random-intercept fit prints finite `std_error` values for
  constant `sigma` and `sd:mu:(1 | id)`.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e "devtools::test()"`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 3597`.
- `Rscript -e "pkgdown::clean_site(); pkgdown::build_site(preview = FALSE)"`:
  passed and rendered the updated summary reference, model-workflow article,
  NEWS, and ROADMAP.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n "delta-method standard errors|std_error|std_error|Bayesian credible|confidence intervals, not Bayesian credible|direct response-scale parameter rows|descriptive fitted ranges|derived variance ratios" R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd vignettes/model-workflow.Rmd NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md pkgdown-site/reference/summary.drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html pkgdown-site/ROADMAP.html`:
  found the intended source, generated, and rendered references.
- `rg -n "credible interval|credible intervals|95% credible|Wald intervals.*variance components|do not get routine Wald standard errors|standard errors.*not" vignettes/model-workflow.Rmd NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md man/summary.drmTMB.Rd pkgdown-site/articles/model-workflow.html pkgdown-site/reference/summary.drmTMB.html`:
  found only intended profile-CI design language and the no-Bayesian wording.
- `Rscript -e "devtools::check(args = '--no-manual')"`: passed with
  0 errors, 0 warnings, and 1 local NOTE: `unable to verify current time`.
- `Rscript tools/codex-checkpoint.R --goal "Slice 106 summary parameter standard errors" --next "stage, commit, push, open PR, monitor CI, merge, then start Slice 107 reader-facing summary closure"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-151225-codex-checkpoint.md`.

## Tests Of The Tests

The focused summary test now checks both sides of the new contract. A
predictor-dependent fitted `sigma` range keeps `std_error = NA`, while a direct
ordinary random-intercept SD row equals
`sd * sqrt(cov.fixed["log_sd_mu", "log_sd_mu"])`. The same test also confirms
that the printed parameter table includes `std_error` when at least one
parameter row has a finite value.

## Consistency Audit

The source, generated Rd file, rendered reference page, model-workflow article,
NEWS, ROADMAP, profile-CI design note, and known limitations now agree:
`summary()` can show delta-method standard errors for direct response-scale
parameter rows when `sdreport()` succeeds, but profile-likelihood confidence
intervals remain the recommended interval route for SDs and correlations.
Descriptive fitted ranges and derived variance ratios remain point summaries
without standard errors.

## What Did Not Go Smoothly

The first implementation briefly carried `link_estimate` into
`summary(fit)$parameters`. Emmy caught that as an API leak; the final code uses
`profile_targets()` internally for the link-scale value and exposes only
`std_error` on the public summary table.

## Team Learning

- Ada: the right follow-up to the user's question was a narrow implementation,
  not a broad uncertainty refactor.
- Boole: `summary()` can expose `std_error` without changing extractor APIs or
  adding a new variance-component function.
- Fisher: delta-method SEs are useful local approximations but should not be
  described as interval evidence for boundary-prone SD or correlation rows.
- Curie: tests should compare the transformed SE to the exact `cov.fixed`
  element so a future index-ordering bug is caught.
- Pat: the workflow article needs to tell users how to rank the outputs:
  standard errors for quick reading, profile intervals for stronger SD and
  correlation uncertainty.
- Emmy: internal link-scale bookkeeping should stay internal; summary rows
  should not grow extra columns unless they are part of the public story.
- Grace: rerun roxygen, pkgdown, full tests, and R CMD check for even small
  `summary()` output changes because reference examples print the object.
- Rose: stale scans need to include both source and rendered site when wording
  changes from "no standard errors" to "delta-method standard errors".
- Gauss and Noether stayed watch-only because the likelihood and symbolic model
  contract did not change.

## Known Limitations

- Delta-method standard errors are local approximations and may be fragile near
  SD boundaries or correlation boundaries.
- Derived repeatability, phylogenetic signal, covariance products, and fitted
  ranges still do not have validated standard errors or confidence intervals.
- `summary()` does not yet add standard errors to `summary(fit)$covariance`
  rows because those covariance products combine multiple fitted quantities.

## Next Actions

1. Keep profile-likelihood confidence intervals as the documented interval path
   for direct SD and correlation targets.
2. Treat derived variance-ratio and covariance-product uncertainty as a later
   nonlinear-interval design task, not an automatic delta-method patch.
3. In Slice 107, use the now-richer `summary()` output in a reader-facing
   closure/checklist slice rather than adding another uncertainty engine.
