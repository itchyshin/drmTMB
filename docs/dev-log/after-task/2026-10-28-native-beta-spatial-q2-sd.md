# After task: Beta coordinate-spatial intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent coordinate-spatial intercept and numeric-slope fields in a native Beta model.

## 2. Implemented

The Beta builder now recognizes sd_spatial targets, extracts a coordinate-spatial term and admits the missing base route with one unlabelled intercept plus numeric slope. Provider selection and collision rules include spatial, while sigma remains fixed-effect-only. The new route requires complete responses and predictors, including when no SD formula is supplied. The coefficient-specific data map uses the existing native loading and extraction; no C++ source or compiled artifact changed.

Independent fields satisfy u_k ~ N(0,K), b_k=D_k u_k and Cov(b_k)=D_k K D_k, with D_k=diag(exp(W_k alpha_k)). The predictor is X beta+b_0+x*b_1. Beta mean is eps+(1-2*eps)*plogis(eta), eps=1e-12, and precision phi=sigma^-2. The example pairs spatial(1+x|id,coords=coords) with two selected sd(id,level="spatial",coef=...) formulas.

## 3a. Decisions and Rejected Alternatives

The independent coordinate kernel is exp(-distance/range)+1e-6 I, with range fixed to median strictly positive unordered pairwise Euclidean distance. It is not normalized; marginal field SD is the fitted multiplier times sqrt(K[g,g]). The ordinary fixture has diagonal 1.000001 and does not invoke extra fallback jitter.

Seed 2026102803, 64 sites on an 8 by 8 grid with 20 observations per site, SD-slope error tolerance .4 and absolute likelihood/eta/reorder/constant-base tolerance 1e-4 were recorded before fitting. Assumptions without asking: reuse these one-seed point-fit tolerances from preceding slices. No seed, fixture or tolerance changed after results. Incidental q1 admission was rejected: intercept-only, slope-only, labels, multiple slopes, meshes and extra random layers remain outside this new route.

## 4. Files Touched

Scoped implementation is in R/drmTMB.R. New files are tests/testthat/test-beta-spatial-q2-sd-regression.R, inst/examples/beta-spatial-q2-sd.R, this report, its check-log.d fragment and native-beta-spatial-q2-sd-20261028 evidence directory. No existing test was edited. Foreign dirty changes were preserved.

## 5. Checks Run

The initial red test produced two expected unsupported sd_spatial errors in 7.163 seconds. The first post-change run passed 41 checks but had one error in 39.563 seconds: a new collision test supplied a matrix expression where the parser requires a named symbol. The test was corrected without changing the model. The final nine-file Beta regression passed 446 checks with zero failures, errors, warnings or skips in 276.163 seconds, below the 300-second deadline. The wrapper completed in 280.943 seconds. The new spatial file contributed 48 checks.

The standalone example converged in 9.272 seconds, estimating SD slopes 0.6594423 and -0.4907829 against truths 0.5 and -0.5. These are one-seed point checks, not general recovery or calibrated uncertainty evidence. No full package check, pkgdown build, calibration or live Julia process ran.

## 6. Tests of the Tests

The DGP calculates distances, fixed range and jittered covariance independently of package precision helpers. Its inverse is compared with assembled precision. A dense Beta joint density, analytic score/Hessian, two latent-mode starts, finite differences and absolute Laplace correction provide the numerical oracle. Coordinate row order and factor order differ; reversed coordinate and SD-formula order must preserve the fitted model. Constant SD formulas match the base route.

Raw latent fields, separately scaled effects, named site SDs, parameter tables, selected-optimum fitted means, save/reload and seeded conditional simulation are checked. Failure cases include a missing coefficient-specific SD formula, q1, slope-only/multiple-slope forms, labels, meshes, additional providers/random layers, sigma spatial and missing responses. Coordinates cover observed sites only; no unused-site prediction is claimed. Fresh marginal draws of both fields remain refused.

## 7a. Issue Ledger

One exact native Beta mu spatial_coordinate_slope coordinates candidate is saved in candidate-rows.tsv; mesh_precision is excluded. No shared evidence ledger was promoted, no issue was opened or closed and no external comment was posted. The bounded issue search is retained separately; public status integration remains with the documentation lane. The full SD programme stays open.

## 8. Consistency Audit

Parent and independent read-only reviewer found no P0/P1 issue in the bounded patch and mathematical contract. The Gamma admission arm is unchanged. Existing Beta animal, tree and related-matrix behavior remains under neighboring tests. The exact Julia Beta spatial-slope route still refuses before setup; static inspection is not live parity evidence.

The scan rg -n 'Beta.*spatial|beta.*spatial' covered README.md, docs/dev-log/internal-roadmap.md, NEWS.md, docs/dev-log/known-limitations.md, docs/design/01-formula-grammar.md and vignettes/formula-grammar.Rmd. Broad public status maps remain owned by the documentation lane. Syntax and likelihood parameterization are unchanged; the runnable example and report document this candidate. No roxygen regeneration is needed for internal-only builder changes.

Memory receipt: routed project manifest, on-disk graph and prior Gamma/Beta receipts supplied context; independent kernel and provider-target lessons shaped this slice. Golden Set: not run; independent numerical and neighboring tests provide current evidence. No expensive sister-repository discovery was repeated.

## 9. What Did Not Go Smoothly

Preflight and lease checks took minutes. The first post-change run exposed a formula-parser error in the new collision test. It was repaired by binding the matrix outside the formula, preserving the intended provider-collision test. All attempts remain visible. No scientific acceptance rule changed.

## 10. Known Residuals

General bias, interval behavior, coverage, estimated spatial range, duplicate-coordinate fallback jitter, weighted/missing-data fits, q1 spatial, labels, correlated or multiple slopes, extra random layers, new-data SD prediction, uncertainty workflows and live Julia parity remain unassessed. No commit, push, merge or release occurred. The aggregate acceptance gate remains UNKNOWN because its existing runner is unavailable.

## 11. Team Learning

Test the intended failure layer: a non-symbol matrix expression can be rejected by formula parsing before provider collision checks. Bind known matrices explicitly. Keep fixed coordinate range and jitter in the independent DGP, and distinguish latent fields from their predictor-dependent scaled effects.

## 12. Cross-Product Coverage

This slice covers native complete-data Beta mu with coordinates, one independent intercept plus numeric slope, group-constant selected SD predictors, unit weights and fixed-effect sigma. It exercises kernel identity, likelihood, extraction, conditional workflows and save/reload. It does NOT cover meshes, unused sites, q1 spatial, labels, multiple slopes, sigma spatial effects, other random layers, missing data, new-data prediction, uncertainty workflows, marginal two-field draws, coverage, Julia parity, full checks or release.

## 13. Prose Assessment

The separate exact-draft assessment is stored with the evidence. Scientific and factual judgments are limited to the saved source, tests and example. No external reference claim is made.
