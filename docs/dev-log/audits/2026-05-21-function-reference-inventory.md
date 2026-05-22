# Function and Reference Inventory Audit

## Scope

This is the first exported-function and reference-page inventory after the fast
CI slice. It checks the public surface from `NAMESPACE`, `_pkgdown.yml`,
`man/`, and focused test names. It is an audit ledger, not a full reference
rewrite.

## Inventory Summary

- Exported user-facing names in `NAMESPACE`: 32.
- Registered `drmTMB` S3 methods in `NAMESPACE`: 26.
- Reference topics in `man/`: 40, including grouped S3 topics.
- Every exported name is present in the pkgdown reference index either as a
  direct topic or inside a grouped topic.

## Function Groups

| Group | Public surface | Reference status | Test signal | Audit verdict |
| --- | --- | --- | --- | --- |
| Core fitting | `drmTMB()`, `drm_control()` | Present under "Model fitting and post-fit tools" | Broad family, optimizer, control, and check tests | Keep; reference page is long and should be reviewed for reader order later. |
| Formula construction | `drm_formula()`, `bf()` | Present under "Model specification" | Formula grammar and many model-fit tests | Keep; make sure formula docs keep planned syntax visually separate from fitted syntax. |
| Families | `beta()`, `beta_binomial()`, `cumulative_logit()`, `student()`, `lognormal()`, `nbinom2()`, `truncated_nbinom2()`, `biv_gaussian()` | Present under "Model specification" | Family-specific likelihood and interval tests | Keep; family pages need a later stale-claim pass against the implementation map. |
| Meta-analysis helpers | `meta_V()`, `meta_known_V()`, `meta_vcov_bivariate()` | Present under "Model specification" | `test-meta-known-v.R`, `test-meta-vcov.R`, Phase 18 meta-V tests | Keep; audit should watch the word "stacked" here because it is a storage convention, not the user-facing centre of the package. |
| Structured markers | `animal()`, `phylo()`, `spatial()`, `relmat()`, `corpair()` | Present under "Structured-effect markers" | Structured Gaussian, q2/q4, profile-target, and diagnostic tests | Keep; pages must continue to distinguish fitted q1/q2/q4 slices from planned neighbours. |
| Deprecated marker | `gr()` | Present under "Deprecated marker internals" | Direct deprecation-warning test and formula-grammar boundary coverage | Keep out of the main reader path; direct calls warn and new known-relatedness formulas should use `relmat()`. |
| Diagnostics and intervals | `check_drm()`, `confint.drmTMB()`, `profile_targets()` | Present under "Model fitting and post-fit tools" | `test-check-drm.R`, `test-profile-targets.R`, `test-summary.R` | High priority; this surface just changed and needs rendered reference review after pkgdown build. |
| Extractors | `fixef()`, `ranef()`, `rho12()`, plus S3 `fitted()`, `predict()`, `residuals()`, `sigma()`, `simulate()`, `summary()`, `weights()`, `vcov()`, `logLik()`, `nobs()`, `df.residual()`, `deviance()` | Present directly or through grouped topics | Extractor, prediction, summary, bivariate, and structured tests | Keep; grouped S3 pages need a later consistency pass for interval/status vocabulary. |
| Prediction tables | `prediction_grid()`, `predict_parameters()`, `marginal_parameters()` | Present under "Model fitting and post-fit tools" | `test-prediction-grid.R`, `test-predict-parameters.R`, `test-marginal-parameters.R` | Keep; current audit fixed wording so modelled SD surfaces are not called direct targets. |
| Correlation tables | `corpairs()` | Present under "Model fitting and post-fit tools" | `test-corpairs.R`, structured correlation tests | Keep; bootstrap remains unsupported here and should stay explicit. |
| Plot helpers | `plot_parameter_surface()`, `plot_corpairs()` | Present under "Visualization" | `test-plot-parameter-surface.R`, `test-plot-corpairs.R` | High priority for rendered figure audit; source tests check mechanics, not visual quality. |

## Immediate Findings

1. Reference navigation is complete for exported names. No exported function was
   missing from `_pkgdown.yml`.
