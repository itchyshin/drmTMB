# Targeted validation

Base runtime: 476afc4ceff7bb819145af1831b9e973a97d1522. Exact command:

```r
pkgload::load_all(quiet = TRUE, recompile = FALSE)
testthat::test_local(filter = "^(check-conditioning|objective-at|phase18-count-mu-random-effect-pilot)$", reporter = "summary", stop_on_failure = TRUE)
```

OPENBLAS_NUM_THREADS, OMP_NUM_THREADS and VECLIB_MAXIMUM_THREADS were 1. The command exited 0. All three test files passed with no failures, one existing NaNs-produced warning and one existing platform non-PD skip in the near-collinear conditioning fixture. No test threshold or skip policy changed.

The old q4 fixture fails the new explicit convergence premise. The new related-tip fixture passes convergence, positive-Hessian and unchanged 1e-8 objective checks; its standalone probe takes 1.206 seconds with zero anchor difference. Existing q4 displacement and refusal tests pass.

Independent reviewer found no P0/P1/P2 concern and requested two stale comment fixes, both applied. The reviewer checked the generated matrix-normal endpoint construction and residual correlation separately, and noted this fixture does not establish parameter recovery or every label independently.

`git diff --check` passed. `git diff --exit-code 476afc4 -- R src tools .github` passed. After-task structure validator and prose checks passed. Existing unresolved Windows pilot warning is now printed if it recurs; this repair does not claim to have eliminated that warning.

## Root-caused Windows warning follow-up

Initial repair source d295296c499d9d0b3026a42668959007c1321ef7 passed Linux and macOS in full matrix run 39145513509. Windows passed the objective fixture and failed only the count pilot warning: poisson_mu_random_effect_001/warning: collapsing to unique 'x' values.

The deterministic pure duplicate-objective test failed before the runtime fix. The final pure suite passed all nine assertions without warnings. The broader affected suite ran test-profile-targets.R, test-phase18-count-mu-random-effect-pilot.R, test-optimizer-selection-downstream.R and the new interpolation tests; it exited 0 with no failures/errors/skips and six existing sd_phylo1/sd_phylo2 deprecation warnings. It covers all three callers of drm_tmbprofile_confint. Output is retained in profile-ties-affected-tests.log. The final pure test file was rerun after removing an incidental requirement that upstream TMB continue warning; it passed again.

Independent review compared the first-minimum split, right-side minimum exclusion, cutoff, mean ties, NA policy and output names against installed TMB 1.9.21. A repeated-minimum example matched exactly. No blocking finding remained. Future upstream warning fixes will not break the regression test; substantive numerical convention drift remains visible through exact compatibility assertions.

After final runtime source changes, run-julia-phylo-labels-public.R genuinely reran with the same pinned DRM.jl and explicit Julia 1.13.0. All eight checks passed in 51.75 seconds with source_unchanged true. Current-source checker plus all 12 mutation self-tests passed; ci-receipt-staleness.sh matched all 56 R files, 95 Julia files and runner; C14 remains green. Previous receipt files remain verbatim under historical-pre-profile-ties-2026-10-18/.

The only runtime difference from origin/main is R/profile.R's explicit interpolation convention. No C++ source, likelihood, optimizer, profile cutoff, tolerance, warning classifier or workflow changed. NEWS and inst/COPYRIGHTS document the change. Post-push Windows and full CI outcomes remain pending.
