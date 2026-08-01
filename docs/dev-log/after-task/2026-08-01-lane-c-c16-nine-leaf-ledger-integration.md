## 1. Goal

Integrate the explicitly authorized, source-bound point-fit transitions for
`mc-0584`--`mc-0587` and `mc-0593`--`mc-0597` after `mc-0583` merged.

## 2. Implemented

Bound the nine existing C16 completion receipts into the canonical ledger,
added one append-only transition and one recovery evidence record per cell,
and regenerated the capability surface. The model-surface census is now 327
implemented, 340 rejected-by-design, and 20 not implemented.

## 3a. Decisions and Rejected Alternatives

Promoted only the nine named, q1, ordinary-ML zero-one-beta structured mu/sigma
leaves. No q2-plus boundary, slope, label, covariance, zoi/coi, profile,
interval, coverage, or formula grammar status was changed.

## 4. Files Touched

- `docs/dev-log/dashboard/capability-ledger/cells.tsv`
- `docs/dev-log/dashboard/capability-ledger/evidence.tsv`
- `docs/dev-log/dashboard/capability-ledger/transitions.tsv`
- generated capability census, surface, and family-map files
- `tools/capability_ledger.py`
- `tools/tests/test_capability_ledger.py`

## 5. Checks Run

- `python3 tools/capability_ledger.py --write` — regenerated 30 outputs.
- `python3 tools/capability_ledger.py --check` — passed.
- `python3 -m unittest tools.tests.test_capability_ledger` — 46 tests passed.
- Direct model-surface count audit — 327 implemented / 340 rejected-by-design /
  20 not implemented.
- `git diff --check` — passed.

## 6. Tests of the Tests

The ledger unit test initially failed against the superseded 318/340/29 and
169-frozen-recovery guard values. Updating only the named C16 transition set
made the test enforce 327/340/20, 178 frozen point-fit cells, and 179 total
point-fit cells; it does not permit an unrecorded promotion.

## 7a. Issue Ledger

Fixed: the C16 ledger guards still described the one-cell `mc-0583` state.
Deferred: the 20 remaining not-implemented model-surface cells retain their
existing status and need separate exact contracts/evidence.

## 8. Consistency Audit

Checked each promoted row has the exact C16 recovery evidence ID, source SHA,
G3 gate, point-fit tier, and provider-specific completion review. The paired
q2-plus rows `mc-0696`--`mc-0704` remain rejected-by-design.

## 9. What Did Not Go Smoothly

The first focused ledger-test run exposed stale expected counts. This was a
guard update, not evidence repair; the retained oracle and recovery evidence
was unchanged.

## 10. Known Residuals

This is local technical point-fit recovery only. It provides no profile,
interval, calibration, coverage, or inference-ready claim.

## 11. Team Learning

Memory receipt: loaded the repository operating contract, route check, Lane C
preflight, and a whole-brain C16/PR lookup; source-bound evidence rather than
prior-run equivalence controlled promotion. Golden Set: not separately run;
the scoped ledger unit suite and generator are the relevant mechanical guards.

## 12. Cross-Product Coverage

Covers: ordinary-ML zero-one-beta q1 structured `mu`/`sigma` intercept leaves
for the nine named providers, their exact source-bound receipts, and the
generated capability surface.

Does NOT cover: zoi/coi endpoints, slopes, labels, covariance, q2-plus,
REML, other families/providers, profiles, intervals, coverage, or public
inference claims.
