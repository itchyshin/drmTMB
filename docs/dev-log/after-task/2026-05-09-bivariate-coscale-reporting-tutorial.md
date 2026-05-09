# After Task: Bivariate Coscale Reporting Tutorial

## Goal

Improve the bivariate location-coscale article so applied users can see what to
report from a fitted `rho12 ~ predictor` model, not only how to fit it.

## Implemented

The `bivariate-coscale` article now includes:

- a fitted table with residual SDs for both responses, fitted `rho12`, and the
  implied residual covariance;
- a "What should I report?" section;
- a report table that includes `eta_rho12`, response-scale `rho12`,
  response-specific residual SDs, and residual covariance;
- a raw-versus-residual correlation comparison to prevent readers from
  interpreting `rho12` as the ordinary raw correlation between the responses;
- rounded table output for readability.

## Mathematical Contract

The fitted bivariate Gaussian residual covariance for observation `i` is:

```text
Omega_i[1, 1] = sigma1_i^2
Omega_i[2, 2] = sigma2_i^2
Omega_i[1, 2] = Omega_i[2, 1] = rho12_i * sigma1_i * sigma2_i
rho12_i = tanh(eta_rho12_i)
eta_rho12_i = X_rho12[i, ] beta_rho12
```

The reporting table now computes the off-diagonal element explicitly:

```r
residual_covariance = rho12 * sigma_activity * sigma_boldness
```

The tutorial also states that raw activity-boldness correlation and fitted
residual `rho12` are different estimands. Raw correlation mixes mean structure,
scale, and residual coupling. `rho12` is the residual correlation after the
`mu1`, `mu2`, `sigma1`, and `sigma2` formulae have been modelled.

## Files Changed

- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-bivariate-coscale-reporting-tutorial.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `rg -n "What should I report|raw_activity_boldness_correlation|mean_fitted_residual_rho12|residual_covariance|round\\(report_table|round\\(rho_table" vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html`:
  confirmed that the source and generated page contain the reporting section,
  residual covariance, raw-versus-residual comparison, and rounded outputs.

## Tests Of The Tests

This was an executable-docs task. The new article chunks call the user-facing
paths that matter for interpretation:

- `predict(fit_biv, dpar = "rho12", type = "link")`;
- `rho12(fit_biv, newdata = ...)`;
- `predict(fit_biv, dpar = "sigma1")`;
- `predict(fit_biv, dpar = "sigma2")`.

If these extractor paths break, the vignette and pkgdown build should fail.
The raw-versus-residual table also checks that the tutorial exposes the main
interpretation distinction users need.

## Consistency Audit

The new text keeps `rho12` restricted to residual response-response
correlation. It does not imply that group-level, phylogenetic, spatial, or
study-level correlations are currently fitted. Those remain future correlation
pair classes and should be reported by `corpairs()` only after their likelihood
paths exist.

The generated pkgdown page was scanned directly because it is the user-facing
artifact.

## What Did Not Go Smoothly

The first version printed full-precision numeric tables, which made the output
harder to read than necessary. A small readability pass changed those tables to
rounded output.

## Team Learning

Pat's user perspective again paid off: users need a table they can report, not
only a parameter definition. Darwin's perspective kept the example framed as a
biological question about changing activity-boldness coupling. Rose's audit
kept the article from blurring residual `rho12` with future group-level or
structured correlation pairs.

## Known Limitations

The article still uses simulated data. It does not provide confidence intervals
for fitted `rho12`, residual covariance, or predicted coscale contrasts.
Profile-likelihood or bootstrap uncertainty for these quantities remains a
future inference task.

## Next Actions

Add uncertainty guidance for tutorial outputs once profile-likelihood or
bootstrap intervals are implemented. Before then, the next user-facing
improvement should be clearer error recovery when a user tries bivariate random
effects that are still planned.
