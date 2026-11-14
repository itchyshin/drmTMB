# After Task: formula NaNs take their weights with them (#1725)

## Goal

Stop a `NaN` created inside a formula, such as `log(x)` of a negative
predictor, from dropping response rows while the likelihood still uses the
weights of the first `nobs` rows.

## Implemented

After each family's model frames are built, `drm_apply_model_frame_rows()`
compares the rows `na.omit` kept. If the frames agree and they are a proper
subset of the modelled data, the function subsets the modelled data, the
weights, the original-row index `keep`, and the known sampling covariance.
If the frames disagree, fitting aborts with class `drmTMB_model_frame_rows`
and names the row counts. `na.pass` frames, used by the missing-response
path, have no `na.action` and are left unchanged when they still have one
row per modelled observation.

## Mathematical Contract

The likelihood is the weighted log-density of the rows the model frame
retained. For the six-row Poisson fixture in #1725 the retained rows are
1, 3, 4 and 6, and the log-likelihood matches
`sum(w[keep] * dpois(count[keep], exp(eta), log = TRUE))` within 1e-6.
No distributional density, link, or formula token changed.
`docs/design/01-formula-grammar.md` and `docs/design/03-likelihoods.md`
were not edited.

## Files Changed

- `R/drmTMB.R`: helpers and one call in each univariate builder and in the
  bivariate Gaussian builder. Bivariate lognormal and Student-t go through
  that Gaussian builder. The Student-t `nu` frame still aborts through the
  existing row-count check when it drops extra rows.
- `tests/testthat/test-fix-modelframe-weight-rows.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-12-fix-modelframe-weights.md`

## Checks Run

Recorded in the check-log shard. The new file passes (6 tests, 18
expectations). The nearby Gaussian, Poisson, binomial, Student-t, Gamma,
meta-analysis, missing-response, offset, and #1697 files passed with 0
failures. `test-gaussian-location-scale.R` and `test-offset-families.R`
were repeated with `NOT_CRAN=true` so `skip_on_cran()` did not hide them.

## Tests Of The Tests

The same file was run against `R/drmTMB.R` at `98717b68c` before the fix.
Five tests failed or errored. `log() of strictly positive x still weights
every row` passed on main and after the fix. The Poisson test compares the
log-likelihood with `stats::dpois` on the retained rows. The Gaussian and
`meta_V` tests compare the fit with an explicit pre-dropped data set.

## Consistency Audit

Searched `docs/` for `complete.cases`. The hits are historical notes or the
missing-data design, which still correctly says the first filter is
`complete.cases()`. That filter does not see `NaN`s created by a transform,
which is the bug this change closes. No README, roadmap, vignette, or
pkgdown navigation change. No roxygen change, so `devtools::document()` was
not run. No new exported function.

## GitHub Issue Maintenance

#1725 describes this bug. The six-row comments in the issue body match a
fresh run on main (`nobs` 4, weight length 6, log-likelihood -7.457925
versus retained-row reference -8.95574). No correction comment.

## What Did Not Go Smoothly

A first Gaussian assertion compared `logLik()` with `dnorm()` at the fitted
coefficients. On six rows the residual SD collapsed toward 0 on two points,
`dnorm()` went to a huge value, and the TMB objective stayed finite. The
test now compares the fit with the same model on the rows a user would drop
by hand, and checks that the stored weights are those rows' weights.

## Team Learning

A length check on `weights` is not enough. The regression has to name the
retained rows' weights, or compare the fit with a pre-dropped data set.
Recorded here rather than in `docs/dev-log/team-improvements.md` because it
is a test lesson for this bug, not a new team process.

## Known Limitations

`sd()` formulas are built later, on the already aligned data. A non-finite
transform that appears only in an `sd()` formula can still shorten that
scale frame after the observation weights have been aligned. Bivariate
Student-t `nu` uses the existing abort when its frame is shorter than `y1`.
The Julia bridge has its own row helper and was not changed.

## Next Actions

Draft pull request for #1725. Further finite-design leaks for families other
than Gaussian are separate issues (#1710 for Student-t and skew-normal).
