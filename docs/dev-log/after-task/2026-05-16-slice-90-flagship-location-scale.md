# After Task: Slice 90 Flagship Location-Scale Tutorial

## Goal

Deepen `vignettes/location-scale.Rmd` so it works as the flagship tutorial for
interpreting mean slopes, residual-scale slopes, random-slope SDs, `sd(group)`
models, diagnostics, and report-scale quantities without changing model
behaviour.

## Implemented

- Added a response-scale interpretation ladder for fixed mean slopes, fixed
  residual-scale slopes, mean random-slope SDs, residual-scale random-slope SDs,
  and random-effect scale slopes.
- Added a `profile_targets(fit_growth)` chunk to make the interval-target
  inventory part of the fitted-example interpretation gate.
- Added a compact fitted translation table for the growth example, reporting
  the mean-temperature slope, residual-SD habitat ratio, and residual-variance
  habitat ratio on scales a reader can quote.
- Added a hierarchical interpretation checklist distinguishing `sigma ~
  temperature`, `(0 + temperature | population)`, and `sd(population) ~
  habitat`.
- Updated the worked-example inventory, roadmap, and NEWS to mark Slice 90 as
  complete and start the `0.1.2` development NEWS section.

## Mathematical Contract

No formula grammar, likelihood parameterization, TMB code, extractor behavior,
or fitted-model object structure changed. The tutorial now states the existing
Gaussian contract more explicitly:

```text
mu slope                  -> additive response-scale mean change
sigma slope               -> exp(gamma) residual-SD ratio
sigma slope, variance view -> exp(2 * gamma) residual-variance ratio
mu random-slope SD        -> SD of group-specific mean slopes
sigma random-slope SD     -> SD on the log-residual-SD slope scale
sd(group) slope           -> exp(alpha) among-group SD ratio
```

The prose also keeps the current boundary explicit: `sd(population) ~ habitat`
targets an unlabelled `mu` random intercept; coefficient-specific random-slope
SD regression through syntax such as
`sd(population, dpar = "mu", coef = "temperature") ~ habitat` remains reserved.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/37-worked-example-inventory.md`
- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-90-flagship-location-scale.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/37-worked-example-inventory.md vignettes/location-scale.Rmd`
- `pkgdown::build_article("location-scale")`: failed before source-package
  installation because the previously installed local package did not expose
  `profile_targets()`.
- `pkgdown::build_site()`: passed after pkgdown installed the current source
  package into a temporary library; rendered `articles/location-scale.html` and
  `news/index.html`.
- `pkgdown::check_pkgdown()`: passed with "No problems found."
- `devtools::test(filter = "gaussian-(location-scale|random-effect-scale)",
  reporter = "summary")`: passed.
- `git diff --check`: passed.
- Targeted `rg` scans confirmed the source and rendered site include the Slice
  90 interpretation table, `profile_targets(fit_growth)`, `growth_translation`,
  `sd(population) ~ habitat`, and the `0.1.2` development NEWS heading.
- `LC_ALL=C rg -n "[^\\x00-\\x7F]" vignettes/location-scale.Rmd NEWS.md
  docs/design/37-worked-example-inventory.md ROADMAP.md`: returned no matches.

## Tests Of The Tests

No new testthat tests were added because Slice 90 changes tutorial prose and
rendered examples only. The focused Gaussian test run reuses existing tests for
the two model surfaces the tutorial now explains: fixed-effect location-scale
models and random-effect scale models. The rendered pkgdown article also ran
the new vignette chunks that call `profile_targets(fit_growth)` and build the
translation table.

## Consistency Audit

- Ada: Slice 90 stays within Phase 6e tutorial maturation and does not change
  the model surface.
- Boole: all syntax examples remain within the existing one-response Gaussian
  grammar.
- Noether: the symbolic interpretation agrees with the public `sigma` scale and
  explicitly converts variance claims through `sigma^2`.
- Darwin: the prose now separates predictability, thermal reaction norms, and
  among-population variation as distinct biological questions.
- Pat: the tutorial now has a single place to compare `sigma ~ temperature`,
  `(0 + temperature | population)`, and `sd(population) ~ habitat`.
- Grace: pkgdown build/check and focused Gaussian tests passed; the targeted
  article-only render failure is explained as stale local installation state.
- Rose: NEWS now uses a `0.1.2 (development version)` heading so post-0.1.1
  changes are not recorded under the released `0.1.1` heading.

## What Did Not Go Smoothly

`pkgdown::build_article("location-scale")` failed when run directly because it
used the previously installed local `drmTMB` package, which did not yet export
`profile_targets()`. The full `pkgdown::build_site()` path installs the current
source package first and rendered the edited article successfully.

## Team Learning

Grace should prefer full pkgdown builds for article edits that use newly
exported functions, unless the local installed package has just been refreshed.
Rose should keep checking NEWS headings during slice work so release notes do
not drift under a dated release section.

## Known Limitations

Slice 90 did not add a new fitted hierarchical example for `sd(population) ~
habitat`; it clarified how to interpret that implemented surface and its
reserved slope-specific boundary. Slice 91 should stay separate and focus on
the structured-dependence reader route.

## Next Actions

1. Open and merge the Slice 90 PR after GitHub Actions pass.
2. Start Slice 91 on a new branch from `main`, focused on
   `vignettes/phylogenetic-spatial.Rmd`.
3. Use Slice 92 as the Phase 6e gate before any `0.1.2` release preparation.
