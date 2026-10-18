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
