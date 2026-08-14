# After Task: joint continuous missing predictors

## 1. Goal

Implement `impute_joint(cbind(x1, x2) ~ z)` for exactly two correlated
continuous missing predictors in a Gaussian response, then add a separate
Poisson proof route with the same public grammar.

## 2. Implemented

`bf(y ~ z + mi(x1) + mi(x2), sigma ~ 1)` now accepts
`impute = impute_joint(cbind(x1, x2) ~ z)` with
`missing = miss_control(predictor = "model")`. The route estimates two
fixed-effect Gaussian predictor models, their two residual scales, and their
residual correlation. `imputed(fit, "x1")` and `imputed(fit, "x2")` return
the fitted conditional modes. The same continuous latent block has a separate
ordinary-Poisson proof route; it does not widen other non-Gaussian families.

## 3a. Decisions and Rejected Alternatives

For each row, `(x1, x2)` follows a bivariate Gaussian predictor model with
means from the common imputation design, two residual SDs, and a transformed
correlation. The Gaussian response route uses the observed-data likelihood;
TMB/Laplace is exact for this Gaussian latent block. The Poisson proof route
uses the same latent block with TMB/Laplace integration of the count response.
`docs/dev-log/2026-08-13-joint-mi-two-predictor-alignment.md` records the
equations, R grammar, and TMB quantities together.

`impute_joint()` was chosen rather than two independent `impute` list entries
because the residual correlation is part of the fitted model. Interactions, a
third predictor, mixed predictor families, response masks, grouped or
structured joint imputation, and REML were rejected for this route.

## 4. Files Touched

- `R/missing-data.R`, `R/drmTMB.R`, and `src/drmTMB.cpp`: parser, payload,
  likelihood, parameter extraction, and missing-predictor finalization.
- `tests/testthat/test-missing-predictor-gaussian.R` and
  `tests/testthat/test-missing-predictor-poisson-response.R`: likelihood,
  grammar, extractor, recovery-smoke, and Poisson proof tests.
- `R/formula-markers.R`, `README.md`, `NEWS.md`, `_pkgdown.yml`, generated
  reference files, and `docs/design/01-formula-grammar.md`: public scope and
  reference-index updates.

## 5. Checks Run

- `devtools::document()` completed and generated `impute_joint.Rd`.
- Focused Gaussian and Poisson tests: 161 pass, 0 fail, 0 warn, 0 skip.
- All `missing-predictor` tests: 461 pass, 0 fail, 0 warn, 0 skip.
- `pkgdown::check_pkgdown()`: passed after adding `impute_joint` to the
  reference index.
- `Rscript ~/Dropbox/Github\ Local/Shinichi/tools/rose-pattern-scan.R`:
  passed.
- `git diff --check`: passed.
- A local `devtools::check(args = "--no-manual")` was started and reached
  build/install, but the local runner did not return a final receipt. It is
  not claimed as green.

## 6. Tests of the Tests

The Gaussian test compares the fitted TMB objective to an independent R
observed-data multivariate-normal likelihood over the observed predictor
patterns. It also checks missing-value storage sentinels and unsupported
grammar forms. The recovery smoke
uses a fixed seed, 600 rows, independent missingness in both predictors, and
checks response coefficients, imputation slopes, correlation, and gradient.
The Poisson tests exercise the continuous latent path separately and reject
response masking.

## 8. Consistency Audit

The status inventory was searched with:

```sh
rg -n -i "impute_joint|joint.*mi\(|two.*missing predictor|multiple.*mi\(|missing predictor" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml R man tests
```

The formula grammar, README, NEWS, known limitations, package help, and
pkgdown reference index now describe the exact two-continuous-predictor
exception. Historical NEWS entries were left unchanged.

## 7a. Issue Ledger

Open issue `#963`, “missing-data: allow more than one mi() term per fit”, is
the matching tracker. No comment or closure was made because this branch is
not yet committed or reviewed. Its wider `k >= 2` and mixed-family request
remains open.

## 9. What Did Not Go Smoothly

The first joint fit exposed scalar-only finalization and coefficient extraction
paths. The first Poisson fit also exposed that the joint likelihood had been
wired only in the Gaussian TMB branch. Both were repaired before the focused
tests were added. Pkgdown then identified the missing reference-index entry.

## 11. Team Learning

A second `mi()` term is not only a formula-parser change: the predictor model,
TMB data contract, random latent-vector ordering, extractors, and public
capability inventory must all change together. The independent Gaussian oracle
was the fastest way to check that the latent-vector ordering and correlation
parameterization matched the intended likelihood.

## 10. Known Residuals

The joint route accepts exactly two bare continuous predictors with common
fixed-effect imputation terms. It does not accept interactions, a third or
mixed-type predictor, grouped or structured joint imputation, response masks,
or REML. The Poisson route further excludes zero inflation and response random
or structured terms. Joint conditional standard errors are not exposed yet.

## 12. Cross-Product Coverage

This work covers a fixed-effect joint Gaussian predictor model with two bare
continuous `mi()` terms, for a Gaussian response and one ordinary Poisson proof
route. It does NOT cover response masking, REML, offsets, sparse matrices,
aggregation, zero inflation, response random or structured terms in the Poisson
route, grouped or structured joint imputation, additional predictors, or other
non-Gaussian response families. Joint conditional standard errors are also not
covered.

## Next Actions

**SUPERSEDED in part by the completed Totoro campaign.** The local 600-row
recovery smoke was followed by the preregistered 3,000-attempt Gaussian MCAR
campaign on Totoro, which supports `point_fit_recovery` only for the narrow
MD9b route. The Poisson route remains an experimental numerical proof, not a
recovery claim. See
`docs/dev-log/2026-08-13-joint-mi-gaussian-recovery-completion.md`. Still
needed before merge: a package check with a retained final receipt, branch
review, and an update to issue `#963` that leaves its wider request open.
