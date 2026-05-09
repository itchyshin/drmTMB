# After Task: Curved-Effects User Tutorial

## Goal

Make the ordinary-R-formula support useful to applied readers by showing a
biological location-scale example with a curved temperature response,
habitat-temperature interaction, model output, and interpretation.

## Implemented

The `location-scale` article now includes a "Curved responses and interactions"
section. It teaches `habitat * temperature`, `I(temperature^2)`, and
`poly(temperature, 2)` from a user viewpoint:

- `I(temperature^2)` is shown in the worked model because the coefficient name
  and equation are easy to connect;
- `poly(temperature, 2)` is described as supported and potentially useful, but
  less transparent for raw coefficient interpretation;
- predictions are used as the main interpretation device for curved effects.

## Mathematical Contract

The symbolic model is:

```text
growth_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 temperature_i +
       beta_2 temperature_i^2 +
       beta_3 I(habitat_i = grassland) +
       beta_4 temperature_i I(habitat_i = grassland)
log(sigma_i) = gamma_0 + gamma_1 temperature_i^2
```

The matching R syntax is:

```r
drmTMB(
  drm_formula(
    growth ~ habitat * temperature + I(temperature^2),
    sigma ~ I(temperature^2)
  ),
  family = gaussian(),
  data = dat_curve
)
```

This is a linear predictor with transformed covariate columns. It is nonlinear
in temperature but linear in the coefficients, matching ordinary R formula
semantics.

## Files Changed

- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-curved-effects-user-tutorial.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  failed because `drmTMB` was not installed in the bare R session.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Curved responses|poly\\(temperature|temperature\\^2|habitat \\* temperature|fitted_residual_sd|third-order" vignettes/location-scale.Rmd pkgdown-site/articles/location-scale.html`:
  confirmed the source and generated page contain the new section and outputs.

## Tests Of The Tests

This was an executable-docs task rather than a package-code task. The vignette
chunk simulates data, fits the model, prints `summary(fit_curve)`, and prints a
prediction table. If the documented formula syntax, fitting route, summary
method, or prediction method breaks, the vignette and pkgdown build should
fail.

## Consistency Audit

The new section uses the same terms as the design documents: `mu` for location,
`sigma` for residual standard deviation, and fixed-effect formula
transformations as ordinary `model.matrix()` columns. It does not claim that
random-effect slope transformations or structured phylogenetic/spatial slopes
are implemented.

The generated pkgdown page was checked directly because the user-facing page is
the artifact readers will see.

## What Did Not Go Smoothly

The first direct vignette render failed because the package was not installed
in the local R session. Loading the package with `devtools::load_all()` before
rendering fixed the local check. The pkgdown build installs the package into a
temporary library and therefore checked the normal site path.

## Team Learning

Pat's user-test lesson is that examples need model output and a biological
interpretation, not just syntax. Darwin's lesson is that a quadratic
temperature response is an ecological question readers already recognize.
Rose's efficiency lesson is that doc-only tasks should first render the touched
vignette and generated site; full test suites are still valuable, but they are
not always the most efficient first check when no package code changed.

## Known Limitations

The example uses simulated data so it is fast and reproducible. It is a
teaching example, not evidence about a real ecological system. It also covers
fixed-effect transformations only; interaction random slopes should still be
handled cautiously until the random-effect grammar is documented and tested.

## Next Actions

Add the same user-first treatment to the bivariate coscale article: after
`rho12 ~ predictor`, show `summary()`, `rho12(fit)`, and a prediction table
that explains how an environmental gradient changes residual coupling between
two traits.
