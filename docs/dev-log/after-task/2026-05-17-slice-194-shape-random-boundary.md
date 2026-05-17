# After Task: Slice 194 Shape Random-Effect Boundary

## Goal

Make the shape and skewness random-effect boundary explicit before later
skew-normal, skew-t, and comprehensive simulation work depends on it.

## Implemented

- `drm_reject_phase1_terms()` now gives a shape-specific error for random-effect
  bar terms in `nu` or future `tau` formulas.
- Student-t `nu ~ x + (1 | id)` and `nu ~ x + (0 + x | id)` are covered by a
  focused unsupported-boundary test.
- The roadmap, family registry, formula grammar, validation debt register,
  known limitations, README, NEWS, and model map now state that shape random
  effects remain fixed-effect-first and evidence-gated.
- The shape design note separates residual skewness, expressed as `nu ~ x`,
  from future latent ID-level skewness, expressed conceptually as
  `skew(id) ~ x`.

## Mathematical Contract

The implemented Student-t shape model remains

```text
nu_i = 2 + exp(eta_nu_i)
eta_nu_i = X_nu[i, ] beta_nu
```

The slice does not add a random-effect term to `eta_nu_i`. Future skew-normal or
skew-t fixed-effect shape formulas must recover their likelihoods first. A
future `skew(id) ~ x` model would target the distribution of latent group
effects, not the residual distribution, and therefore needs a separate
simulation design.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-student-location-scale.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/19-phylogenetic-location-scale-shape.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/model-map.Rmd`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-student-location-scale.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/19-phylogenetic-location-scale-shape.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd`
- `Rscript -e "devtools::test(filter = 'student-location-scale', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'student-location-scale|nongaussian-scale-boundary|nbinom2-location-scale|lognormal-location-scale|gamma-location-scale|beta-location-scale|beta-binomial|truncated-nbinom2|hurdle-nbinom2|zi-nbinom2', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n 'Shape random effects|shape random effects|ID-level skewness|skew\(id\)|nu random effects|tau random effects|Slice 194|future skew-normal|future skew-t|non-Gaussian sigma and shape' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests`:
  returned intended current boundary rows, tests, and design notes.
- `git diff --check`: passed.

## Tests Of The Tests

The new test checks malformed but plausible Student-t shape formulas before
optimization. It verifies both a random intercept and an independent numeric
random slope in `nu`, so the boundary covers the two random-effect shapes users
are most likely to try first.

## Consistency Audit

README, ROADMAP, the model map, the formula grammar, and the family registry
now agree that Student-t `nu` is fixed-effect-only, future `tau` is second-shape
vocabulary only, and ID-level skewness is a later latent-effect model. The
Slice 193 non-Gaussian `sigma` boundary remains separate from this shape
boundary.

## What Did Not Go Smoothly

The first documentation patch was too broad and failed because the formula
grammar did not have the same reserved-neighbour row as the model-map vignette.
Ada narrowed the patch, then Rose checked the actual status rows with `rg`
before continuing.

## Team Learning

- Ada kept the slice as a boundary and documentation hardening task rather than
  starting a skew-normal likelihood.
- Boole kept `nu` canonical and left `skew(id) ~ x` as future grammar rather
  than a current alias.
- Gauss and Noether kept the likelihood contract fixed: no latent shape random
  effect enters the Student-t objective in this slice.
- Fisher and Curie required a concrete failure-path test for `nu` random
  intercepts and slopes.
- Pat and Darwin pushed the residual versus ID-level skewness distinction into
  reader-facing design text.
- Grace verified pkgdown readiness.
- Rose closed the loop with a stale-wording scan and this after-task report.

## Known Limitations

- No skew-normal or skew-t family is implemented here.
- No random effects in `nu`, future `tau`, or ID-level skewness are fitted.
- No shape random-effect intervals, diagnostics, or simulation recovery results
  exist yet.

## Next Actions

Slice 195 should revisit zero-inflation, hurdle, zero-one inflation, and their
random-effect boundaries, keeping fixed-effect likelihoods and proportion-data
grammar separate from random-effect covariance questions.
