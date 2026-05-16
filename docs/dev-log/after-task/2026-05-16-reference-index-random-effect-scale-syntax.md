# After Task: Reference Index Random-Effect Scale Syntax

## Goal

Fix a user-caught Reference-index omission: `sd(id) ~ ...` and related
random-effect scale formulas were documented inside tutorials and examples, but
the Reference page did not give them a dedicated topic.

## Implemented

- Added `R/random-effect-scale-formulas.R` as a docs-only roxygen topic.
- Documented `sd(group)`, `sd1(group)`, `sd2(group)`,
  `sd_phylo(species)`, `sd_phylo1(species)`, and `sd_phylo2(species)` as
  formula syntax captured by `bf()` / `drm_formula()`.
- Stated that `sd(group) ~ predictors` does not replace `stats::sd()`.
- Added the topic to `_pkgdown.yml` under the Reference-index marker section.

## Mathematical Contract

The topic states that random-effect scale formulas model latent random-effect
standard deviations. They are distinct from residual scale formulas such as
`sigma ~ predictors`, latent correlation formulas such as `corpair()`, and the
`corpairs()` extractor.

## Checks Run

- `Rscript -e 'devtools::document()'`: passed.
- `air format _pkgdown.yml R/random-effect-scale-formulas.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-reference-index-random-effect-scale-syntax.md`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgdown::build_site()'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with `0 errors | 0 warnings | 0 notes`.
- `rg -n 'random_effect_scale_formulas|sd\\(group\\)|sd_phylo1|corpair\\(\\)|corpairs\\(\\)' pkgdown-site/reference/index.html pkgdown-site/reference/random_effect_scale_formulas.html _pkgdown.yml man/random_effect_scale_formulas.Rd`:
  confirmed the rendered topic and neighbouring correlation entries.

## Tests Of The Tests

No implementation test was added because this is a documentation-only reference
index patch. The useful check is rendered-site evidence: the pkgdown Reference
index now contains the new random-effect scale formula topic, while `corpair()`
and `corpairs()` remain visible in their appropriate sections.

## What Did Not Go Smoothly

The earlier Slice 96 audit treated pkgdown success as sufficient. That was too
mechanical: `pkgdown::check_pkgdown()` can pass even when formula-only syntax
is hard for readers to find.

## Team Learning

Rose should add a Reference-index semantic pass to documentation slices. Pat
should scan the Reference page as a new user would, especially for syntax that
is parsed but not exported as an ordinary function. Ada should not treat article
navigation and Reference navigation as interchangeable.

## Known Limitations

This patch does not change parser behavior, supported syntax, likelihood code,
or exported functions. It only makes existing formula syntax discoverable.

## Next Actions

1. Push the updated Slice 96 PR and rerun CI.
2. For future docs slices, include a rendered Reference-index scan before the
   after-task report is closed.
