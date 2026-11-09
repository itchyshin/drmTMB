# 2026-11-08: R message for a failed Julia fit

Goal: when the Julia bridge reports `fit_failed = TRUE` (DRModels.jl #1270), R warns, marks the object, and prints a FAILED FIT line. A bridge that sends no `fit_failed` key behaves as before.

Commands run locally on the Mac, from a worktree on `origin/main` `bfa7acf5b`:

- `devtools::load_all()` then `testthat::test_file()` on the new `test-julia-failed-fit-message.R`: 27 pass, 0 fail, 0 warn, 0 skip.
- Neighbouring bridge tests, all 0 fail and 0 error: `test-xfam-bridge.R` (54 pass), `test-coefficient-labels.R` (122), `test-coevolution-accessors.R` (25), `test-julia-binomial-sd.R` (44), `test-julia-biv-inference.R` (37).

Claim boundary: hand-built bridge results only. The Julia bridge was not run end to end, so the real `fit_failed` payload from DRModels.jl #1270 is not yet checked. No exports, no NAMESPACE or Rd change, no likelihood or API change. The full package check was not run.
