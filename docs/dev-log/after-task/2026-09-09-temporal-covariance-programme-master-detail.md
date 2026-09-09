# After-task — temporal covariance Ultra Master Plan detail repair

## 1. Goal

Make the approved temporal covariance master plan visibly executable by adding named agents, model and effort routing, phases, ownership, hand-offs, parameter contracts and gate artifacts.

## 2. Implemented

Added the S0–S6 dispatch board, parent-to-child launch rule, shared parser/omission contract, formula/parameter/output matrix, and gate-to-artifact map to the master plan.

## 3a. Decisions and Rejected Alternatives

The plan fixes sequencing and evidence requirements but does not preselect the P2/P4 positive-definite Toeplitz map. P2.0 must choose it using stated derivative, reconstruction and positive-definiteness evidence.

## 4. Files Touched

- `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/MASTER-PLAN.md`
- `docs/dev-log/check-log.md`
- this report
- `docs/dev-log/plan-actual/2026-09-09-temporal-covariance-programme-master-detail.md`

## 5. Checks Run

`git diff --check` passed. The Unlazy status parser read 33 master gates and correctly reported 25 currently unmet future/implementation gates; it ran no gate commands.

## 6. Tests of the Tests

The status-only Unlazy invocation distinguishes recorded checkboxes from execution and reports the seven checked gates with runnable commands as unexecuted in this planning worktree.

## 7a. Issue Ledger

No new implementation issue was found. Existing P1 methods and all later-model gates remain open by design.

## 8. Consistency Audit

The dispatch board agrees with the existing P0–P6 order, master ledger, maximum-level boundaries and campaign-authority separation. The parameter table preserves the stated OU and heterogeneous-AR1 transforms while leaving the unresolved Toeplitz map explicitly unresolved.

## 9. What Did Not Go Smoothly

The earlier master document held most operational details in phase prose, making the plan look underspecified when scanned from the top.

## 10. Known Residuals

The plan does NOT cover an implemented homtoep, hetar1, hettoep, ARMA, seasonal, random-walk or temporal Matérn provider. It does NOT authorize a campaign, push, merge, release or external message.

## 11. Team Learning

A master plan needs an up-front dispatch dashboard plus phase prose: agent lenses alone do not make model, effort, artifact ownership or hand-off requirements easy to audit.

## 12. Cross-Product Coverage

This repair does NOT cover source-code behavior. It aligns the programme specification, Unlazy ledger interpretation and future child-arc launch discipline.
