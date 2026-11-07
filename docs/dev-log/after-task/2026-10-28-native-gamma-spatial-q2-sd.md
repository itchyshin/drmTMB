# After task: Gamma coordinate-spatial intercept and slope SDs

## 1. Goal

Fit separate predictor-dependent SDs for independent coordinate-spatial intercept and numeric-slope fields in a native Gamma model, preserving the existing kernel.

## 2. Implemented

The Gamma builder opts into one unlabelled coordinate-spatial intercept plus numeric slope. The shared validator uses a separate Gamma-only branch with a default-false flag. Removing the new flag and branch reproduces the pre-edit validator bytes exactly. Existing tree, animal, related-matrix and other-family behavior is retained. The Gamma target and data-map gates now include spatial fields; the Beta admission arm is unchanged. No C++ or compiled artifact changed.

Independent fields satisfy u_k ~ N(0,K), b_k=D_k u_k and Cov(b_k)=D_k K D_k, where D_k=diag(exp(W_k alpha_k)). The mean is exp(X beta+b_0+x*b_1), and Gamma shape=sigma^-2. The example pairs spatial(1+x|id,coords=coords) with two coefficient-selected sd(id,level="spatial") formulas.

## 3a. Decisions and Rejected Alternatives

The coordinate kernel retains its existing fixed range: the median strictly positive unordered pairwise Euclidean distance. K=exp(-distance/range)+1e-6 I. It is not normalized, so its diagonal is 1.000001 and marginal field SD is the fitted multiplier times sqrt(1.000001). The range is not an estimated model parameter. The ordinary positive-definite fixture does not exercise the additional jitter fallback.

Seed 2026102801, 64 sites on an 8 by 8 grid with 20 observations per site, slope-error tolerance .4 and absolute likelihood/eta/equivalence tolerance 1e-4 were recorded before fits. Assumptions without asking: reuse these bounded one-seed tolerances from the preceding slices, with coverage deferred. No seed, fixture or tolerance changed after results. Meshes, unused-site prediction and additional random layers are outside this route.

## 4. Files Touched

Scoped changes are in R/drmTMB.R. New files are tests/testthat/test-gamma-spatial-q2-sd-regression.R, inst/examples/gamma-spatial-q2-sd.R, this report, the matching check-log.d fragment and native-gamma-spatial-q2-sd-20261028 evidence directory. No existing test file was edited. Foreign dirty work was preserved.

## 5. Checks Run

The initial red tests failed at the expected intercept-only validator: two errors in 2.994 seconds. The first post-change run passed 41 checks but had one refusal-message error in 17.343 seconds. The lognormal builder correctly refused earlier than the new test expected; the matcher was corrected without changing the model. The final nine-file regression passed 229 checks with zero failures, errors or warnings in 73.126 seconds, below the 180-second estimate. One existing live Julia comparator was skipped because its engine path was unavailable; the live engine was not exercised. The new spatial file contributed 47 checks.

The standalone example converged in 2.950 seconds, estimating SD slopes 0.4861302 and -0.3155446 against truths 0.5 and -0.5. These are one-seed point checks, not general recovery or calibrated uncertainty evidence. No full package check, pkgdown build, interval calibration or live Julia process ran.

## 6. Tests of the Tests

The DGP independently computes pairwise coordinate differences, fixed median range and raw jittered covariance. Its inverse is compared with the assembled precision. A separate dense Gamma density, analytic score and Hessian, two latent-mode starts, finite differences and absolute Laplace correction supply the likelihood oracle. Coordinate row order, factor order and SD formula order differ. Reordered coordinates and reversed SD formulas must preserve the fit; constant-SD formulas must match the base route.

Raw latent fields and separately scaled effects, named group SDs, parameter tables, selected-optimum fitted means, save/reload and seeded conditional simulation are checked. Mesh, labels, slope-only or multiple-slope forms, additional random layers, missing responses and default other-family admission are guarded. Coordinates must cover observed sites only; no unused-site extraction or prediction is claimed. Fresh marginal two-field simulation remains explicitly refused.

## 7a. Issue Ledger

The native Gamma mu spatial_coordinate_slope coordinates candidate is saved in candidate-rows.tsv. The mesh_precision row is excluded. No shared evidence ledger was promoted and no issue or external comment was posted. The full SD programme remains open.

## 8. Consistency Audit

Parent and independent read-only reviewer found no P0/P1 issue in the bounded patch and mathematical contract. The standalone spatial branch closes before the existing provider branches. The exact Julia Gamma spatial-slope route still refuses before setup; static inspection is not runtime parity evidence. The targeted stale-refusal search found no earlier Gamma spatial-slope rejection to update.

Public status maps remain with the documentation lane. Syntax and likelihood parameterization are unchanged; the runnable example and this report describe the candidate. No roxygen regeneration was needed for internal-only code and example changes.

Memory receipt: routed project manifest, graph map and prior Gamma receipts supplied context. The raw-kernel and shared-validator lessons shaped this slice. Golden Set: not run; independent numerical and neighboring checks provide present evidence. No expensive sister-repository scouting was repeated.

## 9. What Did Not Go Smoothly

Preflight and lease scans took minutes. The initial result exposed a test error-message mismatch, repaired by matching the earlier existing refusal. All attempts are retained. The first required-row filter included mesh_precision; it was narrowed to coordinates before any admission or claim. No scientific acceptance rule changed.

## 10. Known Residuals

General bias, interval behavior, coverage, estimated spatial range, duplicate-site fallback jitter, weighted or missing-data fits, meshes, labels, correlated or multiple slopes, extra layers, new-data SD prediction, profile/bootstrap workflows and live Julia parity are unassessed. No commit, push, merge or release occurred. The aggregate acceptance gate remains UNKNOWN if its existing runner is unavailable.

## 11. Team Learning

Keep coordinate-derived range and jitter in the independent DGP rather than drawing from the package precision helper. A non-unit kernel diagonal changes marginal SD even when the difference is small. Add a complete sibling branch to a shared validator and compare untouched bytes before testing neighbors.

## 12. Cross-Product Coverage

This slice covers native complete-data Gamma mu, coordinate-based spatial fields, one independent intercept plus numeric slope, group-constant selected SD predictors, unit weights and fixed-effect sigma. It checks kernel identity, likelihood, extraction, conditional workflows and save/reload. It does NOT cover meshes, unused sites, labels, multiple slopes, sigma spatial effects, other random layers, missing data, new-data prediction, uncertainty workflows, calibration, Julia parity, full checks or release.

## 13. Prose Assessment

The separate exact-draft assessment is stored with the evidence. Scientific and factual judgments are restricted to the saved source, tests and example. No external reference is claimed.
