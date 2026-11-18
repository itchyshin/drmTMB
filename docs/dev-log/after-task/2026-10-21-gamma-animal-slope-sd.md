# After Task: Gamma Animal Slope SD Regression

## 1. Goal

Add and document one narrow native Gamma route for a predictor-dependent SD on a single animal-model slope coefficient.

## 2. Implemented

Native complete-data Gamma models now accept one slope-only animal coefficient with a group-level SD predictor and fixed `sigma`. The route rejects covariance labels, within-animal variation in the SD predictor, and animal blocks with multiple coefficients. Existing Gamma animal intercept and relatedness-matrix routes remain separate.

## 3a. Decisions and Rejected Alternatives

We reused the existing structured animal scale path instead of adding a new likelihood or changing kernel scaling. The route is limited to one slope-only coefficient; a broader animal intercept-plus-slope block remains unsupported.

### Mathematical Contract

For group (i), the animal slope has τ_i = exp(α_0 + α_1 z_i), and the slope vector has covariance D A D under the existing animal-kernel scaling. For observation (j) in group (i), log(μ_ij) = β_0 + β_1 x_ij + b_i x_ij. The Gamma response uses shape 1/σ² and scale μ_ijσ². Here `x` varies within group and `z` is constant within group. This is a q1 slope-only point-recovery route, not a general animal block.

| Mathematical object | Formula or R syntax | Implementation check |
| --- | --- | --- |
| Group SD | `log(tau_i) = alpha0 + alpha1 * z_i` | The fit recovers the seeded SD trend and predicts SDs keyed by animal label. |
| Slope covariance | `b ~ Normal(0, D A D)` | Existing structured animal scale machinery is reused without changing kernel normalization. |
| Linear predictor | `log(mu_ij) = beta0 + beta1*x_ij + b_i*x_ij` | The test fixture simulates the same animal slope and Gamma response. |
| Supported term | `animal(0 + x | id, pedigree = pedigree)` with `sd(id, level = "animal") ~ z` | One coefficient only; `sigma ~ 1`, complete response data. |

## 4. Files Touched

The implementation is in `R/drmTMB.R`; behavioral coverage is in `tests/testthat/test-gamma-animal-slope-sd-regression.R`. User-facing formula help and the predictor-dependent SD guide were updated, along with `NEWS.md`, formula grammar, the random-effect scale design, the structural-slope map, known limitations, the internal roadmap, and the general-SD inventory and native adapter map. `man/random_effect_scale_formulas.Rd` was regenerated. The local programme checkpoint and `docs/dev-log/check-log.md` record this slice.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-animal-slope-sd-regression|gamma-animal-pedigree-sd-regression", reporter = "summary")'` passed: 14 assertions in the existing animal-intercept test and 10 in the slope-only test. The Julia bridge reported zero live tests.
- `Rscript -e 'devtools::document()'` passed and regenerated `man/random_effect_scale_formulas.Rd`.
- `Rscript -e 'pkgdown::check_pkgdown()'` passed with no problems; Pandoc emitted existing MathML deprecation warnings.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_dir = "/private/tmp/general-sd-regression-render", quiet = TRUE)'` completed. It loaded this worktree explicitly.
- The first vignette render loaded an older installed checkout and failed on an unrelated Bernoulli phylogenetic formula. Loading this worktree before rendering resolved that environment mismatch.
- No Julia engine test or interval-coverage campaign was run.
- A test-only follow-up added finite conditional-simulation and save/reload checks for the SD coefficients and group-level predictions. `Rscript -e 'devtools::test(filter = "gamma-animal-slope-sd-regression")'` passed all 15 expectations in 10.1 seconds.

## 6. Tests of the Tests

The new test first failed at the family-specific intercept-only validator, confirming that it exercised the missing admission. It now checks seeded recovery with a tolerance of 0.25, name-keyed predictions, constant-SD likelihood equivalence, rejection of within-animal SD predictors, rejection of an intercept-plus-slope animal block, finite conditional simulations, and preservation of SD coefficients and predictions after saving and reloading. The DGP uses `t(chol(A))` to generate the stated `D A D` covariance. The existing Gamma animal-intercept test passed in the original paired run.

## 7a. Issue Ledger

Searched open issues for `"random-effect SD" OR "random slope SD" OR "scale regression"`. The returned issues did not track this specific Gamma animal slope-only slice, so no issue was created, changed, or closed.

## 8. Consistency Audit

The equation, fixture, implementation boundary, formula reference, NEWS, limitation note, inventory, and adapter map agree on one complete-data q1 animal slope-only coefficient with fixed `sigma`. The structural-slope map had called all coefficient-specific SD formulas unavailable; it now names the Gamma and NB2 animal slope-only exceptions and retains the general limitation. The status inventory remains a denominator of required work, not a support claim. Exact support-wording scan used:

```sh
rg -n "animal slope-only|Gamma.*animal" docs/dev-log/general-sd-regression/inventory.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md docs/dev-log/known-limitations.md docs/dev-log/internal-roadmap.md NEWS.md LOOP/lanes/general-sd-regression/checkpoint.md
rg -n "Native Gamma models support one animal|Gamma q1 animal slope-only" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The first scan found the expected Gamma scope entries. The second found no matching stale claim in the scanned status surfaces; formula grammar and internal roadmap already describe the route with its limits. No site navigation change was needed.

## 9. What Did Not Go Smoothly

The initial guide render used an older installed package and failed before reaching the Gamma example. The successful rerun explicitly loaded this worktree. No code change was needed for that environment issue.

## 11. Team Learning

When a guide calls `library(drmTMB)`, render it with the intended source tree loaded first. Otherwise an older installed package can create misleading failures unrelated to the edited guide. The structural-slope map also needs exact family-specific exceptions rather than a blanket statement about coefficient-specific SD targets.

## 10. Known Residuals

This evidence does not establish interval calibration, Julia parity, support for a multi-coefficient animal block, animal random intercept plus slope in this route, missing-response behavior, random `sigma`, or other Gamma structured providers. Predictor-dependent SD calibration remains deferred, and the overall general-SD goal is still open.

## 12. Cross-Product Coverage

Continue the required-family/effect inventory and native/Julia coordination in the active general-SD programme. Keep this row at point-recovery evidence until separately reviewed uncertainty work and Julia implementation are complete.

Native R/TMB point-recovery and output behavior are verified for this exact Gamma row. The Julia engine has not been exercised for this row, and no interval-calibration evidence is claimed. The overall cross-family, cross-effect, two-engine goal remains open.

This slice does NOT cover Julia fitting, interval calibration, other structured providers, missing responses, random `sigma`, or multi-coefficient animal blocks.
