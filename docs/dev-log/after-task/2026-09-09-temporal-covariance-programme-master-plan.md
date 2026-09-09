# Temporal covariance Ultra Master Plan closeout

## 1. Goal

Replace the high-level temporal covariance roadmap with an execution-grade Ultra Master
Plan that specifies phases, agents, models, effort, file transfers, formula/API
contracts, evidence, compute rules and a master Unlazy ledger.

## 2. Implemented

Added `MASTER-PLAN.md` and `unlazy/MASTER-GATES.md` beneath the existing temporal
programme plan. The plan sequences phylogenetic-stable plus independent OU, homogeneous
Toeplitz, heterogeneous AR1, heterogeneous Toeplitz, then one science-triggered item-6
candidate. It adds no package implementation.

## 3a. Decisions and Rejected Alternatives

The programme has one bounded implementation arc at a time. P2, P3 and P4 reserve the
canonical public keywords `homtoep`, `hetar1` and `hettoep`; aliases are rejected. Their
initial common-level limits are 12, 12 and 8. P1 validates metadata before omission,
then applies the existing listwise policy and rejects a retained singleton temporal path.
ARMA remains a later independent-within-id ARMA(1,1) candidate, never generic order
selection or a shared-shock shortcut.

## 4. Files Touched

- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/MASTER-PLAN.md`
- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/MASTER-GATES.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

The direct bundled-Node invocation of Unlazy's gate parser read the master ledger as 33
unique, intentionally unmet gates. `git diff --check` passed. Targeted searches confirmed
canonical public forms for homogeneous Toeplitz, heterogeneous AR1 and heterogeneous
Toeplitz. These are planning/document checks, not model tests.

## 6. Tests of the Tests

The detailed plan requires Phase 0 to materialize the P1/source-map runners and prove
their negative controls before M01--M03 invoke them. It forbids running a future gate
runner merely because it appears in a ledger. T3's selected positive-definite map, T4's
D R D covariance and T5's valid-R map each require independent dense oracles and named
mutations before inference or calibration.

## 7a. Issue Ledger

No external issue, message, campaign, push, merge, release or deployment occurred.

## 8. Consistency Audit

Two independent reviews checked the master plan. Formula review required and accepted
repairs for the Node invocation, runner materialization, missing-response/singleton
semantics, canonical grammar and fixed level limits. Integration review required a
committed immutable master revision before approval and an explicit runner-file lease
transfer from Phase 0 to P1 evidence; both are incorporated before this closeout commit.

## 9. What Did Not Go Smoothly

The initial master ledger claimed 31 gates while it contained 32; the bootstrap gate
increased the final count to 33. The exact parser exposed this before the plan was
committed. An initial command displayed `node` followed by the Node binary as though it
were JavaScript; direct execution exposed the error and the plan now calls the binary
correctly.

## 10. Known Residuals

All 33 master gates are pending until this commit is fingerprinted and the user approval
is recorded as M00. Phase-0 runners, a fresh execution worktree, NotebookLM source map,
package implementation, simulations and campaigns do not yet exist. The master plan does
not make AR1, OU or any future structure more broadly supported than its retained
evidence permits.

## 11. Team Learning

An Ultra Master Plan needs operational details as well as model order: who creates each
gate runner, who owns it after bootstrap, exactly which public keywords are canonical,
where omission happens and what dimensions are allowed. These are implementation
contracts, not editorial refinements.

## 12. Cross-Product Coverage

This task covers the detailed plan for Gaussian temporal covariance sequencing. It does
not cover a new fitted model, native compilation, inference evidence, reader rendering,
remote compute, a campaign, push, merge, release, deployment or external communication.
