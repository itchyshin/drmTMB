# After-task report — Arc 6 F5 public S3 design

## 1. Purpose

Recorded the future public `vcov()`/`confint()` contract for the one potential
Bernoulli x ordinary-NB2 alpha-inference route while F4 runs.

## 2. Scope

Documentation only.  No R, C++, test, runner, compute, API, ledger, or public
claim changed.

## 3. Decision

If F4 passes and F5 is separately approved, expose only a named alpha 1 x 1
Godambe covariance and a 95% alpha-Wald interval for the validated fixed-effect
complete-pair intercept route.  All other association objects remain
informative failures.

## 4. Evidence and limits

The design derives from the frozen F4 alpha contract.  It is not evidence that
the public method is valid; F4 results and a fresh completion panel remain
required.

## 5. Files

- `docs/dev-log/2026-07-27-arc6-f5-public-s3-design.md`
- this report

## 6. Deferred work

F4 completion, independent review, separate F5 authorization, implementation,
tests, package checks, public documentation, merge, and release remain
deferred.
