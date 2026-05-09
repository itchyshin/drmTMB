# After Task: Correlation Pairs, Tutorial Style, Weights, and Large-Data Memory

## Goal

Export the first implemented correlation-pair extractor, improve the bivariate
coscale tutorial so equations and R output are paired, and record design
decisions for likelihood weights and large-data memory scaling.

## Implemented

- Added `corpairs()` for fitted correlations already present in a `drmTMB`
  object.
- Added tests for residual bivariate `rho12`, ordinary group-level `mu`
  random-effect correlations, and the no-correlation case.
- Added a `corpairs()` reference page and pkgdown navigation entry.
- Revised the bivariate coscale tutorial so it includes LaTeX equations,
  code-like implementation checks, real model output, `summary(fit)`,
  `rho12(fit)`, `corpairs(fit)`, and a response-scale interpretation table.
- Added `docs/design/21-tutorial-style.md` so future tutorials follow the same
  equation-syntax-output-interpretation pattern.
- Added `docs/design/22-likelihood-weights.md` to reserve `weights =` for
  ordinary likelihood row multipliers and keep it separate from
  `meta_known_V(V = V)`.
- Added `docs/design/23-large-data-memory.md` to separate sparse phylogenetic
  precision scaling from million-row R memory scaling.
- Updated `README.md`, `ROADMAP.md`, `NEWS.md`,
  `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/20-coscale-correlation-pairs.md`,
  `docs/dev-log/known-limitations.md`, and affected vignettes.

## Mathematical Contract

For the implemented fixed-effect bivariate Gaussian coscale model, tutorials
now present the reader-facing transform as:

```text
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
```

Implementation-facing docs still record the exact numerical guard:

```text
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

The guard keeps covariance matrices strictly positive definite near the
boundary. It is not a biological parameter and should not dominate tutorial
tables.

`corpairs(fit)` currently reports two fitted correlation classes:

```text
residual rho12 between response 1 and response 2
ordinary group-level mu random-effect correlations from fitted corpars$mu
```

It does not yet report bivariate group-level, phylogenetic, spatial,
study-level, or cross-parameter correlation pairs.

For future likelihood weights, the planned contract is:

```text
weights = row likelihood multipliers
meta_known_V(V = V) = known sampling covariance
sigma ~ x = modelled residual or heterogeneity scale
sd(group) ~ x = modelled group-level random-effect scale
```

For large phylogenetic datasets, the scaling contract is:

```text
sparse A-inverse/augmented precision solves the species covariance problem
memory-light R data handling solves the millions-of-rows problem
```

These are separate engineering problems.

## Files Changed

- `R/methods.R`
- `NAMESPACE`
- `man/corpairs.Rd`
- `tests/testthat/test-corpairs.R`
- `_pkgdown.yml`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/00-vision.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/07-collaboration-and-site.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/22-likelihood-weights.md`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/which-scale.Rmd`
- generated `pkgdown-site/` pages

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'corpairs|biv-gaussian|gaussian-random-intercepts')"`
- `Rscript -e "devtools::test()"`
- Direct renders for `vignettes/formula-grammar.Rmd`,
  `vignettes/bivariate-coscale.Rmd`, `vignettes/which-scale.Rmd`, and
  `vignettes/phylogenetic-spatial.Rmd`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `air format .`

Results:

- targeted tests: 299 passed, 0 failed;
- full `devtools::test()`: 1192 passed, 0 failed;
- touched vignettes rendered successfully;
- pkgdown checks found no problems;
- pkgdown site built successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .`: failed because `air` is not installed locally.

## Tests Of The Tests

The `corpairs()` tests check:

- predictor-dependent residual `rho12` against `rho12(fit)` and link-scale
  predictions;
- a labelled ordinary group-level `mu` random intercept-slope correlation,
  including parsed group, block, coefficient labels, response names, and class;
- the empty-table contract when a model has no fitted correlations.

Those tests cover both an observation-level residual correlation and an
ordinary random-effect correlation, which is the main naming distinction that
future correlation-pair work must preserve.

## Consistency Audit

Stale-wording scans checked for:

```sh
Fisher-z/atanh scale
flagship
selling point
O'Dea-style
biological data
Goodall
Russell
Confucius
weights
corpairs
meta_known_V(V = V)
rho12_i = tanh
0.99999999 * tanh
```

The current source no longer uses `flagship`, `selling point`, `O'Dea-style`,
or narrow "biological data" framing outside historical after-task notes.
Temporary app nicknames do not appear in current source. The `rho12` guard
appears in implementation-facing docs, tests, and reference pages; tutorials
use the simpler `tanh()` notation with an adjacent guard note.

## What Did Not Go Smoothly

The first pkgdown build failed before this audit because the bivariate coscale
article called `drmTMB()` without loading the package inside the vignette
rendering environment. The setup chunk now conditionally calls `library(drmTMB)`.

The `air` formatter remains unavailable. Formatting still relies on targeted
source review and `git diff --check`.

The weight discussion clarified that `weights = 1 / vi` must not be treated as
the default meta-analysis path. Known sampling variance belongs in
`meta_known_V(V = vi)`.

## Team Learning

- Ada should keep stable team names in reports and keep temporary app nicknames
  out of project documents.
- Pat and Darwin should continue pushing tutorials toward model output and
  interpretation, not syntax-only demonstrations.
- Rose should continue checking that exact implementation equations and
  teaching equations are both present but clearly labelled.
- Fisher should require comparator checks and simulation recovery before any
  new correlation-pair class is called implemented.
- Grace should treat large-data readiness as a benchmarked release criterion,
  not a claim inferred from small unit tests.
- Boole and Emmy should keep `weights =` as top-level model-fitting syntax, not
  formula syntax.

## Known Limitations

- `corpairs()` does not fit or infer new correlation classes.
- Bivariate group-level, phylogenetic, spatial, study-level, and
  cross-parameter correlation pairs remain planned.
- `weights =` is not implemented.
- Memory-light fitting controls, sparse fixed-effect matrices, and
  sufficient-statistic aggregation are not implemented.
- Large phylogenetic models with millions of rows need a dedicated benchmark
  before `drmTMB` claims production-scale readiness.

## Next Actions

1. Add a small `weights =` implementation for fixed-effect Gaussian models,
   with tests proving that constant weights scale the objective correctly.
2. Add `drm_control(keep_data = FALSE, keep_model_frame = FALSE)` as the first
   memory-light fitting control.
3. Add a non-CRAN large phylogenetic benchmark script for 100k, 500k, 1M, and
   5M rows.
4. Continue tutorial-quality upgrades, starting with the Gaussian
   location-scale and meta-analysis pages.
