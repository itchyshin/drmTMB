# After task: refuse a non-identity Gaussian imputation link (#1749)

Reader: a package contributor checking the missing-predictor family gate.

## Task goal

`gaussian(link = "log")` passed `drm_impute_family_type()` and could be fitted
as an identity-scale imputation model. The gate should abort and name the link.
Plain `gaussian()` imputation stays as it is.

## Files

- `R/missing-data.R` (`drm_impute_family_type`)
- `tests/testthat/test-fix-1749-impute-gaussian-link.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-18-fix-1749-impute-gaussian-link.md`

## Checks

`pkgload::load_all()` then
`testthat::test_file("tests/testthat/test-fix-1749-impute-gaussian-link.R")`.

Before the guard: FAIL 2 on the log and inverse links (no error was thrown).
After the guard: FAIL 0, WARN 0, PASS 6. The identity-link `mi(x)` fit
converged.

## Consistency

The abort text matches the identity-link wording proposed for
`drm_family_type()` in the open response-family guard. This branch does not
edit that function. Likelihoods, formula grammar, and the identity-link
Gaussian imputation path are unchanged.

## Tests of the tests

Before the guard, the two rejection expectations failed because no error was
thrown. After the guard they must pass, and a 24-row `mi(x)` fit with
`gaussian()` must still return a finite log-likelihood.

## What did not go smoothly

The first identity-link example omitted `miss_control(predictor = "model")`,
so it aborted for a different reason. The corrected example is the one that
must pass.

## Design, pkgdown, and issues

No design-doc or pkgdown change: the help for `impute_model()` already says
`gaussian()` keeps the continuous predictor route. The issue stays open
(`refs #1749`).

## Limits

A response-family `gaussian(link = "log")` is a separate open guard. This
change covers the imputation classifier only.
