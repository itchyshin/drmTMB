# GOAL — deliver useful Gaussian temporal AR1 random effects in drmTMB

Implement the approved temporal AR1 provider in an isolated worktree.  The supported
first slice is a univariate Gaussian mean model with `temporal(1 | id, time =
occasion, structure = "ar1")`, optionally alongside exactly one ordinary `(1 | id)`
random intercept.  It estimates a shared temporal process SD and persistence, retains
separate residual `sigma`, and exposes fixed-effect Wald intervals only.

## Definition of done

- [ ] Parser, native likelihood, methods, tests, documentation, and generated files implement the approved API.
- [ ] Unlazy gates prove deterministic likelihood identities, output behavior, recovery evidence, and package integration.
- [ ] A timed calibration pilot is retained; no 5,000-dataset campaign is submitted before recorded G17 approval.
- [ ] Independent review, after-task evidence, plan-versus-actual reconciliation, and a local commit are complete.

## Invariants

- Preserve true integer gaps, independent series, and separate random-intercept, temporal-process, and residual variation.
- Allow Wald intervals only for fixed mean effects. Refuse profile/bootstrap/variance-component intervals, `newdata` prediction, forecasting, OU, temporal slopes, wider families, and unapproved random-effect combinations.
- Do not push, merge, release, publish, send external messages, alter credentials, or submit remote computation without its named authority.

## Pre-authorisation

Scoped edits, local builds/tests/renders, checkpoints, local commits, and a bounded timing pilot are authorised. Stop for an actual campaign submission, an estimate above the approved pilot boundary, an ownership collision, or evidence that changes this model contract.