2. The first stale figure wording was found during inventory: `sd(site) ~ x`
   prediction surfaces were described as "direct random-effect SD surfaces".
   That conflicts with the new interval contract because direct SD targets now
   receive Wald intervals through `confint()`, while fitted `sd(group)` surfaces
   on a grid remain modelled/derived surfaces with unavailable Wald bands. The
   wording was changed to "modelled random-effect SD surfaces".
3. `gr()` remains exported for compatibility but is now explicitly deprecated
   and demoted in pkgdown. New user-facing examples should use `relmat()`,
   `animal()`, `phylo()`, or `spatial()`.
4. The generated `pkgdown-site` can be stale after source edits. Before any
   deploy, rebuild the site and re-run a rendered-page stale-wording scan.
5. The `corpairs()` and `predict_parameters()` reference pages were correct but
   thin on fast reader paths. The refreshed prose now tells users when to use
   `rho12()` versus `corpairs()`, when to use `marginal_parameters()` rather
   than row-level predictions, and why profile intervals should be filtered
   before running on large models.
6. The `prediction_grid()` and `marginal_parameters()` examples used tiny
   degenerate toy fits. The refreshed examples now use the same stable
   location-scale fixture, show finite Wald rows through `predict_parameters()`,
   and show empirical-grid averaging through `marginal_parameters()`.
7. The grouped model-fit extractor page omitted the documented `logLik()`
   method from the topic aliases and usage. The refreshed page now documents
   `logLik()`, `nobs()`, `df.residual()`, `deviance()`, `AIC()`, and `BIC()` as
   one likelihood-comparison path.
8. The next adjacent S3 pass found public reference topics without examples:
   `drmTMB`, `fitted.drmTMB`, `fixef`, `ranef`, `rho12`, and
   `weights.drmTMB`. The roxygen sources now give each of those pages a small
   runnable example. `gr()` remains example-free by design because it is a
   deprecated compatibility marker, and `drmTMB-package` remains a package
   overview topic rather than a function page.
9. The `vcov.drmTMB` S3 method was registered but did not appear in a public
   Rd topic. It now shares the grouped model-fit extractor page with
   `logLik()`, `nobs()`, `df.residual()`, `deviance()`, `AIC()`, and `BIC()`.
10. The two watchlist status-tile figures in the figure gallery were heavier
    than they needed to be. The refreshed `emmeans` and correlation-boundary
    chunks use lighter status-matrix displays, and the correlation matrix now
    marks ordinary, phylogenetic, spatial, animal, and `relmat()` q4 or
    regression extensions as partly fitted rather than leaving animal and
    `relmat()` behind stale planned-only colouring.

## Rendered Reference Follow-Up

2026-05-21 CI reference pass:

- Checked the high-risk generated reference pages for `confint()`, `summary()`,
  `profile_targets()`, `corpairs()`, `predict_parameters()`, and the plot
  helpers.
- Rebuilt the local reference pages with `pkgdown::build_reference()` before
  judging the HTML. The stale local `confint()` page had still said bootstrap
  intervals were not implemented; the rebuilt page now shows
  `method = c("wald", "profile", "bootstrap")`, `profile_precision =
  c("default", "fast")`, and bootstrap arguments.
- Updated `confint()` examples to show `confint(fit)`,
  `confint(fit, parm = "variance_components")`, a fast targeted profile, and a
  commented direct-target bootstrap call.
- Updated the `summary()` profile example to use `profile_precision = "fast"`.
- Ran the new examples on the toy model. Default Wald, the variance-component
  shortcut, fast profile for `sigma`, and the summary fast-profile example all
  completed.
- Source-only `gllvmTMB` comparison: local `confint.gllvmTMB_multi()` is a
  fixed-effect Wald helper, while `simulate.gllvmTMB_multi()` documents
  unconditional redraws as the parametric-bootstrap path. The usable lesson for
  `drmTMB` is to keep fast direct intervals first in the docs and present
  bootstrap as a targeted refit tool, not as the default answer for every row.

2026-05-21 plot-helper reference pass:

