# After Task: Slice 159 Confidence-Band Examples

## Goal

Make the Slice 158 confidence-band path clearer to readers by showing both a
real fixed-effect 95% Wald band and an explicit unavailable interval status.
Keep the roadmap page useful as a live plan for the stabilization bridge back
to Phase 17 after Slice 202.

## Implemented

The Reference examples for `predict_parameters()` and
`plot_parameter_surface()` now request `conf.int = TRUE`, so the examples use
the interval-aware table contract directly.

The model-workflow article now prints the interval provenance for an explicit
`mu`/`sigma` grid:

```text
conf.status = "wald"
interval_source = "wald"
conf.level = 0.95
```

It then contrasts that with a direct `sd(site)` prediction table where an
interval request returns:

```text
conf.status = "wald_unavailable"
interval_source = "not_available"
```

The roadmap now includes a 30-slice stabilization map from Slice 159 through
Slice 188, plus the remaining Slice 189 and Slice 190-202 bridge text before
returning to Phase 17. It also records a Phase 16 skew-family planning note:
fixed-effect univariate `skew_normal()` first, `skew_t()` later, `nu` for
asymmetry, `tau` for skew-t tail thickness, shape random effects later, and
residual `sigma ~ ...` kept separate from `sd(group) ~ ...`.

## Mathematical Contract

No likelihood changed. The interval contract remains the Slice 158 Wald
fixed-effect interval for supplied `newdata` rows:

```text
eta_hat_i = X_i beta_hat
se_eta_i = sqrt(X_i V_beta X_i')
eta_low_i = eta_hat_i - z_(1 - alpha/2) se_eta_i
eta_high_i = eta_hat_i + z_(1 - alpha/2) se_eta_i
```

Rows without a validated Wald basis keep their point estimates and report an
explicit unavailable status. The plot helper consumes interval columns; it does
not estimate uncertainty.

## Files Changed

- `R/predict-parameters.R`
- `R/plot-parameter-surface.R`
- `man/predict_parameters.Rd`
- `man/plot_parameter_surface.Rd`
- `vignettes/model-workflow.Rmd`
- `docs/design/39-visualization-grammar.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-159-confidence-band-examples.md`

## Checks Run

- `air format R/predict-parameters.R R/plot-parameter-surface.R vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md ROADMAP.md`: passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "predict-parameters|plot-parameter-surface", reporter = "summary")'`: passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`: passed.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed after the final roadmap wording fix.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `git diff --check`: passed.
- Stale interval wording scan returned no matches outside historical dev-log files:
  `rg -n "ribbons remain planned|add interval ribbons later|point-estimate surfaces|does not draw intervals|leaves confidence intervals" README.md NEWS.md ROADMAP.md docs/design vignettes R man pkgdown-site --glob '!pkgdown-site/search.json' --glob '!docs/dev-log/**'`.
- Stale skew-family status scan returned no matches:
  `rg -n "skew_normal\\(\\).*implemented|skew_t\\(\\).*implemented|family = skew_normal\\(\\).*Implemented|family = skew_t\\(\\).*Implemented|skew-normal.*available|skew-t.*available" README.md NEWS.md ROADMAP.md docs/design vignettes R man pkgdown-site --glob '!pkgdown-site/search.json' --glob '!docs/dev-log/**'`.

## Tests Of The Tests

The focused test suite is the same behavioral gate as Slice 158 and confirms
that supported fixed-effect prediction rows receive intervals while unavailable
rows remain interval-free in plots. This slice did not add new behavior tests
because it changed examples and roadmap text rather than interval code.

The model-workflow render is the main test of the new examples: it executes the
new `unique(... conf.status ...)` chunks for both the Wald-supported
`mu`/`sigma` surface and the unavailable direct `sd(site)` surface.

## Consistency Audit

Source and rendered docs now agree that confidence bands are available only
when the prediction table contains finite supported interval columns. The
roadmap no longer hides the bridge to simulation in one paragraph; it gives the
next 30 slices as a table and still states that Phase 18 comprehensive
simulation waits until after the resumed Phase 17 closure gate.

The Phase 16 note is deliberately written as planning. It does not say
`skew_normal()` or `skew_t()` is implemented.

## What Did Not Go Smoothly

The first skew-family roadmap wording said "implemented density", which could
sound like skew-normal was already implemented. Rose caught this through the
stale-status scan; the roadmap now says "chosen density".

## Team Learning

Ada kept the branch stacked on the green confidence-band implementation. Pat
made the examples inspectable before plotting. Fisher kept fixed-effect Wald
bands separate from variance-component and shape uncertainty. Grace required
the rendered-site check because the roadmap is user-visible. Rose turned a
minor wording hazard into a stale-status scan rule. Jason's landscape pass
confirmed that skew-normal and skew-t parameterization choices must be explicit
rather than copied wholesale from another package. Gauss flagged the skew-t
zero-start derivative trap from `RTMBdist` as a future numerical guard.

## Known Limitations

This slice does not add profile-likelihood or bootstrap intervals to prediction
tables. It does not add intervals for direct random-effect SD surfaces,
conditional random-effect modes, derived variance ratios, q4 derived
correlations, covariance products, marginal means, contrasts, or slopes.

The skew-family note is only a roadmap update. The first implementation still
needs density equations, family registry changes, simulation recovery tests,
comparator checks, malformed-input tests, documentation, and provenance review
if any code is ported.

## Next Actions

1. Continue Slice 160 with discrete-x interval bars or their boundary tests.
2. Use Slices 161-163 to finish `newdata_required`, `conf.level`, and
   confidence-band documentation gates.
3. Keep the Phase 16 skew-family plan fixed-effect first until simulations show
   that shape random effects are identifiable.
