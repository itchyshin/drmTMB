# PR #1651 reconciliation with prior release main

The combined source `ba09d0f52726c5f6cb0f4e39390b2027d57157a7` passed the
C17 compatibility recertification at zero tolerance: all three stored summaries
were identical and all 12 attempts passed their cell criteria. The capability
ledger check, 92 ledger unit tests and C14 receipt-equivalence check passed.
The documentation semantics test passed in a local `devtools::load_all()`
session. It did not exercise the live Julia bridge. The receipt records its
source and dirty-state snapshot under
`docs/dev-log/implementation-recovery/2026-11-08-codex-pr1651-reconcile2-c17c2-c14-final-source-compatibility/`.