- Inspected `plot_parameter_surface-1.png` and `plot_corpairs-1.png` after
  rebuilding reference pages.
- Replaced the `plot_parameter_surface()` example's fragile tiny model fit with
  a controlled compatible prediction table, because the old rendered `sigma`
  panel used an absurd scale and looked like a broken plot.
- Reworked the `plot_corpairs()` example from a sparse faceted two-row display
  into a compact four-row table with short labels and visible profile intervals.
- Recorded rendered-image evidence in
  `docs/dev-log/figure-audits/2026-05-21-reference-plot-helpers/figure-audit.md`.

## Reference Example Status Table

This table records the compact example audit after the 2026-05-22 adjacent S3
pass. "Runnable" means the Rd topic contains an `\examples{}` block after
roxygen regeneration. "Overview" and "deprecated" are explicit reasons for no
example.

| Topic | Public surface | Example status |
| --- | --- | --- |
| `drmTMB-package` | Package overview | Overview page; no runnable example expected. |
| `drmTMB` | Main model-fitting function | Runnable Gaussian location-scale example. |
| `drm_control` | Optimizer and storage control | Runnable example. |
| `drm_formula` / `bf` | Formula constructors | Runnable syntax examples. |
| `meta_V` / `meta_known_V` | Known sampling covariance marker | Runnable syntax examples. |
| `meta_vcov_bivariate` | Bivariate known covariance helper | Runnable example. |
| `beta`, `beta_binomial`, `cumulative_logit`, `student`, `lognormal`, `nbinom2`, `truncated_nbinom2`, `biv_gaussian` | Family constructors | Runnable constructor examples. |
| `animal`, `phylo`, `spatial`, `relmat`, `corpair` | Structured-effect markers | Runnable syntax examples. |
| `random_effect_scale_formulas` | `sd*()` formula syntax topic | Runnable syntax examples. |
| `gr` | Deprecated marker placeholder | Deprecated compatibility topic; no example expected. |
| `check_drm` | Fit diagnostics | Runnable example. |
| `confint.drmTMB` | Wald, profile, and bootstrap intervals | Runnable fast-Wald and fast-profile examples; bootstrap shown as commented long-run route. |
| `profile_targets` | Interval target inventory | Runnable example, including `ready_only = TRUE`. |
| `corpairs` | Correlation-pair table | Runnable bivariate example. |
| `fitted.drmTMB` | Fitted response summaries | Runnable example. |
| `fixef` | Fixed-effect coefficients | Runnable example. |
| `ranef` | Conditional random-effect estimates | Runnable random-intercept example. |
| `rho12` | Residual bivariate correlation | Runnable bivariate example. |
| `weights.drmTMB` | Likelihood weights | Runnable weighted-fit example. |
| `predict.drmTMB`, `predict_parameters`, `prediction_grid`, `marginal_parameters` | Prediction helpers | Runnable examples. |
| `residuals.drmTMB`, `sigma.drmTMB`, `simulate.drmTMB`, `summary.drmTMB` | Post-fit extractors and summaries | Runnable examples. |
| `model-fit-extractors` | `logLik()`, `nobs()`, `df.residual()`, `deviance()`, `AIC()`, `BIC()`, `vcov()` | Runnable likelihood-comparison and covariance example. |
| `plot_parameter_surface`, `plot_corpairs` | Optional plot helpers | Runnable table-driven plotting examples with rendered PNG evidence. |

The repeatable local command for this table is:

```sh
Rscript tools/reference-audit.R
```

## Next Function Audit Actions

1. Rebuild and inspect the changed adjacent S3 reference pages:
   `drmTMB()`, `fitted()`, `fixef()`, `ranef()`, `rho12()`, `weights()`, and
   grouped `vcov()`.
2. Keep `gr()` deprecated and out of the main reader path; revisit removal only
   with a separate compatibility decision before release.
3. Continue the stale-claim pass through family, meta-helper, structured-marker,
   and formula-construction pages against the implementation map.
4. Keep rendered visual checks active for `model-workflow`, `model-map`,
   `implementation-map`, `simulation-plot-grammar`, and
   `phylogenetic-spatial`.
