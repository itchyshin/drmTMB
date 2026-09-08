# After plan: Gaussian temporal AR1 provider

## 1. Goal

Prepare an implementation-ready proposal for Gaussian mean-side temporal correlation
with separate residual `sigma`. This task is plan-only, awaiting user approval and
a fresh Terra medium/high execution task.

## 2. Implemented

Planning artifacts only: [plan](../plans/2026-09-08-temporal-ar1/plan.md),
[acceptance ledger](../plans/2026-09-08-temporal-ar1/acceptance.json), and
[handover](../plans/2026-09-08-temporal-ar1/handover.md).
No R/C++ implementation, compilation, fits, recovery simulations, package checks,
release action or public capability change.

## 3a. Decisions and Rejected Alternatives

Proposed stationary latent AR1 process plus iid Gaussian residual noise, one shared
phi and process SD across independent series. Integer gaps preserve elapsed steps.
At phi=0 only total variance is identifiable; even-only gaps cannot identify phi's
sign. Proposed data rules and numerical identities make those limits explicit.
OU is a compatible future positive-persistence kernel, not implementation scope.

The Terra source scout identified historical generic `Q_phylo` plumbing as reusable
for fixed phi. The planner rejected freezing learned phi in a data matrix and
specified a dedicated dynamic TMB block without renaming existing provider fields.
There is no existing VarCorr method to promise. These are proposed design choices,
not a new durable owner decision or empirical method result.

## 4. Files Touched

Only this report and the three artifacts linked above, all within the granted lease.
Proposed future implementation files are enumerated in plan section 7 and were not
edited. Shared `check-log.md`, coordination boards, numbered design documents,
AGENTS, hub memory, Julia/bridge, interval, bootstrap, repeatability and release
paths were left to their owners. This report serves as the scoped planning check
record; a shared check-log entry is owed to the approved execution lane after leasing.

## 5. Checks Run

Read repo/hub AGENTS, memory index, D-251 model routing, LOAD-FIRST manifest,
coordination-board and active-lane-split, plus current foreign branch notices.
Ran lane preflight first: FOREIGN LANE ACTIVE, including two other Codex lanes;
154 worktrees counted later. Local HEAD and local origin/main both began at
`1ae582c9fc9060071bb147ea4aa7206744392419`. SSH remote verified; no fetch/push.
Lease `codex:temporal-ar1-plan-f6e8` granted for this report and this plan directory.
The lease note is the concise coordination notice; no shared board edit needed.

Source recon used one bounded Terra medium explorer while the planner derived the
model and tests. Reused that reviewer for a bounded final plan review. No package
or statistical runs were delegated.
The six actionable review corrections were incorporated: newdata refusal, all-path
TMB defaults, dedicated-block exclusivity, frozen output names, retained independent
optimisation attempts, and method/guard ownership. This is plan review, not an
empirical correctness certificate.

Pre-handover command:
`env NO_PR=1 bash ~/shinichi-brain/tools/handoff_gate.sh /Users/z3437171/.codex/worktrees/f6e8/drmTMB`
exited 1: 494 unpushed commits on other branches. Those are protected foreign state,
not work to land here. The handover declares this and the local-only planning branch.
The gate did not authorize a push; none was attempted.

Artifact validation commands and final outcomes are recorded in handover section
“Verification”. JSON and report checks establish document integrity only; all
16 execution gates remain NOT_RUN. The after-task validator does not execute this
JSON ledger: it is an explicit future acceptance contract, not a falsely green
package-verification ledger.

## 6. Tests of the Tests

No package tests were written or run. The plan requires an independent dense-MVN
oracle and deliberate mutations for compressed gaps, shared series starts, missing
normalizers and swapped innovation/process SD. Artifact validation also checks that
all execution gate states remain NOT_RUN and IDs are unique.

## 7a. Issue Ledger

No GitHub issue access or mutation: the task forbids GitHub API/login and external
messages. The foreign repeatability notice references #1301; it remains protected.
Execution must reconcile any relevant issue using its separately authorised route.

## 8. Consistency Audit

Source search: `rg -n 'temporal|autocorr|AR1' R src tests/testthat docs/design`.
Provider search: `rg -n 'relmat|kernel|ordinary|structure = "none"' R/formula-markers.R R/parse-formula.R`.
History search: `git log --all --oneline --regexp-ignore-case --grep='temporal\|autocorr\|AR1'`.
The plan distinguishes absence of a temporal marker at the inspected base from
unverified foreign work. Ordinary, phylogenetic, spatial and relmat behavior stays
unchanged. Source, generated docs, README, NEWS, pkgdown and capability inventory
were not updated because there is no implementation claim to synchronize.

## 9. What Did Not Go Smoothly

Some expected hub paths were at `memory/MODEL-ROUTING.md`, not hub root, and the
report/pattern validators live in the hub rather than repo `tools/`. Both were
located before closeout. Large initial reads truncated output; relevant sections
were reread selectively. The coordination boards lag the live census, and preflight
reports duplicate numbered ledger IDs. This lane used a uniquely named directory
and narrow lease instead of allocating another shared number or repairing foreign
coordination history. The app stayed in Default mode; explicit task scope kept all
package work read-only and authorised only planning artifacts.
Two follow-up patch attempts failed on an unmatched context line and made no edits;
the corrected patch then applied and document checks passed.

## 10. Known Residuals

User approval is pending. Proposed shared-file edits cannot be claimed until fresh
execution preflight and owner coordination; guard support can require the protected
profile/method paths. Implementation estimates are unmeasured planning hypotheses.
No model likelihood, fitting, recovery, inference or cross-platform claim is proven.
No external publication or pushing authority exists. All unpushed foreign branches
remain untouched; this planning branch remains local by instruction.

## 11. Team Learning

A known precision matrix provider and a learned temporal kernel share mathematical
structure but differ at the AD boundary: learned phi must participate in the native
objective and its gradients. Preserve that distinction when reusing plumbing.
The paired process/residual SD interpretation must also appear in extraction and
simulation. These are planning lessons filed here, not new evidence-backed memory
claims or edits to another lane's process files.

## 12. Cross-Product Coverage

This task covers the **plan** for native Gaussian ML, one mean-side AR1 provider,
time validation, dense identities, bounded recovery, supported output/guard scope,
documentation and handover. It does NOT cover an implemented provider, OU fitting,
non-Gaussian/bivariate models, mixed structures, phi or process-SD regression, REML,
interval calibration, bootstrap, repeatability, forecasting, Julia parity, any
recovery campaign, CRAN readiness, site deployment or a public support claim.

## Next Actions

Approve or revise the plan, then open a fresh Terra medium/high task using the
handover prompt. This Astra planning task stops after its local commit.
