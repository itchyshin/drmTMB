# Lane C Z5 — zero-one-beta sigma q1 slope after-task report

## Goal and result

Repair and validate only the ordinary ML sigma random-slope candidate
`mc-0576`, with exact formula `bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1,
coi ~ 1)`. The source, focused tests, independent complete-mixture oracle, and
four-seed retained local recovery fixture now support a point-fit-only review.
The ledger has deliberately not moved pending a fresh completion panel.

## What changed

The q1 validator now requires the fixed sigma predictor and the slope inside
`(0 + slope | id)` to be exactly the same symbol. The test rejects the formerly
accepted neighbour `sigma ~ z + (0 + x | id)`, verifies the direct target and
all three profile fences, and retains objective plus AD-versus-central-FD
checks. The recovery runner records atom counts, per-group atom/interior
support, log-sigma range, clamp status, all seed diagnostics, and a zero-true-SD
diagnostic.

## Evidence and boundaries

`tests/testthat/test-zero-one-beta.R` passed after the repair; the ledger
checker passed. The source-authenticated recovery receipt is
`implementation-recovery/2026-07-30-lane-c-z5-zob-sigma-slope-local-run-1/`.
No profile evaluation, interval, bootstrap, coverage, remote compute, Lane A/B
work, Future-extension edit, or Mission Control count update occurred.

## Residual work

The pre-repair four-attempt output remains in the same retained directory but
is superseded as promotion evidence by the fuller rerun. `mc-0576` must remain
not implemented unless a fresh Noether/Fisher/Rose panel returns GO. Other
zero-one-beta slopes and all joint or structured routes remain outside this
claim.
