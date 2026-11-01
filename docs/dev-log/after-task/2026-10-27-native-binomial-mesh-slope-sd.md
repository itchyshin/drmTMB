# After Task: Native Binomial mesh slope SD regression

## 1. Goal

Add one native Binomial logit route for a fixed-kappa mesh spatial slope whose SD depends on site-level predictors, and align its implementation, outputs, evidence, and user documentation.

## 2. Implemented

The model now fits `spatial(0 + x | site, mesh = mesh)` with `sd(site, level = "spatial", coef = "x") ~ z`. Its linear predictor contribution is `x_i * exp(W_site alpha) * (A_st omega)_i`, where `omega` retains the supplied fixed-kappa mesh precision. The slope design is used in the TMB likelihood and marginal simulations. `ranef(fit, "spatial_mu")$projected` reports the projected coefficient field; simulation applies each observation's `x` when forming its contribution.

The candidate universe now contains a dedicated mesh-slope mechanism. Native Binomial rows remain required for review; Julia mesh rows are marked blocked at base plumbing. The three previous Binomial mesh-intercept evidence records now bind an immutable copy of their original test source, preserving those receipts after the test file grew.

### Mathematical Contract

| Symbol | Formula or implementation | DGP | Extractor/check | Truth |
| --- | --- | --- | --- | --- |
| `omega` | `omega ~ N(0, Q_mesh^-1)` | `backsolve(chol(Q), rnorm(n_vertex))` | Sparse mesh latent draw | Fixed-kappa GMRF field |
| `f` | `f = A_st omega` | `mesh$A_st %*% omega` | `ranef(..., "spatial_mu")$projected` | Projected coefficient field |
| `tau_site` | `log(tau_site) = alpha0 + alpha1 z_site` | `exp(alpha0 + alpha1 z_site)` | `predict(dpar = "sd_spatial(site)")` | `alpha1 = 0.55` |
| `eta_i` | `beta0 + beta_x x_i + x_i tau_site f_i` | Same term-by-term construction | Seeded marginal-draw oracle | `beta_x = 0.3` |

## 3a. Decisions and Rejected Alternatives

This slice admits one numeric slope-only mesh coefficient, with fixed mesh precision and a site-level log-SD regression. The fixed-kappa precision and projection retain their existing scale. The output keeps the projected coefficient field distinct from its observation-level contribution. Coverage calibration and Julia parity remain deferred. Intercept-plus-slope mesh blocks, multiple mesh coefficients, other endpoints, and other families were left outside this slice.

## 4. Files Touched

- `R/drmTMB.R`, `src/drmTMB.cpp`, `R/methods.R`
- `R/formula-markers.R`, `man/spatial.Rd`
- `tests/testthat/test-binomial-mesh-sd-regression.R`
- `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`, `vignettes/spatial-models.Rmd`, `vignettes/structural-dependence.Rmd`, `NEWS.md`
- `tools/general-sd-regression/universe.py`, `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/general-sd-regression/mechanism-templates.tsv`, `required-rows.tsv`, `required-universe.md`, `direct-sd-evidence.tsv`
- Evidence snapshots and test transcript under `docs/dev-log/general-sd-regression/evidence/`

## 5. Checks Run

- Test-first check: before implementation, the new test failed at the Binomial mesh intercept-only guard with the expected refusal.
- `OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression|mesh-contract", reporter = "summary")'`: passed. The Binomial mesh test file reported 32 expectations; the neighboring Gaussian mesh contract file reported 48. No warnings or skips.
- `python3 -m unittest discover -s tools/general-sd-regression/tests`: 36 tests passed in 34.662 seconds.
- `python3 tools/general-sd-regression/universe.py`: generated 19,342 required rows.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 19,342 candidates, 88 linked rows, 19,254 unlinked rows, and 108 evidence records.
- `OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::document()'`: completed; `man/spatial.Rd` and neighboring help files are up to date.
- Rendered `vignettes/formula-grammar.Rmd`, `vignettes/spatial-models.Rmd`, and `vignettes/structural-dependence.Rmd` to temporary HTML; all three completed with existing Pandoc MathJax deprecation warnings.
- The after-task validator passed its structure check. It warned that the broader acceptance ledger has 13 files but no runnable node or gate-check command, so that gate remains unknown.
- `OPENBLAS_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'`: no pkgdown problems. Existing Pandoc `--mathml` deprecation warnings appeared.
- No full package test, `R CMD check`, site build, live Julia bridge test, interval calibration, or coverage run was performed.

