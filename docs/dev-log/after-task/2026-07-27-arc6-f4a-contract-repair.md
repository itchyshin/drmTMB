# After-task report — Arc 6 F4a alpha contract repair

## 1. Goal

Repair the two F4 preregistration omissions identified by Noether without
implementing a runner, changing package code, or beginning compute.

## 2. Implemented

The F4 review now fixes the private alpha path as
`drm_pair_general_eta_sandwich(b, nb, a)`, permits only `a$alpha` plus
`s$alpha_covariance` / `s$alpha_se`, and defines the point, Godambe, and
interval availability denominators.

## 3a. Decisions and Rejected Alternatives

Conditional association curvature, eta-scale quantities, public `vcov()` and
`confint()`, and internally retained boundary coefficients are inadmissible.
Near-boundary associations are unavailable for F4 point or interval inference.

## 4. Files Touched

- `docs/dev-log/2026-07-27-arc6-f4-preregistration-review.md`
- `docs/dev-log/after-task/2026-07-27-arc6-f4a-contract-repair.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

Read the private sandwich implementation and F3 runner, confirmed the exact
alpha covariance and standard-error fields, and passed `git diff --check`.

## 6. Tests of the Tests

No executable code changed. The amendment binds future F4 metrics to the
existing private helper and does not create a new numerical implementation.

## 7a. Issue Ledger

Resolved: the F4 alpha-extraction and denominator omissions. Deferred: runner
implementation, exact execution SHA/runbook, DRAC compute, F4 evidence, and
all public inference work.

## 8. Consistency Audit

Point, Godambe, and interval summaries have distinct named denominators;
primary coverage remains all-valid-protocol and treats unavailable intervals as
non-coverage.

## 9. What Did Not Go Smoothly

The older preregistration described nested counts but did not bind each summary
to one of them. F4a fixes that ambiguity before it can enter a runner.

## 10. Known Residuals

F4 remains unexecuted. No alpha SE, Wald interval, recovery, coverage, or
public claim is established.

## 11. Team Learning

An internal coefficient is not automatically a valid inferential estimate;
availability must be defined before summary statistics are calculated.

## 12. Cross-Product Coverage

This F4a amendment covers only the fixed-effect Bernoulli x ordinary-NB2
intercept-only association candidate. It does NOT cover all other pairs,
association slopes, eta intervals, random effects, missingness, weights,
offsets, REML, direct `rho12`, or Arc D.
