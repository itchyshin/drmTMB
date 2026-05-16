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
- Added a trait-named teaching block, grounded in the PLSM paper's parrot
  example, that defines `beak_length`, `body_mass`, `forest`, `mu`, `sigma`,
  `beta_forest^(mu)`, and `beta_forest^(sigma)` before translating those
  coefficients into biological claims.
- Recorded paper-grounded location-scale meta-analysis polish as a separate
  later tutorial route rather than inserting known-`V` meta-analysis material
  into the flagship location-scale page.
- Recorded the planned `meta_V()` umbrella as future design space only:
  additive known covariance remains current `meta_known_V(V = V)`,
  proportional sampling variance such as `pi_i ~ Normal(0, phi_pi / w_i)` is
  not implemented, and neither branch is CRAN-blocking for `0.1.2`.
- Updated the worked-example inventory, roadmap, and NEWS to mark Slice 90 as
  complete and start the `0.1.2` development NEWS section.

## Mathematical Contract

No implemented formula grammar, likelihood parameterization, TMB code, extractor
behavior, or fitted-model object structure changed. The tutorial now states the
existing Gaussian contract more explicitly:

```text
mu slope                  -> additive response-scale mean change
sigma slope               -> exp(gamma) residual-SD ratio
sigma slope, variance view -> exp(2 * gamma) residual-variance ratio
mu random-slope SD        -> SD of group-specific mean slopes
sigma random-slope SD     -> SD on the log-residual-SD slope scale
sd(group) slope           -> exp(alpha) among-group SD ratio
```

The parrot beak-length block keeps the same public-scale contract:
`beta_forest^(sigma)` is a log-residual-SD contrast, so
`exp(beta_forest^(sigma))` is the residual-SD ratio and
`exp(2 * beta_forest^(sigma))` is the residual-variance ratio. The prose
explicitly separates this from `beta_forest^(mu)`, the mean beak-length
contrast.

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
- `pdfinfo` and `pdftotext` on the local Methods in Ecology and Evolution PLSM
  paper: inspected the parrot beak-length, forest habitat, body mass, range
  size, and beak-trait examples before the final prose polish.
- `pdfinfo` and `pdftotext` on the local Global Change Biology
  location-scale meta-analysis paper and the distributional-regression
  meta-analysis manuscript: inspected enough to record meta-analysis as a
  separate later article route.
- `sed`/`rg` on `/Users/z3437171/Dropbox/Github Local/unifying_model/R/unifying.html`:
  inspected the proportional sampling-variance and weighted covariance notes
  before reserving the future `meta_V()` design.
- `git diff --check`: passed.
- Targeted `rg` scans confirmed the source and rendered site include the Slice
  90 interpretation table, parrot beak-length parameter definitions,
  `profile_targets(fit_growth)`, `growth_translation`, `sd(population) ~
  habitat`, and the `0.1.2` development NEWS heading.
- `LC_ALL=C rg -n "[^\\x00-\\x7F]" vignettes/location-scale.Rmd NEWS.md
  docs/design/37-worked-example-inventory.md ROADMAP.md`: returned no matches.
- Final `air format` across NEWS, ROADMAP, formula/meta-analysis design docs,
  worked-example inventory, edited vignettes, check log, and this after-task
  report: passed.
- Final `git diff --check`: passed.
- Final patch-only non-ASCII scan using `git diff ... | LC_ALL=C rg -n
  "[^\\x00-\\x7F]" || true`: returned no matches.
- Final `pkgdown::build_site()`: passed after the parrot example and
  meta-analysis `meta_V()` reservation edits; rendered `articles/location-scale.html`,
  `articles/meta-analysis.html`, `ROADMAP.html`, and `news/index.html`.
- Final `pkgdown::check_pkgdown()`: passed with "No problems found."
- Final targeted `rg` scan confirmed rendered evidence for `beak_length`,
  `beta_forest`, `meta_V()`, proportional sampling variance, `phi_pi`, and the
  `0.1.2` NEWS heading.

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
  grammar; `meta_V()` is recorded as planned design space only.
- Noether: the symbolic interpretation agrees with the public `sigma` scale and
  explicitly converts variance claims through `sigma^2`; the parrot block now
  defines each parameter before interpretation.
- Darwin: the prose now separates predictability, thermal reaction norms, and
  among-population variation as distinct biological questions, with parrot
  beak length, forest habitat, body mass, aggressiveness, and life-history pace
  used as named examples rather than placeholders alone.
- Pat: the tutorial now has a single place to compare `sigma ~ temperature`,
  `(0 + temperature | population)`, and `sd(population) ~ habitat`, plus a
  nearby example of how to define every symbol in biological language.
- Grace: pkgdown build/check and focused Gaussian tests passed; the targeted
  article-only render failure is explained as stale local installation state.
- Rose: NEWS now uses a `0.1.2 (development version)` heading so post-0.1.1
  changes are not recorded under the released `0.1.1` heading, and the
  meta-analysis future API note is queued without changing release scope.

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
reserved slope-specific boundary. It also did not rewrite the meta-analysis
article; the Global Change Biology paper and the distributional-regression
meta-analysis manuscript should anchor a later separate meta-analysis polish
slice. The reserved `meta_V()` umbrella also remains future work: no parser,
likelihood, tests, or deprecation route were added. Slice 91 should stay
separate and focus on the structured-dependence reader route.

## Next Actions

1. Open and merge the Slice 90 PR after GitHub Actions pass.
2. Start Slice 91 on a new branch from `main`, focused on
   `vignettes/phylogenetic-spatial.Rmd`.
3. Use Slice 92 as the Phase 6e gate before any `0.1.2` release preparation.
