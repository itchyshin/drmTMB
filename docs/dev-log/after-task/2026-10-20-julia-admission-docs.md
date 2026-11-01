# After task: Julia engine admission wording (#1569)

Reader: a user deciding whether `engine = "julia"` fits their model.

## What changed

- `@param engine` (and `man/drmTMB.Rd`) now also names `skew_normal()`,
  `cumulative_logit()`, `biv_student()`, and `biv_lognormal()`, matching
  `R/julia-family-registry.R`.
- `julia-engine.Rmd` no longer says `skew_normal()` is unavailable.
- `distribution-families.Rmd` and `proportion-beta-binomial.Rmd` no longer say
  plain binomial rejects `engine = "julia"`; they say it fits fixed effects only.
- `model-map.Rmd` drops "or Julia bridge" from the binomial gap.

## Tests

`tests/testthat/test-julia-admission-docs.R`: 8 failures on main, 12 passes now.

## Not done

The issue's ideal fix is to generate the family list from the registry. That is
a larger change and is left open (#1569 stays "Part of").
