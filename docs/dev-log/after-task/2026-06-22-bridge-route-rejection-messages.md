# After-Task Report: Bridge Route Rejection Messages

## Task

Bank slice S037 by making intentional R-to-Julia bridge rejection messages part
of the tested and dashboard-validated contract.

## Changes

- Tightened `expect_julia_gate()` so every intentional gate still errors before
  Julia setup and the message contains both the registered pattern and
  route-specific guidance.
- Added native-engine guidance to currently bare `weights` and `impute`
  rejections on the base, structured, and cross-family bridge routes.
- Added `docs/dev-log/dashboard/bridge-rejection-messages.tsv` and
  `docs/design/191-bridge-route-rejection-messages.md`.
- Extended mission-control validation so the rejection-message table must match
  the current intentional-gate registry.

## Checks

```sh
Rscript -e 'devtools::test(filter = "julia-gate-vs-engine", reporter = "summary")'
tools/validate-mission-control.py
git diff --check
```

## Result

Intentional route rejections now carry tested user guidance and dashboard
evidence.

## Claim Boundary

S037 keeps every covered row at `intentional_error`. It does not relax bridge
gates, add R-via-Julia fitting, change formula grammar, change REML support,
add q4 interval coverage, claim non-Gaussian REML, expose public
`engine_control`, or touch Ayumi-facing text.
