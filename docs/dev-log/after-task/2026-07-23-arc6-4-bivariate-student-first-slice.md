# After Task: Arc 6.4 exact bivariate Student-t first slice

## 1. Goal

Implement one bounded exact bivariate Student-t family from the commit that
landed Arc 6.3. The headline estimand is `rho12`, the scatter/residual
correlation under one shared degrees-of-freedom parameter. At finite `nu`,
`rho12 = 0` means uncorrelated, not independent, because the two margins share
one scale-mixture draw.

## 2. Implemented

`biv_student()` is a distinct exact-special family and TMB model type. It
admits complete finite pairs, fixed-effect `mu1` and `mu2`, intercept-only
`sigma1`, `sigma2`, one shared `nu`, and intercept-only `rho12`. `fitted()`
returns the two marginal means, and `simulate()` uses one shared chi-square
mixing draw per pair.

## 3a. Decisions and Rejected Alternatives

The family uses an elliptical bivariate Student-t distribution with Student-t
scales and one shared `nu = 2 + exp(eta_nu)`. It does not reuse
`associate_pairs()`, because frozen-margin latent-normal `eta` is a different
estimand. Separate `nu1` and `nu2`, raw-scale correlation language, Gaussian
residual whitening, and early capability promotion were rejected. A
general-purpose gamma-ratio implementation was replaced by the exact
two-dimensional cancellation to protect the Gaussian limit.

## 4. Files Touched

The implementation changes the family constructor, model dispatch and builder,
TMB likelihood, numeric helpers, methods, diagnostics, parameter prediction,
and profile fences under `R/` and `src/`. It adds
`tests/testthat/test-biv-student.R`, design contract 234, and a cited prior-art
report. Generated `NAMESPACE` and Rd files accompany the new export. NEWS,
roadmap, family registry, link contract, formula grammar, likelihoods, source
map, limitations, Arc 6 overview, and family/formula vignettes now state the
same bounded scope.

## 5. Checks Run

- `devtools::document(quiet = TRUE)`: PASS.
- `devtools::test(filter = "biv-student", reporter = "summary")`: PASS,
  68 expectations.
- Adjacent `biv-lognormal`, `family-link-contract`, and
  `student-location-scale` tests: PASS; one pre-existing singular-convergence
  warning.
- Direct `test-biv-gaussian.R`: PASS; two pre-existing deprecation warnings.
- Direct `test-profile-targets.R`: PASS after the validation-order repair; two
  pre-existing warnings and one CRAN skip.
- `python3 tools/capability_ledger.py --check`: PASS, 30 outputs.
- `git diff --check`: PASS.
- The first full check had one failure after 16,580 passes, 288 skips, and 62
  warnings. That failure exposed the repaired `profile_targets(list())`
  validation-order bug.
- Final `devtools::check(error_on = "warning", document = FALSE, manual =
  FALSE)`: PASS in 15m57s with 0 errors, 0 warnings, and one benign macOS
  temporary-directory note for `xcrun_db`.
- The after-task structure validator: PASS.

## 8. Consistency Audit

The closeout stale-surface search is:

```sh
rg -n 'bivariate Student-t models? (remain|are) (planned|later)|bivariate Student-t.*planned|future exact special model|Arcs 6\.1.*6\.2.*only implemented|6\.3--6\.8' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man tests/testthat --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/handover/**'
```

The family, grammar, registry, likelihood, link, limitation, NEWS, roadmap,
source-map, Arc 6 overview, vignette, roxygen, and generated-reference surfaces
were checked. No README or pkgdown-navigation entry was added because this is a
bounded development slice without a tutorial or capability claim.

## 6. Tests of the Tests

The source test compares package `logLik()` with an independent closed-form
bivariate-t density and with `mvtnorm::dmvt()`. A direct TMB objective test
exercises `nu = 1e15`, where naive gamma subtraction loses precision. The suite
also checks univariate marginal reduction, response swapping, unequal scales,
high absolute correlation, `nu` near two, the Gaussian limit, shared-mixture
simulation, and non-factorization when finite `nu` meets `rho12 = 0`.

