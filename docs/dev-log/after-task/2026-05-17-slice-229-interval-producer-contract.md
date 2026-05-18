# Slice 229 Interval Producer Contract

## Goal

Define the metadata contract for real Phase 18 interval producers before
attaching Wald, profile, or bootstrap intervals to simulation surfaces.

## What Changed

- Added `docs/design/43-phase-18-interval-producer-contract.md`.
- The design note defines required interval columns: endpoints, confidence
  level, method, reported scale, status, and failure message.
- It records the boundary that known `meta_V(V = V)` inputs are not estimated
  interval targets.
- It records the correlation rule: Wald intervals for `rho12` and random-effect
  correlations should distinguish raw-rho intervals from Fisher-z
  back-transformed intervals, while profile endpoints should be reported on the
  public target scale.

## Checks

- `air format docs/design/43-phase-18-interval-producer-contract.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-229-interval-producer-contract.md`
- `git diff --check`

## Limitations

This slice is a design contract only. It does not compute Wald, profile, or
bootstrap intervals.

## Standing Roles

Fisher shaped the interval metadata and correlation-scale rules. Noether kept
reported scale separate from internal transformed scale. Pat kept the contract
reader-facing. Rose kept missing intervals visible through status and message
columns. Ada kept implementation deferred until the contract was explicit.
