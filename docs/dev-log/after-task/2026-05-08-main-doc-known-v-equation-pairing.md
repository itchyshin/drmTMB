# After Task: Main Documentation Known-`V` Equation Pairing

## Goal

Make the main user-facing documentation show the symbolic bivariate
known-sampling-covariance model next to the R syntax, so users can see exactly
what `meta_known_V(V = V)`, `meta_vcov_bivariate()`, `sigma1`, `sigma2`, and
`rho12` mean together.

## Implemented

- Added the row-paired stack definition
  `y_stack = (y1_1, y2_1, ..., y1_n, y2_n)'` to the README and main overview
  vignette.
- Paired that stack with the likelihood
  `y_stack ~ MVN(mu_stack, V + Omega_stack)`.
- Paired the equation with the matching R syntax using
  `meta_vcov_bivariate()` and `meta_known_V(V = V)`.
- Clarified that the long-term bivariate random-effect example in the formula
  grammar is future-facing, not the current implemented bivariate
  random-effects surface.

## Mathematical Contract

For complete-row bivariate Gaussian meta-analysis,

```text
y_stack = (y1_1, y2_1, ..., y1_n, y2_n)'
y_stack ~ MVN(mu_stack, V + Omega_stack)

Omega_i =
  [sigma1_i^2,                 rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,  sigma2_i^2]
```

Here `V` is known sampling covariance and `Omega_stack` is the fitted residual
or between-study covariance implied by `sigma1`, `sigma2`, and `rho12`.

## Files Changed

- `README.md`
- `vignettes/drmTMB.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `git diff --check`: clean
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: 84 passed, 0 failed
- `Rscript -e "pkgdown::build_site()"`: completed
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes

## Tests Of The Tests

No new tests were added because this task changed only documentation. The
targeted bivariate suite was rerun because the prose describes the just-added
bivariate known-`V` likelihood and its existing tests include independent
likelihood comparison, residual-`rho12` recovery, missing-row subsetting, and
malformed-input rejection.

## Consistency Audit

- The README and overview vignette now use the same row-paired equation and
  matching syntax.
- The generated pkgdown home page and overview article contain the same new
  equation after `pkgdown::build_site()`.
- Active public docs no longer describe bivariate known sampling covariance as
  planned-only.
- Historical dev-log entries that were true when written were left unchanged.

## What Did Not Go Smoothly

One stale-wording search used backticks inside a shell double-quoted pattern,
which the shell tried to execute. The search was repeated with safer quoting.
For future audits, patterns containing backticks should use single quotes or a
plain pattern file.

## Team Learning

- Noether's equation-first habit should become the default for every model
  surface: symbolic equation, R syntax, then interpretation.
- Pat's reader view caught the need to define row-pairing, not just write
  `2n` by `2n`.
- Rose's after-task checklist remains useful even for documentation-only
  changes, because generated pkgdown pages can lag behind source files.

## Known Limitations

- The public examples still use abstract variable names such as `x1`; later
  tutorials should add more ecology, evolution, and environmental-science
  examples around real questions.
- Bivariate random effects remain future-facing, and the grammar docs should
  keep that status explicit until they are implemented and tested.

## Next Actions

- Address the broader formula-status drift flagged by Tesla: current support
  for `mvbind()`, implemented univariate `phylo()`, and planned bivariate
  random effects should be summarized in one status table.
- Add more equation/syntax/interpretation triads to the main overview,
  especially for `sigma`, `sd(group)`, and `rho12`.
