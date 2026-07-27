# Arc D Design 2 — traceable `sd()` clamp-limited profile contract

**Status:** PLAN ONLY — execution requires Shinichi's explicit approval.
**Date:** 2026-07-26. **Platform:** Codex. **Lane:** B — `sd()` scale and
intervals. **Foreign lane:** association PR #854; do not touch it.

```text
🎯 GOAL
On a fresh Lane-B branch, build a traceable and fail-closed contract for a
tight clamp on regression-predicted random-effect SDs: clamp activation at the
unconstrained fitted optimum or in any accepted profile evaluation makes that
target's public profile interval
unavailable (`clamp_limited`), with no finite endpoints. The headline is not
the clamp itself: it is complete observability across the whole profile path,
so a clamp-shaped likelihood-ratio root cannot be reported as inference.
Run the observability and consumer-map work in parallel; defer the clamp,
status implementation, ledger, bootstrap, association, missing-response,
public capability claims, and all compute until explicit approval. Verify every
profile evaluation, preserve K=12 as incomplete/non-covering, and close only
after Fisher and Rose review.
```

## What the brain and repository already know

Reusing the residual `logsigma_clamp` at the direct-`sd()` sites was falsified:
the K=12 dense meta-V negative control changed from `profile_failed` to a
finite, vacuous interval. Design 1, now in draft PR #856, is intentionally
only an overflow guard and does not alter this contract. Design 3 remains
rejected because fitting and profiling different objectives would make an
interval no longer describe the reported fit.

The current Design-2 target is therefore **not** a claim of non-identification
and not a stability claim. `clamp_limited` means: *an unrestricted
likelihood-ratio endpoint was not established because at least one accepted
profile evaluation used a clamp-modified objective.*

## Prior-work sweep receipt

| Surface | Evidence run | Finding | Call forced |
| --- | --- | --- | --- |
| Repository state | `git status -sb`; `git log --oneline -20`; `git worktree list`; `git branch -a --no-merged origin/main`; `branch_drift_check.sh` | Fresh plan branch at `e6bbad9b` (`origin/main`, 0 ahead / 0 behind). #856 is the narrow Design-1 draft PR; #854 is the active association lane. An earlier plan-only branch, `codex/arc-d-inference-contract-plan`, already contains the pre-D1 comparison. | Build a fresh Design-2 plan branch; do not revise association or stack implementation on #856. |
| Existing design work | `docs/design/245-f5-sd-regression-clamp-and-identifiability.md`; `docs/design/247-arc-d-clamp-profile-contract-d1.md`; prior plan/handover on `codex/arc-d-inference-contract-plan` | K=12 falsifies unlabelled tight clamping; D0 identified missing model-type reports and no `linear_predictor` boundary check. | Reuse the decision evidence, but replace the generic implementation step with a traceability gate. |
| Runtime consumers | `rg` over `R/profile.R`, `R/methods.R`, plotters, `inst/sim/run/sim_run_meta_v_lss_smoke.R`, and the K=12 tests | `interval_status_levels()` drives plot availability; meta-V only treats finite `interval_status == "ok"` as complete. | Propagate any new status as unavailable/incomplete before enabling the clamp. |
| Sister repos | `rg -n 'clamp_limited' gllvmTMB DRM.jl` | No reusable exact `clamp_limited` contract was found. | Build the drmTMB-specific contract; no cross-repo change. |
| Brain | `search_notes("drmTMB Arc D Design 2 clamp_limited interval_status sd regression profile endpoints", search_all_projects=TRUE)` | Retrieved older profile-status context but no newer override of the repository's D0/D1 decision record. | Repository docs and current source remain the technical basis. |
| Verdict | All surfaces above | The genuine gap is trace-capable clamp observability for the full SD-regression profile path, plus fail-closed status propagation. | Plan that gap only; do not begin a coverage campaign. |

No external literature search is proposed: this is an internal numerical/API
contract with no priority or methodological-novelty claim. A literature search
becomes mandatory before any later public methodological claim.

## Contract to approve before execution

For a group-level predicted log-SD
\(\eta_g = X_g\beta_{sd}\) (including any documented phylogenetic offset),
define `clamp_active` exactly when at least one evaluated \(\eta_g\) is outside
the clamp identity interval \([l,u]\). “Near the clamp” is not a valid rule.

For the initial implementation, if `clamp_active` occurs at the
**unconstrained fitted optimum** or in **any profile objective evaluation** on
either LR branch, return exactly. This is deliberately conservative: TMB 1.9.21
does not expose accepted inner-optimizer parameter vectors. It may withhold an
interval after a transient trial evaluation, but it cannot certify a
clamp-shaped endpoint.

| Field | Required value |
| --- | --- |
| `conf.status` | `"clamp_limited"` |
| `profile.boundary` | `TRUE` |
| `profile.message` | `"clamp_limited"` |
| `lower`, `upper` | `NA_real_`, `NA_real_` |
| propagated interval source | `"not_available"` |
| simulation interval status | `"incomplete"`, never `"ok"` |

The raw, bound-shaped root may exist only in a private trace for diagnostics;
it must never enter an ordinary interval table, plot, reducer, coverage result,
or capability claim.

## Why this is blocked today

