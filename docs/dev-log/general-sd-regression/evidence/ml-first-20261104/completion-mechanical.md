# Independent completion panel — mechanical evidence

Date: 2026-11-04  
Scope: read-only audit of row accounting, source binding, attempt preservation, and integration status for the approved first-delivery article lane. No R/Julia fits were run by this panel.

## Verdict

No mechanical blocker found in the audited artifacts. The six route adjudications are scoped source admission and implementation only; all 21,246 rows remain in the generated view, and exact-source runtime, public outputs, examples, and calibration remain unknown/deferred as appropriate. The full general-SD programme is still open. Do not treat this panel as article acceptance or integration completion.

## Evidence checked

- `current_route_status.py` and its 20 unit tests: all 20 pass. Tests cover row-loss detection, duplicate identities, exact joins, refusal of stale/insufficient pins, interface qualification, and path containment.
- Regenerated-artifact check using the explicit Julia worktree `/Users/z3437171/.codex/worktrees/sd-article-ml-julia/DRM.jl` and six-row adjudication JSON: `CURRENT_ROUTE_AUDIT_PASS`.
- `check_artifacts.py`: `ML_FIRST_ARTIFACT_INTEGRITY_PASS`.
- Current route table: 21,246 rows, 21,246 unique row keys; 20 families. It retains 812 evidence records linked to 369 exact rows and 20,877 unlinked rows. Six rows alone have `admitted_scoped` and `implemented_scoped`; the other 21,240 remain unknown for those fields. All 21,246 remain unknown for exact-source runtime, public output contract, and docs example; calibration is deferred for all.
- The six grants are native and Julia routes for Binomial/iid intercept, Poisson/iid intercept, and Gamma/relmat intercept. The overlay explicitly records limits, next task `S4-current-example-runtime`, and separate runtime/output status. Hash-checking source pins against the corrected explicit Julia root succeeds. No evidence of broad-family or whole-programme promotion found.
- Gap reproduction ledger has 23 rows, 15 distinct concern/seed/phase combinations, and a result-log reference for every row. It retains initial, frozen-verification, and frozen-verification-final attempts. Statuses include returned failures, errors, unresolved missing-seed-log, known unrepaired finding, pending regression, and pass; they are not collapsed into success. ZeroOneBeta probe output retains the Hessian/non-finite failure trace.
- Frozen verification receipt records `EXECUTIONS_COMPLETED_SOURCE_UNCHANGED`, with snapshot equality across its jobs from 19:24:08 to 19:30:04 UTC. Its verification script names both exact worktree roots, hashes source snapshots before and after each job, and stops on nonzero exit or source drift. The current-source LSS receipt check reports `PHYLO_LABEL_RECEIPT_PASS` (12 labels, 72 rows, 8 checks, tolerance 4e-06). The ZeroOneBeta probe failures are reproduced evidence, not a green repair claim.

## Blockers versus pending integration gates

No artifact-accounting or source-binding blocker found in this audit. Pending gates remain material: the full R package check is still running on Totoro; CI, merge, and main post-merge checks are not complete; publication/deployed-page verification remains pending. These are integration gates, not reasons to demand closure of the broader G0-G4/G6-G8 programme. G5 and D-342 remain deferred under the approved scope.

The parent-generated current view was checked with the explicit new Julia root; if either source worktree changes, rerun the generator check before relying on these pins. The frozen receipt only proves no source drift during its recorded executions, not that every source claim in the larger audit has runtime evidence.
