# After Task: Fast Direct Wald, Targeted Profile, and Bootstrap CIs

## Goal

Make the interval API usable for large fitted models after Ayumi's Bergmann
timing report: provide a fast default for direct fixed, scale, SD, and
correlation targets; make targeted profiles easier to run quickly; and add a
bounded `confint()` bootstrap route for selected direct targets.

## What Changed

`confint()` now defaults to direct Wald intervals for fixed-effect
coefficients, constant scale targets such as `sigma`, random-effect SDs,
random-effect correlations, and constant residual `rho12` when the fitted
object has `TMB::sdreport()` covariance. SD intervals are computed on the
fitted log-SD scale and exponentiated. Correlation intervals are computed on
the guarded Fisher-z/atanh scale and transformed back to correlations.

Target-set shortcuts now make long models easier to query:
`"fixed_effects"`, `"random_effects"`, `"variance_components"`, and
`"correlations"`. For expensive profile intervals, `profile_precision =
"fast"` passes `ystep = 0.5` and `ytol = 2` to `TMB::tmbprofile()` unless the
caller supplies different controls. This keeps the reliable profile route
available while giving long phylogenetic or spatial SD targets a quick
first-pass option.

`confint(..., method = "bootstrap")` now simulates from the fitted model,
refits each simulated response with `se = FALSE` by default, extracts the
selected direct target estimates, and returns percentile intervals with
`bootstrap.n`, `bootstrap.failed`, `bootstrap.parallel`, and
`bootstrap.workers` metadata. The smoke tests cover both ordinary grouped SDs
and a scalar `phylo(1 | species, tree = tree)` SD target so the Bergmann-style
route has a small structured-effect check.

## User Value

For large phylogenetic models, the practical path is now explicit:
`confint(fit)` gives the fast direct Wald table; `confint(fit, parm =
"variance_components")` narrows the table to scale and SD targets; targeted
`method = "profile"` can be reserved for SD or correlation rows where
likelihood shape matters; and `profile_precision = "fast"` gives a quicker
profile pass before committing to a slower default profile. Bootstrap is now a
real `confint()` route for direct targets when refit-based uncertainty is worth
the runtime.

## Files Changed

- `R/profile.R`
- `R/methods.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-summary.R`
- `man/confint.drmTMB.Rd`
- `man/summary.drmTMB.Rd`
- `README.md`
- `NEWS.md`
- `vignettes/model-map.Rmd`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`

## Checks

Validation for this slice:

```sh
air format R/profile.R R/methods.R tests/testthat/test-profile-targets.R tests/testthat/test-summary.R README.md NEWS.md docs/design/12-profile-likelihood-cis.md vignettes/model-map.Rmd
Rscript -e "devtools::test(filter = 'profile-targets|summary|control', reporter = 'summary')"
Rscript -e "devtools::document()"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Outcomes:

- Focused tests for profile targets, summary intervals, and controls passed.
- The focused profile-target run includes a tiny scalar phylogenetic bootstrap
  smoke test.
- The full `devtools::test(reporter = "summary")` suite passed.
- `devtools::document()` regenerated `man/confint.drmTMB.Rd` and
  `man/summary.drmTMB.Rd`.
- `git diff --check` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::check(error_on = "never", env_vars =
  c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))` completed with 0 errors, 0 warnings,
  and 0 notes.

## Consistency Audit

The implementation does not change likelihood parameterization or formula
grammar. Wald SD intervals use the same log-SD parameters already optimized by
TMB, and correlation intervals use the same guarded correlation-link
parameters used by the fitted model. Profile intervals still go through
`TMB::tmbprofile()` and remain target-specific. Bootstrap intervals are
available only through `confint()` for direct targets; `summary()`,
`corpairs()`, prediction tables, q4 derived correlations, repeatability, and
phylogenetic signal still need separate interval designs.

The README, model map, NEWS, and profile-likelihood design note now state the
fast direct Wald route, `profile_precision = "fast"`, and the direct-target
bootstrap boundary. Stale wording that said public bootstrap was unavailable
or that fitted-model Fisher-z Wald correlations were not public defaults was
removed from the updated surfaces.

## Standing Review

Ada kept the CI work isolated from the active C++ helper-extraction lane.
Fisher set the default strategy: use Wald for fast routine reporting, profile
selected variance/correlation targets when likelihood shape matters, and use
bootstrap when refit variability is the target. Gauss and Noether checked the
log-SD and Fisher-z/atanh transformations. Emmy checked the S3 and target
contracts. Curie checked the focused tests, including scalar phylogenetic
bootstrap refits. Grace ran the full package validation. Pat and Rose checked
that users can now find the fast route before starting a long profile.

## Known Limitations

The bootstrap path is intentionally narrow. It is not a replacement for a
comprehensive simulation/audit programme, and it is not yet routed through
`summary()`, `corpairs()`, prediction tables, or derived covariance summaries.
Profile intervals can still be slow or one-sided near boundaries; the new
`profile_precision = "fast"` option is a quicker first-pass control, not a new
profile engine.

## Next Actions

The next inference slices should audit derived intervals, q4 covariance
functions, and bootstrap coverage separately. The next documentation slice
should add a concise user example that compares `confint(fit)`,
`confint(fit, parm = "variance_components")`, a targeted
`profile_precision = "fast"` profile, and a small bootstrap call on the same
model.