## 6. Tests of the Tests

The new recovery test failed before the admission change at the intended formula guard. The passing test checks convergence, recovery of the log-SD slope, site SD prediction against an independent model matrix, coefficient-field projection, the exact `x * SD * projected_field` marginal draw, binary simulation, and save/reload. Existing intercept-link tests and the Gaussian mesh contract ran in the same focused checks.

## 8. Consistency Audit

The documentation now distinguishes the Gaussian mesh intercept, the already tested Binomial mesh intercept links, and the new logit mesh slope. The formula guide, spatial article, structured-dependence article, public help, roadmap, NEWS, and limitations state that this slice has point-recovery evidence only. The README has no mesh capability table to update. The live denominator still marks unrelated provider, endpoint, and Julia combinations unresolved or blocked.

Status inventory search used: `rg -n "mesh.*slope|mesh slopes|mesh/SPDE.*planned|non-Gaussian.*mesh|precomputed mesh" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/spatial-models.Rmd vignettes/structural-dependence.Rmd R/formula-markers.R man/spatial.Rd`. Follow-up edits corrected the current-scope mesh statements; historical notes were retained as historical records.

The evidence reconciler first caught that earlier intercept receipts referenced the mutable test path. Their original test bytes were reconstructed from the unchanged prefix and matched the recorded SHA-256 `89a6e60181634680d800006472463d70f5c8ee9bf4af54d244eedd341e4a0b46`; immutable evidence now preserves that snapshot. The new test SHA-256 is `24d06297e39c8fd184448ed77200a0d27ce26a7ff36dbbe36699ec8009f4b84d`.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial mesh spatial slope SD' --limit 10` found no narrowly matching issue. Issue #59 tracks the broader Phase 18 simulation programme. It was left unchanged for this implementation slice.

## 9. What Did Not Go Smoothly

The first mesh-slope run exposed a matrix-shape error in the synthetic SD-target descriptor. The first inventory unit run also exposed two expected-count controls that needed to include the new probit and cloglog Julia rows. Both issues were corrected and the relevant checks passed. A shell wrapper used zsh's reserved `status` variable after the R tests had run; the saved test transcript was read directly and passed.

## 11. Team Learning

When adding tests to a file already named by evidence records, preserve the old source under an immutable evidence path before registering a new hash. For projected structured slopes, keep the coefficient field returned by `ranef()` distinct from the observation-level contribution used in simulation.

## 10. Known Residuals

This is native TMB point-recovery evidence for the Binomial logit mesh slope route only. No interval-coverage claim is made. Probit and cloglog mesh-slope recovery, Julia support/parity, additional mesh coefficients, additional structured providers, other distributional endpoints, and bivariate models remain open.

## 12. Cross-Product Coverage

This slice covers the native TMB Binomial logit location endpoint, one spatial mesh slope coefficient, a site-constant SD design, prediction, marginal simulation, and save/reload. It does NOT cover Julia mesh parity, probit or cloglog mesh-slope recovery, interval coverage, other structured providers, additional distributional endpoints, or bivariate models.

Next, continue the broader general SD goal from the refreshed family/provider inventory. Prioritize the next native Bernoulli structured-provider gap, then coordinate Julia mesh admission with the DRM.jl parity lane. Keep interval coverage deferred as previously directed.
