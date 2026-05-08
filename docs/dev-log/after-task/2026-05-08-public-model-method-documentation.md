# After Task: Public Model-Method Documentation

## Goal

Document existing public model-output methods so users can find and understand
prediction, simulation, residual, scale, and summary behaviour from the
reference index.

## Implemented

- Added roxygen documentation for:
  - `predict.drmTMB()`;
  - `simulate.drmTMB()`;
  - `residuals.drmTMB()`;
  - `sigma.drmTMB()`;
  - `summary.drmTMB()`.
- Added those methods explicitly to the pkgdown model-fitting reference
  section.
- Regenerated Rd files:
  - `man/predict.drmTMB.Rd`;
  - `man/simulate.drmTMB.Rd`;
  - `man/residuals.drmTMB.Rd`;
  - `man/sigma.drmTMB.Rd`;
  - `man/summary.drmTMB.Rd`.

## Mathematical Contract

No likelihood or fitted-object behaviour changed.

The documentation records existing contracts:

```text
predict(fit, dpar = "sigma", type = "response") = exp(eta_sigma)
predict(fit, dpar = "rho12", type = "response") = tanh(eta_rho12)
```

For fitted rows, implemented conditional random-effect contributions are
included where they exist. For `newdata`, predictions are currently
fixed-effect, population-level predictions.

For meta-analytic Gaussian models with known sampling covariance,
`sigma(fit)` returns the modelled residual heterogeneity scale. The total
observation covariance used by simulation and Pearson residuals is:

```text
V_total = V_known + diag(sigma_i^2)
```

or the dense-matrix analogue when `V_known` is a full covariance matrix.

## Files Changed

- `R/methods.R`
- `_pkgdown.yml`
- `man/predict.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/summary.drmTMB.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::document()"`: completed successfully.
- `Rscript -e "devtools::test()"`: 572 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- Generated-site search found the five new reference-page headings and the
  `meta_known_V(V = V)` clarification on the rendered `sigma()` page.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- No unit tests were added because this task did not change model behaviour.
- R CMD check ran the new examples, so example code was tested through the
  package examples stage.
- pkgdown was rebuilt and searched directly, which checks that the new pages
  are visible in the generated reference site.

## Consistency Audit

- `NAMESPACE` already registered these S3 methods, and now the matching Rd
  topics exist.
- `_pkgdown.yml` now lists the methods explicitly rather than relying on
  broad `starts_with()` entries.
- No NEWS entry was added because this is documentation coverage for existing
  behaviour rather than a behaviour change.
- The `sigma()` docs now match the meta-analysis design: `sigma` is the
  residual heterogeneity scale, not a separate `tau` syntax.

## What Did Not Go Smoothly

- A documentation-review subagent could not be launched because the thread had
  reached its agent limit. The local audit therefore carried the review burden.
- `air` remains unavailable locally.

## Team Learning

- Method documentation should be treated as part of the definition of done for
  every exported or S3-registered user-facing method.
- Small reference examples are enough for Rd pages; richer biological examples
  should remain in tutorials where the scientific question can be explained.
- Prediction docs must always say whether random effects are included,
  especially once new-data workflows, phylogenetic terms, and random-effect
  scale models all exist.

## Known Limitations

- Conditional prediction for new group levels is not implemented.
- The method examples are synthetic and minimal.
- More applied examples for diagnostics and simulation should be added to
  tutorials when the next modelling slices land.

## Next Actions

- Consider a later tutorial pass showing `predict()`, `simulate()`,
  `residuals()`, and `check_drm()` together in one ecology/evolution workflow.
- Keep future method additions paired with roxygen documentation and pkgdown
  reference placement from the same commit.
