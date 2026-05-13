# After Task: Bivariate Covariance Block Label Guard

## Goal

Prevent the current bivariate Gaussian grammar from accepting syntax that looks
like a full cross-parameter covariance block before that likelihood is
implemented.

## Implemented

Added `reject_biv_cross_parameter_label_reuse()` to reject the same labelled
random-intercept block on the same group when all four bivariate formulas use
it, such as `(1 | p | id)` in `mu1`, `mu2`, `sigma1`, and `sigma2`. The error
tells users to use distinct labels for the current separate mean-mean and
scale-scale blocks. I also added a negative test for random-effect syntax in
`rho12`, which should stay a within-observation residual correlation.

## Mathematical Contract

The implemented bivariate model has at most one same-parameter mean-mean block
and one same-parameter scale-scale block. It does not yet fit a single
cross-parameter covariance matrix for `mu1`, `mu2`, `sigma1`, and `sigma2`.
Residual `rho12` remains row-level and is not a group-level random-effect
correlation.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-covariance-label-guard.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  229 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2008 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

A live pre-edit probe showed that `(1 | p | id)` in all four bivariate formulas
was previously accepted and produced two `corpairs()` group rows with the same
block label. The new negative test exercises that exact pattern, so it would
fail if the guard stopped firing. The `rho12` random-effect test checks an
already rejected path so the intended residual-correlation message stays
covered.

## Consistency Audit

I checked the guard and scope wording with:

```sh
rg -n "Reusing one bivariate|same-label pattern|same label and grouping variable|cross-parameter bivariate covariance|rho12.*within-observation" R/drmTMB.R tests/testthat/test-biv-gaussian.R NEWS.md docs/design/01-formula-grammar.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md docs/dev-log/known-limitations.md vignettes
rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
```

`NEWS.md` and `docs/design/01-formula-grammar.md` now document the distinct
label requirement for the current bivariate same-parameter covariance slices.

## What Did Not Go Smoothly

The previous implementation accepted a syntax pattern that was computationally
well-defined but semantically too easy to misread. The fix was small, but it
needed a user-facing NEWS note because it intentionally rejects a previously
accepted formula.

## Team Learning

Boole's syntax lens matters before Gauss expands the likelihood. If a label
could reasonably imply a larger covariance block, the grammar should either fit
that block or reject the syntax clearly.

## Known Limitations

This guard does not implement cross-parameter bivariate covariance, bivariate
random slopes, random effects in `rho12`, or structured phylogenetic/spatial
covariance. It only protects the current labelled-intercept surface from an
ambiguous same-label request.

## Next Actions

The next slice can either start the smallest true cross-parameter covariance
design, or add more comparator evidence around the currently implemented
separate mean-mean and scale-scale blocks before expanding the likelihood.
