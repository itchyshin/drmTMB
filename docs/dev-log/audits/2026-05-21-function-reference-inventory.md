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

## Next Function Audit Actions

1. Continue rendered reference inspection with `prediction_grid()`,
   `marginal_parameters()`, and grouped model-fit extractor prose and examples.
2. Check every exported reference page for one runnable minimal example, or an
   explicit reason no example is appropriate.
3. Keep `gr()` deprecated and out of the main reader path; revisit removal only
   with a separate compatibility decision before release.
4. Add a compact example-status table for all exported topics.
