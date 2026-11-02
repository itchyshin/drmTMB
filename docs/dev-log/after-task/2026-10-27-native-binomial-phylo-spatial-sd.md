# After Task: Native Binomial Phylogenetic and Spatial SD Regression

## 1. Goal

Add a narrowly bounded native TMB route that fits predictor-dependent scales for a phylogenetic intercept and a coordinate-spatial intercept in the same Bernoulli model.

## 2. Implemented

The Binomial builder now admits this exact q1 pair with separate SD formulas. The phylogenetic and spatial latent fields retain their supplied covariance or precision scaling and contribute separately to the location predictor. Public SD prediction, conditional prediction, structured-effect extraction, marginal simulation, and saved-fit reload retain both targets.

## 3. Mathematical Contract

For tips (g) and sites (h), the tested model uses independent structured fields

\[
b_T = D_T u_T, \quad u_T \sim N(0, K_T), \qquad
b_S = D_S u_S, \quad u_S \sim N(0, K_S),
\]

with `log(diag(D_T)) = X_T alpha_T` and `log(diag(D_S)) = X_S alpha_S`. Each predictor is constant within its corresponding tip or site. The fields are independent conditional on their separate kernels. This slice does not normalize either supplied kernel and does not add cross-field correlation.

## 3a. Decisions and Rejected Alternatives

The first paired structured route is limited to a phylogenetic field plus a coordinate-spatial field. The implementation does not generalize all provider pairs in this slice; it does not normalize supplied kernels or add cross-field correlation. The model remains complete-response, logit Binomial, and q1 for each field.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-binomial-phylo-spatial-sd.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-spatial-sd.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-spatial-sd-20261027/`
- `docs/dev-log/recovery-checkpoints/2026-10-27-145737-codex-checkpoint.md`

The source files already contain other worktree changes. No unrelated hunks were reverted.

## 5. Checks Run

- The focused test first failed at the existing builder refusal for multiple structured Binomial providers, confirming the new test exercised the missing route.
- The expanded focused test passed after implementation.
- The adjacent command in `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-spatial-sd.md` passed all four selected suites: the new tree-plus-spatial test, existing Binomial phylogenetic SD regression and simulation tests, and existing Binomial spatial SD regression tests. The new fixture confirms that both SD coefficient groups map to the shared `beta_sd_mu` vector at distinct indices; per-group SD rows in `profile_targets()` are correctly reported as derived targets. The saved transcript is under `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-spatial-sd-20261027/`.
- `git diff --check` on the changed tracked source and documentation paths found no new whitespace issues. A repository-wide invocation reports an existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R:225`, which is outside this slice and was left unchanged.
- The vignette addition is a syntax example only; the full vignette and pkgdown site were not rendered.
- `tools/check-after-task.R` passed the report structure check. It also warned that the acceptance ledger exists but is not runnable in this environment, so its gate state remains unknown.

## 6. Tests of the Tests

The test initially stopped at the builder guard before the new route existed. The fixture simulates two independent latent fields from the same tree covariance and spatial precision structure used by the fit. Early lower-information settings did not recover both SD trends reliably; the final fixed-seed fixture uses 36 tree tips, 64 sites, and four crossed replicates. This fixture provides point-recovery evidence from one generated dataset; operating-characteristic calibration remains deferred. An exploratory assertion expected per-group SD outputs to map directly to TMB parameters. The profile table correctly marks them as derived, so the final test checks that the two SD coefficient groups map to the shared fixed-effect vector at separate indices.

## 7a. Issue Ledger

The open-issue search returned #1463 (general test sweep) and #59 (simulation framework), neither of which specifically tracks this exact Binomial tree-plus-coordinate-spatial SD pair. No issue was modified and no duplicate issue was opened.

## 8. Consistency Audit

The R syntax in the test and vignette matches the builder selectors: `phylo(1 | species, tree = tree)`, `spatial(1 | site, coords = coords)`, `sd(species, level = "phylogenetic") ~ z_tree`, and `sd(site, level = "spatial") ~ z_site`. The roadmap and scale-model design note now identify the exact supported pair and its point-fit-only boundary. The public output checks compare predictions with each formula's model matrix and confirm that conditional prediction contains both fitted fields.

The broader stale-wording scan was limited to the edited design sections and vignette. README, NEWS, known-limitations, the formula-grammar article, pkgdown navigation, and the generated site were not reconciled in this slice. `docs/dev-log/check-log.md` was not edited because its path preflight remained stalled against the highly shared worktree; the standalone check-log receipt is recorded in `check-log.d/`. The cross-programme direct-SD evidence ledger was also left unchanged because it is an untracked shared artifact in this checkout; the local source manifest records this slice's exact hashes for later ledger integration.

## 9. What Did Not Go Smoothly

The worktree's `R/drmTMB.R` and `src/drmTMB.cpp` contain extensive pre-existing changes, so source review had to stay on the exact builder and likelihood blocks. An existing compile-time typo in the second-field mesh branch (`mu(i)` instead of `eta_mu(i)`) prevented the first compile and was corrected to restore compilation of the affected model source. The first saved-test wrapper also used zsh's read-only `status` variable after the R process completed; the rerun used a distinct variable and exited cleanly.

## 10. Known Residuals

This is one native TMB logit Binomial q1 pair. It does not establish probit or cloglog for the pair, animal/relmat/mesh combinations, correlated fields, incomplete responses, Julia direct or bridge parity, profile endpoints or bootstrap refits for both targets, interval calibration, broad family parity, or package-wide stability. The required-row ledger still needs a direct-SD evidence link for this pair. The overall predictor-dependent random-effect SD goal remains active.

## 11. Team Learning

Structured-provider pairs need separate group-index maps, SD design matrices, and prediction/simulation routing for each field. The highest-value integration check is the combined conditional predictor, because separate SD recovery alone would not catch omission of one field from user-facing predictions.

## 12. Cross-Product Coverage

This slice covers native R/TMB fitting, point recovery, separate group-level SD predictions, combined conditional prediction, marginal simulation, structured-effect extraction, and RDS save/reload for the exact logit Binomial q1 tree-plus-coordinate-spatial configuration. It does not cover Julia direct or bridge parity, interval coverage, or other response-family/effect combinations.

## 13. Next Actions

1. Add this exact capability row to the direct-SD evidence ledger after its shared-file ownership is resolved.
2. Review profile and bootstrap target routing for simultaneous structured fields before advertising those workflows.
3. Continue with the next bounded family/effect combination in the native implementation lane, then add the matching Julia route where the paired engine is ready.
