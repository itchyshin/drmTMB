# Reference-documentation batch ledger

## Scope and evidence base

This ledger makes the eight reference batches named in the reader-surface
programme independently traceable.  It records the 68 authoritative `man/*.Rd`
topics at the frozen audit revision `1a972b8e6e1c60cec85ca116c0f1463fc2bf4214`.
Each topic's generated route is `reference/<topic>.html`; the reference index is
`reference/index.html`.  The topics below were regenerated with
`devtools::document()`, parsed with `tools::checkRd()`, and rendered by the
recorded full-site build.  See `global-render-closeout.md` and
`reference-julia-boundary-closeout.md` for the original build evidence.

The route names below are source-topic routes, not assertions about a new public
export.  The 51-export count remains the package inventory; multiple methods and
internal helper topics can share a reference surface.

## Batch 1 — Package (1 topic)

| Topic | Generated route | Disposition |
| --- | --- | --- |
| `drmTMB-package` | `reference/drmTMB-package.html` | Audited; package status vocabulary is consistent with the release-scope manifest. |

## Batch 2 — Model specification (17 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `drm_formula`, `meta_V`, `mi`, `impute_model`, `meta_vcov_bivariate` | `reference/<topic>.html` | Audited; formula, known-covariance, and missing-predictor documentation retains its explicit boundaries. |
| `beta`, `zero_one_beta`, `beta_binomial`, `cumulative_logit`, `categorical`, `student` | `reference/<topic>.html` | Audited; family parameterisation and response restrictions render without a new capability claim. |
| `skew_normal`, `lognormal`, `tweedie`, `nbinom2`, `truncated_nbinom2`, `biv_gaussian` | `reference/<topic>.html` | Audited; family and bivariate syntax remains bounded by the manifest and ledger. |

## Batch 3 — Structured-effect markers (7 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `random_effect_scale_formulas`, `animal`, `phylo`, `phylo_interaction`, `spatial`, `relmat`, `corpair` | `reference/<topic>.html` | Audited; status-marked structured syntax, `rho12`, and narrow REML boundaries remain explicit. |

## Batch 4 — Deprecated markers (2 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `meta_known_V`, `gr` | `reference/<topic>.html` | Audited; both routes remain compatibility-only and are kept out of the main reader path. |

## Batch 5 — Model fitting and post-fit tools (29 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `drmTMB`, `drm_family_dpq`, `drm_quantile_residuals`, `drm_control`, `miss_control` | `reference/<topic>.html` | Audited; current fitting is native R/TMB and internal diagnostic helpers are not promoted as new exports. |
| `drm_phylo_penalty`, `drm_phylo_penalty_sweep`, `check_drm`, `is_converged`, `confint.drmTMB`, `profile_targets`, `profile.drmTMB` | `reference/<topic>.html` | Audited; diagnostics and interval routes preserve provenance and do not imply coverage. |
| `corpairs`, `fitted.drmTMB`, `fixef`, `imputed`, `model-fit-extractors`, `marginal_parameters`, `prediction_grid` | `reference/<topic>.html` | Audited; extractors and imputation help retain their documented return-shape and scope boundaries. |
| `predict_parameters`, `predict.drmTMB`, `ranef`, `residuals.drmTMB`, `rho12`, `sigma.drmTMB`, `simulate.drmTMB`, `structured_effects`, `summary.drmTMB`, `weights.drmTMB` | `reference/<topic>.html` | Audited; prediction, structured-effect, and residual-correlation wording remains consistent with the manifest. |

## Batch 6 — Distributional outputs and adequacy (5 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `fitted_distribution`, `exceedance`, `centile_chart`, `worm_plot`, `qq_plot` | `reference/<topic>.html` | Audited; diagnostic and distributional output routes do not imply inferential certification. |

## Batch 7 — Future Julia support (4 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `confint.drmTMB_julia`, `predict.drmTMB_julia`, `summary.drmTMB_julia`, `rho_latent` | `reference/<topic>.html` | Repaired and audited; retained only for compatibility inspection, not current fitting, inference, REML, or cross-family support. |

## Batch 8 — Visualization (3 topics)

| Topics | Generated routes | Disposition |
| --- | --- | --- |
| `plot.profile.drmTMB`, `plot_corpairs`, `plot_parameter_surface` | `reference/<topic>.html` | Audited; plotted intervals require stated provenance and never imply coverage by themselves. |

## Totals and final-check contract

The batch counts are `1 + 17 + 7 + 2 + 29 + 5 + 4 + 3 = 68` topics.  Final
closeout reruns `tools::checkRd()` over exactly these 68 files, builds the full
site, checks pkgdown, and inventories the rendered reference/index routes.  This
ledger does NOT add an export, change generated help, certify an interval, or
alter the package's capability ledger.
