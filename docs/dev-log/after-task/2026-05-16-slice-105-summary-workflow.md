# After Task: Slice 105 Summary Workflow

## Goal

Make the ordinary `summary()` workflow visible for users who expect a fitted
model summary to show fixed effects, variance components, interval status, and
the first derived variance-ratio summaries before they reach for specialist
extractors.

## Implemented

- Updated the printed `summary.drmTMB` parameter heading so random-effect SD
  rows are named in the visible output.
- Added a live random-intercept example to `vignettes/model-workflow.Rmd`.
- The article now shows `summary(fit_site)` for a site random-intercept model,
  explains the `sd:mu:(1 | site)` row as a response-scale random-effect SD,
  and tells readers that squaring it gives the variance component.
- The article now points readers to the `derived` component for repeatability
  when the Gaussian random-intercept ingredients are unambiguous.
- The article now states that random-effect SD and correlation uncertainty is
  handled through profile-likelihood confidence intervals for direct targets,
  not Bayesian credible intervals.
- Updated the Phase 17 roadmap and worked-example inventory to record the
  summary-first workflow polish.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-144822-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, TMB parameterization, formula grammar, optimizer, prediction
calculation, or interval calculation changed. This slice changes presentation
and documentation only. The existing frequentist interval contract stays the
same: fixed-effect Wald intervals are opt-in, direct SD or correlation profile
intervals are opt-in, and derived variance-ratio intervals remain unavailable
until a validated nonlinear interval method exists.

## Files Changed

- `R/methods.R`
- `ROADMAP.md`
- `docs/design/37-worked-example-inventory.md`
- `tests/testthat/test-summary.R`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-105-summary-workflow.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-144822-codex-checkpoint.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = '^summary$')"`: initially failed
  because the new `cli` heading writes to the message stream while the data
  frames write to stdout.
- `Rscript -e 'devtools::load_all(quiet=TRUE); ... capture.output(print(smry), type="message")'`:
  confirmed the heading is captured from the message stream.
- `Rscript -e "devtools::test(filter = '^summary$')"`: passed after the test
  captured both message and stdout streams, with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 171`.
- `Rscript -e "devtools::document()"`: passed with no generated-file changes.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "devtools::test()"`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 3594`.
- `Rscript -e "pkgdown::clean_site(); pkgdown::build_site(preview = FALSE)"`:
  passed and rendered the updated model-workflow page.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `Rscript -e "devtools::check(args = '--no-manual')"`: passed with
  0 errors, 0 warnings, and 1 local NOTE: `unable to verify current time`.
- `git diff --check`: passed.
- `rg -n "credible interval|credible intervals|95% credible|Bayesian credible|confidence intervals, not Bayesian credible|sd:mu:\\(1 \\| site\\)|random-effect variance component|Distributional, random-effect" R tests vignettes ROADMAP.md docs/design pkgdown-site/articles/model-workflow.html pkgdown-site/reference/summary.drmTMB.html`:
  found the intended no-credible-interval wording, random-effect example, and
  rendered heading only.
- `rg -n 'ordinary `summary\\(\\)`|summary\\(fit_site\\)|profile_targets\\(fit_site\\)|derived repeatability|variance components' vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html ROADMAP.md docs/design/37-worked-example-inventory.md`:
  confirmed the source and rendered site carry the summary-first workflow.
- `rg -n "summary\\(fit\\).*coef|coef\\(fit, dpar\\).*summary|Read coefficients by parameter" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html`:
  returned no matches after the old coefficient-first heading was removed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 105 summary workflow" --next "stage, commit, push, open PR, monitor CI, then start Slice 106 audit of random-effect SD standard-error feasibility"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-144822-codex-checkpoint.md`.

## Tests Of The Tests

The new focused test failed on its first run because it captured stdout only,
while `cli::cli_text()` writes the heading through the message stream. The test
now captures both streams before asserting the heading. That failure confirmed
the test is checking the actual printed surface rather than only the underlying
`summary()` object.

## Consistency Audit

Source and rendered docs now agree that ordinary `summary()` is the first
reader-facing surface for fixed effects, response-scale parameters, fitted
random-effect SDs, covariance summaries where present, derived repeatability,
and interval status. The workflow article keeps `fixef()`, `ranef()`,
`sigma()`, `rho12()`, and `corpairs()` as specialist extractors rather than
replacements for `summary()`. The roadmap and worked-example inventory record
the documentation polish without claiming a new model surface.

## What Did Not Go Smoothly

The first print-output test looked natural but captured the wrong output stream
for `cli` headings. Capturing both streams is a better pattern for future
printed-summary tests.

## Team Learning

- Ada: keep user-facing summary work narrow and land it as a documentation and
  print-surface slice before auditing deeper uncertainty internals.
- Boole: ordinary `summary()` should be treated as the public first-read API;
  extractors support follow-up tasks.
- Fisher: use "confidence interval" for drmTMB profile intervals and reserve
  "credible interval" for a future Bayesian backend, if one ever exists.
- Curie: printed-output tests using `cli` need to capture message output as
  well as stdout.
- Pat: applied users need the variance-component row and the repeatability row
  explained near a live example, not hidden in a design note.
- Darwin: the site random-intercept example is enough biological structure for
  a workflow guide without becoming a new full tutorial.
- Grace: a clean pkgdown rebuild verified the rendered guide, reference page,
  and roadmap after prose changes.
- Rose: the stale-wording scan should include rendered pages whenever the user
  explicitly asks whether something is visible in examples.
- Gauss and Noether stayed watch-only because no likelihood, TMB, or symbolic
  model contract changed.

## Known Limitations

- Random-effect SD rows still do not print routine Wald standard errors.
- Direct random-effect SD and correlation uncertainty remains available through
  profile-likelihood confidence intervals when the target is profile-ready.
- Derived repeatability intervals remain marked unavailable.
- This slice did not add `summary()` examples for bivariate covariance blocks,
  phylogenetic signal, or spatial SDs.

## Next Actions

1. Audit whether any existing `sdreport()`/delta-method path can honestly
   expose standard errors for direct random-effect SD rows, or whether profile
   intervals should remain the only supported interval route.
2. Add a compact reference-page example only if it can stay fast and stable
   under R CMD check.
3. Keep ordinary `summary()` examples ahead of specialist extractors in future
   user-facing workflows.
