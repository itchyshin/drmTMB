# After Task: `summary()` Parameter Table

## Goal

Make `summary.drmTMB()` show the distributional parameters that make `drmTMB`
different from generic mixed-model summaries: scale, shape, residual
correlation, random-effect standard deviations, and random-effect correlations.

## Implemented

- Added a `parameters` table to `summary.drmTMB()`.
- Kept the existing `coefficients`, `sdpars`, and `corpars` summary components
  for compatibility.
- Reported direct response-scale profile targets such as constant `sigma`,
  constant `rho12`, random-effect SDs, and random-effect correlations.
- Reported fitted response-scale ranges for predictor-dependent or otherwise
  row-varying distributional parameters such as `sigma` and Student-t `nu`.
- Added opt-in confidence intervals:
  - `summary(fit, conf.int = TRUE)` adds Wald intervals for fixed effects;
  - `summary(fit, conf.int = TRUE, method = "profile", ci_parm = ...)` profiles
    selected direct targets such as `sigma`, `rho12`, `sd:mu:(1 | id)`, or
    `cor:mu:cor((Intercept),x | id)`.
- Updated `NEWS.md`, `vignettes/model-workflow.Rmd`, and
  `man/summary.drmTMB.Rd`.

## Mathematical Contract

No likelihood equations, formula grammar, or parameter transformations changed.
The summary table reads fitted quantities from existing extractors and profile
target metadata:

- fixed effects remain on their coefficient scale in `summary(fit)$coefficients`;
- constant `sigma`, `sigma1`, and `sigma2` are shown on the response scale;
- constant residual `rho12` is shown on the response correlation scale;
- random-effect SDs and correlations are shown from `fit$sdpars` and
  `fit$corpars`;
- row-varying distributional parameters are summarized by fitted-row mean,
  minimum, and maximum.

Profile confidence intervals reuse the existing `confint()`/`profile_targets()`
machinery and only attach intervals to targets that were actually profiled.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-summary.R`
- `man/summary.drmTMB.Rd`
- `NEWS.md`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-summary-parameter-table.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 32
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1689 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/summary.drmTMB.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n "summary\\(\\).*fixed-effect estimates|summary\\(\\).*response-scale|conf\\.int|ci_parm|profile-likelihood confidence|Distributional, scale, and correlation parameters|fitted scale, shape|fitted:nu|sd:mu:\\(1 \\| id\\)" R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd NEWS.md vignettes/model-workflow.Rmd pkgdown-site/reference/summary.drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, test, documentation, and generated-site wording.
- `rg -n "summary\\(\\).*fixed-effect estimates, log likelihood|summary\\(\\).*fitted random-effect standard deviations|Reserved for future summary options|Random-effect SDs:|Random-effect correlations:" README.md ROADMAP.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  found no stale non-historical wording.

## Tests Of The Tests

- The new tests check the fast default summary table, fixed-effect Wald
  intervals, a profile interval for a random-effect SD, bivariate residual
  `rho12`, and Student-t `nu` as a shape-range example.
- The profile test uses `ci_parm = "sd:mu:(1 | id)"` so the test exercises the
  expensive interval path without profiling every coefficient.

## Consistency Audit

The public reference page, model-workflow article, NEWS entry, source code, and
unit tests now describe the same contract: estimates are visible by default;
confidence intervals are opt-in; profile intervals require direct profile
targets or explicit `newdata` through `confint()`.

## What Did Not Go Smoothly

The first design was too Gaussian-focused. Adding the Student-t `nu` range test
made the summary table cover shape parameters too, which better matches the
distributional-regression surface we want.

## Team Learning

- Pat: a user should see where the fitted variability, shape, and correlation
  live before learning extractor names.
- Fisher: profile intervals should be deliberate because profiling all direct
  targets can be expensive.
- Boole: `ci_parm` keeps the summary API compact while reusing the existing
  profile target namespace.

## Known Limitations

- Row-varying `sigma`, `rho12`, `nu`, `zi`, `hu`, or `sd(group)` summaries are
  ranges only. Row-specific confidence intervals still belong in
  `confint(..., newdata = ...)`.
- Profile intervals are attached only to currently ready direct targets.
- The summary table is descriptive; it does not yet provide marginal means,
  averaging over covariates, or visual contrasts.

## Next Actions

- Design an `emmeans`-style marginalization layer for `mu`, `sigma`, `nu`, and
  `rho12` after the summary and confidence-interval surfaces settle.
- Build plotting helpers around the same parameter table so mean, scale, shape,
  and coscale summaries can share a visual grammar.