The affected `sd() ~ x` target is a fixed-effect `linear_predictor`. It uses
the full `TMB::tmbprofile()` route rather than the direct scalar endpoint
engine. Current profile output does not retain the constrained full parameter
vectors, so an endpoint-only test cannot establish whether an intervening
evaluation activated the clamp. A Design-2 implementation must therefore do
one of two things before enabling the clamp:

1. implement a trace-capable evaluator that records clamp activation for every
   objective evaluation, plus the fitted optimum baseline; or
2. refuse the uninstrumented SD-regression profile route fail-closed.

Without one of these, Design 2 must not be implemented.

## Execution plan — only after approval

| Phase | Owner / route | Output | Dependencies and acceptance gate |
| --- | --- | --- | --- |
| 1. Observability map | Terra-high, native explicit — Gauss | Equation-to-source map for all nine C++ sites, two R re-derivations, and model types 1, 10, 6, 7, 2, 19, 20 | Name the precise `eta_g`, identity interval, and how Poisson/NB2 obtain equivalent observation. No clamp enabled. |
| 2. Profile trace design | Sol-high, native explicit — Fisher/Noether | Design note specifying the fitted-optimum baseline plus objective-evaluation trace and its lifetime | Must cover the full `tmbprofile` route and both LR sides. Failure to trace means explicit fail-closed refusal, not endpoint-only inference. |
| 3. Consumer contract | Terra-high, native explicit — Rose | Table mapping `clamp_limited` through `confint()`, summary, prediction tables, parameter/corpair plots, and meta-V reducers | Every reader either renders no interval or marks it unavailable. The ledger is read-only. |
| 4. Observability PR | Terra-high, native explicit — TMB engineer | Internal reports/reconstruction and trace tests, without a tight clamp | All 11 surfaces agree; trace contains every accepted profile evaluation; standard interior paths unchanged. |
| 5. Atomic clamp/status PR | Terra-high, native explicit — TMB engineer | Tight clamp plus the approved public four-field contract | Cannot merge unless phases 1–4 pass. No bootstrap, association, missing-response, ledger, or public capability wording. |
| 6. Independent verification | Sol-high, native explicit — Fisher; Terra-high — Rose | Contract and scope verdicts | The `tmbprofile` SD-regression route, all readers, and the K=12 negative control pass. Existing direct-SD endpoint-engine behavior is regression-tested separately, not widened to `linear_predictor` targets. |
| 7. Closeout | Terra-medium, native explicit — Rose | After-task report and handover | No compute and no campaign authorization. A later interval-grade study is a separate owner decision. |

Estimated implementation after approval: 2–4 focused working days, two PRs,
and no compute. This plan fits one implementation session only if the trace
design is straightforward; otherwise stop after Phase 2 with a new decision
memo.

## Pre-registered verification gates

1. **Activation boundary:** pure tests at `l`, `u`, and immediately outside,
   defined on raw \(\eta_g\), not on transformed SDs.
2. **K=12 clamp-binding control:** `clamp_limited`, missing public endpoints,
   retained attempt, `interval_status = "incomplete"`, zero complete or
   covering count. Its diagnostic message may change from
   `nonfinite_interval` only by an explicit test update.
3. **Interior control:** the `mc-0017`-shaped profile is strictly in the
   identity region; enabled versus disabled clamp has identical profile
   status and endpoints within numerical tolerance.
4. **Eleven-surface coherence:** C++/R agreement across all direct-SD routes,
   including missing Poisson/NB2 observability.
5. **Trace completeness:** `tmbprofile` records both profile sides and every
   objective evaluation, plus the fitted optimum; uninstrumented
   paths fail closed. The endpoint engine remains unsupported and unchanged for
   `linear_predictor` targets, and cannot emit a finite ordinary interval for
   this Design-2 target.
6. **Reader containment:** summary and prediction outputs propagate
   `not_available`; parameter and corpair plots draw no interval band.
7. **Reducer containment:** meta-V retains the attempt but records it as
   incomplete and non-covering; no capability-ledger or generated-surface edit.
8. **Regression boundary:** Design 1's overflow sentinel and all current
   non-clamp profile behavior remain unchanged.

## Team raised

- **Fisher:** endpoint-only detection is insufficient because an intervening
  profile evaluation can alter the LR root. Require a full trace or refuse the
  route; define `clamp_limited` as unavailable inference, not proof of
  non-identification.
- **Rose:** this is a public status-vocabulary change, not a local diagnostic.
  New statuses must be registered in plot/table readers and kept incomplete in
  meta-V; split observability from clamp activation into two reviewable PRs.
- **Ada:** approve only the stated four-field, no-endpoint contract and the
  trace-first architecture. Do not let a finite diagnostic root leak to users.

## Decisions locked and fences

- Design 1 is separate and remains limited to overflow safety (#856).
- Design 3 remains rejected for objective mismatch.
- Design 2 does not authorize a ledger transition, bootstrap or coverage work,
  the 177-cell campaign, association work, missing-response work, public
  capability/default claims, or any compute.
- Design 2 cannot use a soft “near bound” heuristic, and cannot pass a finite
  clamp-shaped endpoint through `confint()`.

## Approval requested

Approve this Design-2 plan only if you accept the public
`conf.status = "clamp_limited"` vocabulary with missing endpoints and the
trace-first / fail-closed prerequisite. Approval authorizes Phases 1–3 and the
two implementation PRs above; it does **not** authorize compute, the
interval-grade campaign, a ledger change, or a public capability claim.
