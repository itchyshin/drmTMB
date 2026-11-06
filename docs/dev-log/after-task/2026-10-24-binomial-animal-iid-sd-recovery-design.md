# After Task: Binomial Animal and IID SD Recovery Design

## 1. Goal

Check whether the Binomial model can recover separate predictor-dependent scales for an animal intercept and an independent site intercept, using a synthetic design that does not align site membership with the animal covariance ordering.

## 2. Implemented

Reworked the focused recovery fixture to assign animals to sites in balanced random order, use a moderate AR(1) animal relationship matrix, and generate both log-SD slopes as 0.45. The recovery case now uses 192 animals, 48 sites, and 24 observations per animal. No R builder or TMB likelihood code changed in this task.

## 3a. Decisions and Rejected Alternatives

Kept the original recovery tolerance unchanged. The smaller fixture's site assignment followed the animal order used by its AR(1) matrix, so that fixed seed did not distinguish the two latent intercept components well. Relaxing its tolerance would have hidden a weak recovery design.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-iid-sd-regression.R`
- `docs/dev-log/evidence/binomial-animal-iid-sd-recovery-20261024/test.log`
- `docs/dev-log/evidence/binomial-animal-iid-sd-recovery-20261024/source.sha256`
- This report, the check log, the goal checkpoint, the acceptance ledger, and the team-improvement log.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "binomial-animal-iid-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`: passed, exit code 0. The exact console output is in `docs/dev-log/evidence/binomial-animal-iid-sd-recovery-20261024/test.log`.
- The focused test file has 48 passing expectations. `tools/check-after-task.R` passed the report structure check; its programme acceptance-ledger check returned `UNKNOWN` because the ledger has no runnable gate node/check command.
- The saved report passed `slop_check.py` with zero findings.
- Two additional fixed-seed local fits on the larger randomized design converged. Their fitted animal and IID log-SD slopes were 0.468 and 0.464 for seed 20261024, and 0.680 and 0.329 for seed 20261025; the truth was 0.45 for both.
- The original smaller design failed its IID slope check: estimate 1.014 versus truth 0.25, absolute difference 0.764.
- Read the checked-in Graft cards for `R/drmTMB.R` and `src/drmTMB.cpp`. The `graft` command-line tool is unavailable in this environment.
- `git diff --check` and source-hash capture passed for the test and reviewed model files.

## 6. Tests of the Tests

The old recovery fixture reproduced its failure before the design change. The focused test also retains negative checks for unsupported animal slopes and the missing-response route, and it checks the two SD design matrices, group indices, coefficient identities, predicted scales, and save/reload results.

## 7a. Issue Ledger

Searched open issues for predictor-dependent random-effect SD and Binomial animal routes. No directly matching implementation issue appeared. Issue #59 concerns the broader simulation framework; it does not own this model slice, so no issue was changed.

## 8. Consistency Audit

The model uses separate log-SD predictors for the IID site intercept and the structured animal intercept. In TMB, both scale their own latent effects; the animal field retains the supplied relationship matrix. The reviewed R data assembly passes separate design matrices and row mappings. This source review found no obvious wiring error, but it is not an independent numerical likelihood oracle.

The exact status scan was `rg -n "animal.*IID|IID.*animal|animal\\(1 \\|.*A.*\\).*\\(1 \\|" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. Existing formula documentation describes animal and ordinary Binomial SD routes separately; this combined route still needs a user-facing example and a wider documentation reconciliation.

## 9. What Did Not Go Smoothly

The initial 24-site fixture made animal relatedness and site membership track the same ordering. The resulting recovery miss was real for that dataset but did not by itself show that the likelihood was wrong. Separating those design features and increasing the number of groups produced stable recovery in the checked seeds. The combined route still lacks an independent objective oracle.

Lane preflight found many recent repository refs, and the shared lease registry remained locked without a visible owner while its checks were running. I did not remove the lock or change shared model source; this task changed the recovery test and general-SD progress records in the active goal worktree.

## 10. Known Residuals

This is one native Binomial point-recovery and output slice. It does not establish interval coverage, Julia parity for the combined animal-plus-IID structure, other response families, other structured providers, or programme-wide support. The user-facing documentation and full R, Julia, and bridge regression checks remain open. No calibrated-uncertainty claim follows from these fits.

## 11. Team Learning

For a structured plus IID random-intercept recovery test, assign the ordinary groups independently of the ordering used to build the structured covariance. This keeps the two latent components distinguishable in the synthetic example. Added this check to `docs/dev-log/team-improvements.md`.

## 12. Cross-Product Coverage

This task covers the native Binomial animal-intercept plus independent IID site-intercept fit, point recovery, named scale predictions, and save/reload for the tested complete-data case. It does NOT cover other kernels, animal slopes, labelled correlated blocks, other endpoints, Julia execution of the combined model, interval workflows, or coverage calibration.

## Prose Assessment

Style: 2/10, medium confidence. Genre/coverage: short internal after-task report, reviewed in full. Evidence/repair: the opening states the test question and design change; the residual section gives the exact untested boundaries. No wording change needed. Gates: scientific claims are limited to the two seeded fits and source review; factual claims match the saved test log and worktree sources; references are not applicable because no external source is cited. Provenance: self-review, saved report version, 2026-10-24; no control text was used.
