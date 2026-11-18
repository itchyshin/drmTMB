# After-task report: julia simulate and predict_parameters duplicate methods

Date: 2026-11-01. Base: bee7f6c4f (codex/general-sd-regression, PR #1663).

## What happened

R/julia-simulate.R was untracked in the lane worktree, so it was missing from the committed tree. The committed man/simulate.drmTMB.Rd had been generated with it present. The result was a code and doc mismatch (re.form documented, absent from the committed method) and a duplicated usage entry. A second duplicate of the same kind existed for predict_parameters.drmTMB_julia.

## Changes

1. Added R/julia-simulate.R (copied unchanged from the lane worktree). It is the richer simulate.drmTMB_julia: re.form = NA means fresh random effects (lme4 convention, same helpers as simulate.drmTMB), re.form = NULL is refused for Julia Laplace fits, and fixed-effect fits go to simulate.drmTMB. DESCRIPTION has no Collate field, so nothing to update.
2. Removed the old fence simulate.drmTMB_julia from R/julia-bridge.R. It was a refusal stub and, with the collation order, was shadowed or shadowing the richer method.
3. Removed the old fence predict_parameters.drmTMB_julia and its helper drm_julia_method_fence from R/julia-bridge.R. R/predict-parameters.R (tracked, collated later) already defines the real method, so the fence was dead code; the helper became an orphan after both removals.
4. Hand-edited man/simulate.drmTMB.Rd and man/predict_parameters.Rd: dropped the duplicated usage block and the stale source-file name in the header. Totoro has roxygen2 7.3.3 while DESCRIPTION records 8.0.0, so regeneration there would have rewritten many Rd files. The edit is the minimal one that roxygen 8 would produce.
5. R/drmTMB.R validate_binomial_mu_random_terms: removed the false clause saying structured effects beyond one unlabelled q = 1 phylo() or relmat() mu intercept remain unsupported (animal, spatial, slope and q2 routes are admitted). The hint now lists only what is still refused: labelled slopes, labelled correlated blocks, additional correlated blocks. No test pinned the old wording.

None of the source edits fixes a numerical bug. Items 1 to 3 resolve a duplicate definition caused by an untracked file; item 5 corrects a message.

## Per-failure table (test-julia-bridge.R)

| test:line | cause class | evidence | fix |
|---|---|---|---|
| test-julia-bridge.R:63 (coefficient-selected SD targets) | (a) stale test | drm_julia_formula_spec returns an unnamed positional vector for selector-bearing ordinary SD targets, deliberately, since b87566680 ("Bank native predictor-dependent SD routes"); the test indexed it by dpar name | Assert names(spec) is NULL and check spec[[2]] and spec[[3]] by position; same strings as before |
| test-julia-bridge.R:1006 (simulate refuse by name) | (a) stale test | simulate.drmTMB_julia is now wired; the by-name fence is gone. predict_parameters.drmTMB_julia in predict-parameters.R also supersedes the fence | Swapped to a still-refused route: Gamma fit with an ordinary random intercept errors with "Marginal simulation is not implemented for this Julia random-effect model" |
| test-julia-bridge.R:1014 (refusal message text) | (a) stale test | same cause; the msg was NULL because predict_parameters no longer refuses by name | Replaced by two still-refused predict_parameters routes: unknown dpar and stray option. The meaningless "extended class" assertion about the removed fence was dropped |
| test-julia-bridge.R:945, 966 | (c) environment only | Live Julia tests; drm_skip_live_julia() skips them when DRMTMB_JULIA_TESTS is unset or no Julia is present, correct as is | None |

## Verification (Totoro, 4 cores max, load_all, NOT_CRAN=true)

Counts are passed, failed, error, skipped. Julia-live parts skip on Totoro (no Julia); the two Gamma simulation files and the cross-engine file are fully skipped there, so their live behaviour is not exercised in this report.

- test-julia-bridge.R: 151 0 0 2
- test-julia-gamma-animal-intercept-simulation.R: 0 0 0 1 (Julia-live)
- test-gamma-animal-q2-nonunit-kernel-simulation.R: 0 0 0 1 (Julia-live)
- test-gamma-animal-q2-cross-engine-sd.R: 0 0 0 1 (Julia-live)
- test-simulate-predict-unused-args.R: 11 0 0 0
- test-simulate-re-form-phylo-interaction.R: 13 0 0 0
- test-simulate-re-form.R: 22 0 0 0
- test-nbinom2-structured-slope-marginal-simulate.R: 42 0 0 0
- test-binomial-response.R: 60 0 0 0
- test-predict-parameters.R: 80 0 0 0
- tools::codoc, checkDocFiles, checkS3methods on the source dir: no findings.

## Not covered

The Julia-live simulation tests were not run on the Mac. R CMD check was not re-run end to end. Worktree note: the isolated worktree started at main (b535bfbcc) rather than the stated lane commit, so it was moved to a detached HEAD at bee7f6c4f before any edit.
