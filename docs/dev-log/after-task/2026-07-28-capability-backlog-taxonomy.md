# Capability backlog taxonomy correction

## Purpose

Make the full model-surface census visible as work: a cell that is not currently
implemented is not thereby impossible or permanently rejected.

## Scope

The change is limited to the generated capability ledger and its rendered
dashboard assets. It does not implement any model, estimator, or interval.

## Change

The former 330 `rejected_by_design` model-surface rows are now
`not_implemented` with `backlog` work state. The census is consequently 307
implemented and 370 not implemented cells. The generated detailed surface adds
a planning-class column:

- **admission candidate**: an unimplemented fixed or ordinary-random-effect ML
  route;
- **covariance / model method**: a structured-effect extension; and
- **estimator method**: a REML or AI-REML extension.

These are planning classes, not feasibility guarantees, effort estimates, or
inference claims.

## Estimator boundary

ML and REML are separate objectives. A successful ML implementation does not
automatically make the corresponding REML cell valid or available. REML rows
remain visible backlog until their restricted-likelihood objective, tests, and
route-specific evidence exist.

## Evidence and checks

- `python3 -m unittest tools.tests.test_capability_ledger` — 41 tests passed.
- `python3 tools/capability_ledger.py --check` — 30 generated outputs current.
- `git diff --check` — pending at closeout.

## Does not claim

This does not promote any cell, change an evidence tier, make ML and REML
interchangeable, provide intervals, or establish inference readiness. It also
does not change the independently monitored Arc 6 association campaign.

## Follow-up

Use the new planning classes to choose bounded implementation arcs. Each chosen
cell still needs its own formula/likelihood review, tests, and recovery evidence
before its status can move to `implemented`.
