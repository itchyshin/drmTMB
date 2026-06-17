# Skew-Normal Fixed-Effect First Slice

## Task Goal

Make `skew_normal()` a working first-slice family rather than a design-only
placeholder. The intended surface is univariate and fixed-effect: public
`mu = E[y]`, public `sigma = SD[y]`, and residual slant `nu` on the identity
scale.

## Files Changed

- `R/family.R`, `R/drmTMB.R`, `R/methods.R`, `R/check.R`, and
  `src/drmTMB.cpp` add the constructor, builder, TMB likelihood branch,
  simulation, fitted-value, scale, residual, interval-target, and diagnostic
  paths.
- `tests/testthat/helper-skew-normal-density.R`,
  `tests/testthat/test-skew-normal-density-contract.R`,
  `tests/testthat/test-skew-normal-location-scale.R`,
  `tests/testthat/test-family-link-contract.R`, and
  `tests/testthat/test-student-location-scale.R` cover density, recovery,
  methods, unsupported neighbours, and shared shape-boundary wording.
- `README.md`, `NEWS.md`, `ROADMAP.md`, `_pkgdown.yml`,
  `vignettes/distribution-families.Rmd`, `docs/dev-log/known-limitations.md`,
  and the relevant `docs/design/` notes synchronize the public status.
- `man/skew_normal.Rd` is new; existing generated Rd topics for `drmTMB()`,
  `sigma()`, and `check_drm()` were regenerated.

## Checks Run

```sh
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'devtools::test(filter = "skew-normal|family-link-contract|student-location-scale", reporter = "summary")'
Rscript --vanilla -e 'invisible(lapply(c("man/skew_normal.Rd", "man/drmTMB.Rd", "man/sigma.drmTMB.Rd", "man/check_drm.Rd", "man/model-fit-extractors.Rd", "man/beta.Rd"), tools::checkRd)); cat("checkRd_ok\n")'
rg -n 'skew_normal\(\).*(not implemented|not fitted|absent|planned, not fitted|future)|Planned Skew-Normal|skew-normal.*not implemented|no `skew_normal\(\)` constructor|skew_normal.*future work|without adding `skew_normal\(\)`|keep `skew_normal\(\)` absent|No `skew_normal\(\)` constructor|future skew-normal' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md'
git diff --check
Rscript --vanilla -e 'devtools::test(reporter = "summary")'
Rscript --vanilla -e 'pkgdown::check_pkgdown(); cat("pkgdown_check_ok\n")'
Rscript --vanilla -e 'devtools::check(document = FALSE, manual = FALSE, error_on = "never")'
```

Outcomes:

- Focused skew-normal, family-link, and Student-t shape-boundary tests passed.
- `tools::checkRd()` printed `checkRd_ok`.
- The stale constructor-absence scan returned no matches.
- `git diff --check` reported no whitespace problems.
- Full `devtools::test()` passed.
- `pkgdown::check_pkgdown()` reported no problems and printed
  `pkgdown_check_ok`.
- `devtools::check(document = FALSE, manual = FALSE, error_on = "never")`
  finished in 12m 18s with 0 errors, 0 warnings, and 0 notes.
- After rebasing onto `origin/main` at `feec1049`, the only conflict was the
  check-log append. The rebased branch passed `git diff --check`, conflict
  marker scan, stale constructor-absence scan, Rd checks, focused
  `skew-normal|family-link-contract|student-location-scale` tests, and
  `pkgdown::check_pkgdown()`.

## Consistency Audit

The fixed-effect family status now agrees across the constructor docs, family
registry, likelihood contract, family-link contract, README status table,
family tutorial, NEWS, ROADMAP, pkgdown reference index, known limitations, and
generated Rd. Historical Phase 18 notes that previously required the
constructor to be absent are marked as superseded rather than deleted.

## Tests Of The Tests

The tests exercise the likelihood and methods from multiple angles:

- density normalization, Gaussian normal limit, sign orientation, native-density
  comparison, and TMB tail floor;
- deterministic fixed-effect recovery for weak, positive, and negative skew;
- factor and correlated predictors, predictor-dependent `nu`, and a Gaussian
  false-positive boundary;
- independent R-likelihood objective comparison with weights;
- `profile_targets()`, `confint()`, `summary()`, `predict_parameters()`,
  `simulate()`, residuals, `fitted()`, and `sigma()`;
- explicit rejection of random effects, `sd(group)`, known covariance,
  bivariate responses, `rho12`, `skew` aliases, and latent `skew(id)`.

## What Did Not Go Smoothly

Roxygen 7.3.2 tried to add a `RoxygenNote` field and changed a few unrelated Rd
links. Those generated-noise changes were removed so the diff stays focused on
skew-normal support.

The broad `devtools::check()` repeated the full test suite and took 12m 18s.
That was worth keeping because this slice exports a new family and adds a TMB
branch.

## Team Learning

The stale-claim scan should remain part of every capability slice. It caught
old Phase 18 instructions that would otherwise have told a future agent to keep
`skew_normal()` absent after the constructor existed.

## Design And Documentation Updates

The docs now teach the public moment parameterization and name the native TMB
transform to `xi`, `omega`, and `alpha = nu`. The tutorial gives a fixed-effect
example and explains that positive `nu` indicates right-skewed residuals,
negative `nu` indicates left-skewed residuals, and `nu = 0` gives the Gaussian
location-scale likelihood.

## GitHub Issue Maintenance

This work belongs to issue #3. It should be referenced by the PR but should not
close #3, because the issue still covers formal operating-characteristic
evidence, external fitted-model comparators, random effects, structured effects,
known covariance, bivariate skew-normal support, residual `rho12`, latent
`skew(id)`, and alias decisions.

## Known Limitations And Next Actions

The current implementation is a source-tested first slice, not a mature
general-purpose skew-normal programme. Next capability-depth slices should add a formal
multi-replicate skew-normal recovery artifact lane, then an external
fitted-model comparator audit if dependency and scale-map constraints are
acceptable. Only after those gates should the project consider random effects,
structured effects, bivariate skew-normal models, or alias grammar.