Negative tests exercise zero-intercept predictors in every constrained
distributional parameter and reject missing/non-finite pairs, weights, offsets,
ordinary random effects, structured effects, `mi()`, `meta_V()`, REML, Julia,
residuals, distribution-output helpers, and every interval/profile entry
point.

## 9. What Did Not Go Smoothly

NotebookLM first failed its authentication/network check; after approved
authentication it produced the required cited report. Gauss's review caught
catastrophic gamma-term cancellation at very large `nu` and a one-column model
matrix loophole that admitted `~ 0 + x`. Fisher's review caught profile-ready
summary leakage, silent `mi()` row dropping, and Gaussian residual whitening
that is invalid when `sigma1` and `sigma2` are Student-t scales. Rose found the
same residual neighbour and stale weights prose. Each defect was repaired
before the final verification rerun.

The first full package check then exposed an inherited invalid-object ordering
bug in `profile_targets()`. Moving class validation ahead of the exact-special
family fence repaired it without widening this arc.

The final requirement-by-requirement completion audit found one stale label in
design 234's alignment table: it called `rho12` a Gaussian scatter correlation
despite the surrounding Student-t contract. The label now says Student-t
scatter/residual correlation; the equations, code, tests, and other
documentation already used the intended estimand.

## 11. Team Learning

For a two-dimensional Student-t density, algebraic simplification is more
stable than general-purpose gamma arithmetic: the normalizing gamma ratio
cancels exactly. Formula admissibility must inspect the terms object, not only
the model-matrix column count, because `~ 0 + x` can masquerade as a
one-column intercept-only formula.

An exact-special family also needs a complete public-method fence. Student-t
scales do not justify Gaussian Pearson whitening, and a top-level `confint()`
error is insufficient if summaries or internal profile selectors still report
targets as ready.

## Design-Doc Updates

Design 234 is the symbolic/API/oracle contract. Designs 01, 02, 03, 46, 109,
and 230 now register the family and preserve its exclusions. The prior-art
report records the multivariate-t parameterization, shared-mixture dependence,
and comparator sources.

## pkgdown and Documentation Updates

Roxygen output, family and formula vignettes, NEWS, roadmap, known limitations,
and the source map were synchronized. `pkgdown::check_pkgdown()` was not
required by this source-only slice and was not used as evidence. No tutorial,
reference-index category, or public capability claim was added.

## 7a. Issue Ledger

An open-issue search found no issue specifically tracking `biv_student()` or
Arc 6.4. The tracker was deliberately left unchanged; this source-tested slice
does not close a recovery, inference, release, or broad bivariate-family issue.

## 10. Known Residuals

The family has one shared intercept-only `nu`; separate marginal degrees of
freedom are unsupported. Predictors in `sigma1`, `sigma2`, `nu`, or `rho12`,
random and structured effects, partial pairs, weights, offsets, `meta_V()`,
`mi()`, REML, Julia, residuals, distribution-output helpers, intervals,
coverage, recovery, capability promotion, and CRAN claims remain deferred.

Stop at source verification. A later smoke requires separate owner approval;
any retained-attempt recovery campaign requires a fresh plan and DRAC
authorization.

## 12. Cross-Product Coverage

Arc 6.4 changes only `drmTMB`. The gllvmTMB and Julia implementations were
surveyed for reusable exact bivariate Student-t code and had none; they remain
unchanged and are not required backends. Arc 6.3 remains the landed
prerequisite, and its bivariate-lognormal regression tests pass. No
cross-repository mirror, claim, or compute receipt was created.

This slice does NOT cover the Julia engine, gllvmTMB, REML, penalties,
missing-response aggregation, partial pairs, weighted likelihoods, random or
structured effects, intervals, coverage, recovery, or capability promotion.
