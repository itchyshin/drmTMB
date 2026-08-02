# Session Handoff: Arc 6 association — F3R complete, F3 approval-gated

Meta: 2026-07-26 · from Codex · to Codex · fresh-task boundary before a real refit

## Critical Context

The fixed-effect, complete-pair Bernoulli × ordinary-NB2 `association = ~1`
route has passed its private deterministic F1 gate and now has a committed F3R
runner at `66752968a719d5a178bb4095b194e7ccb45f767e`.  It is not yet authorised
to execute: a fresh written owner approval must name that exact SHA and permit
one, local, immutable `attempt-001` provenance smoke.  F3 is provenance only;
it cannot establish a valid SE, interval, recovery, coverage, calibration, or
public-ready claim.

The branch tip also contains this later handover commit. The runner's strict
`HEAD == --expected-sha` guard is intentional: if F3 is approved, create a
**clean detached worktree at `66752968`** for the one invocation. Do not run
the runner from the later handover branch tip.

This is the **association lane only**.  Claude owns Arc D/F5.  Keep direct
`biv_lognormal()` `rho12` inference separate.  Do not expose the private
sandwich through `vcov()`, `confint()`, profile methods, public documentation,
or the capability ledger.

## Goals / Mission

The immediate goal is to make one full two-stage refit auditable before asking
for F4 calibration authority.  The larger Arc 6 goal remains pair-specific
public-inference evidence for this exact route only; it cannot legitimately be
closed by a twelve-hour session because F4 remote calibration and a later F5
public-product decision have independent approvals.

## Plans / Roadmap

The next proposed capacity programme is a 12-hour **F3→F4 bridge**, not a
claim that all Arc 6 is complete:

| Order | Budget | Outcome | Gate |
| --- | ---: | --- | --- |
| Arc 0 | 2 h | One F3 provenance smoke and receipt audit | Fresh written F3 approval first |
| Rung 1 | 1.5 h | Narrow D-43 provenance panel and F3 disposition | Only after F3 |
| Rung 2 | 2.5 h | F4 preregistration: grid, interval target, denominators, MCSE, stop rules | Only after F3 proves provenance |
| Rung 3 | 2.5 h | Developer-only F4 harness/contract design and pure tests | No simulation or remote launch |
| Rung 4 | 2 h | Totoro-versus-DRAC runbook and launch checklist | No connection or compute |
| Close | 1.5 h | F4 approval packet and closeout | Always |

If F3 fails or is unavailable, stop technical progression.  Retain its negative
receipt and plan the smallest repair; do not retry, tune, or proceed to F4.

## What Was Accomplished

- Repaired the Bernoulli × ordinary-NB2 tail-orientation gap and completed the
  F1 deterministic matrix, including the independent analytic derivative
  oracle, tail/zero/swap/boundary cases, and fail-closed taxonomy.
- Corrected F1M provenance to the passing validation commit
  `e0af91fc610a751880dba22a1b342cfb50cb757b` and recorded source blobs.
- Committed F3R at `66752968`: a dedicated developer-only runner, one-attempt
  artifact/status contract, F3 approval packet, receipts, and 47 pure runner
  expectations.
- Verified the final state with 47 F3R runner expectations, 308 focused
  B×NB2/staged-sandwich expectations, `git diff --check`, and the after-task
  structure checker. Fisher and Rose approved the private F3R contract for
  commit; neither approval authorises F3 execution.

## Current Working State

- **Working:** clean handover branch `codex/arc6-association-public-prep-f0f2`
  at its current later handover commit; the frozen F3 execution source is the
  reachable ancestor `66752968a719d5a178bb4095b194e7ccb45f767e`.
- **In progress:** none. F3R is complete; the next action requires owner input.
- **Blocked / gated:** F3 execution awaits the exact approval below. F4 awaits
  both a provenance-correct F3 receipt and its own pre-registered compute
  approval. F5 awaits completed F4 evidence and a separate public decision.

## Key Decisions & Rationale

- Primary private estimand remains staged `alpha`; derived
  `eta = 0.999999 * tanh(alpha)` is separate. Joint-MLE `rho12`, conditional
  stage-two curvature, and observed correlation are excluded.
- F3 runs one full-refit dataset, one attempt, no retry. Its all-attempt stages
  are `dgp_harness → bernoulli_margin → nb2_mean → nb2_dispersion → association
  → rectangle → sandwich → delta → interval`; interval is always
  `not_attempted`.
- F4—not F3—must compare full two-stage uncertainty to outer-simulation
  empirical SD and select an interval procedure. Totoro or DRAC, never GitHub
  Actions, is the first compute decision.
- The previous broad 24 × 200 × 399 staged-bootstrap shards stay stopped and
  must not be aggregated or resumed.

## Landing State

Run `tools/handoff_gate.sh` again before treating this as a remotely durable
handoff. At authoring time it reported this branch had unpushed commits; do not
assume a new checkout sees them until push state is verified.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/arc6-association-public-prep-f0f2` handover branch | yes | verify | none | CARRIED-OVER — current association work; push before relying on a fresh remote checkout. |
| detached F3 execution worktree at `66752968` | source committed | n/a | none | FUTURE/APPROVAL-GATED — create only after the owner approves one F3 attempt. |
| Claude Arc D/F5 | foreign | n/a | PR #851 is foreign | PROTECTED — do not modify, merge, or restage. |
| Legacy `codex/arc6-6-bernoulli-nb2-plan` | yes | no | none | PROTECTED — unrelated old unpushed branch; never clean or reuse. |

## Files Created / Modified

- `R/associate-pairs-sandwich.R` — private deterministic/sandwich support from
  the F1 sequence; F1M blob pinned below.
- `tests/testthat/test-associate-pairs-staged-sandwich.R` — private F1
  deterministic matrix and derivative oracle.
- `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R` — F3 runner; do not
  invoke without approval.
- `tests/testthat/test-arc6-f3-provenance-smoke-runner.R` — pure runner contract tests.
- `docs/dev-log/2026-07-26-arc6-association-f0-f2-preparation-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f1m-deterministic-qualification-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- `docs/dev-log/2026-07-26-arc6-f3r-preflight-receipt.md`
- `docs/dev-log/after-task/2026-07-26-arc6-f3r-provenance-runner.md`
- `docs/dev-log/plan-actual/2026-07-26-arc6-f3r-provenance-runner.md`
- `AGENTS.md` — association-lane snapshot pointer.
- `docs/dev-log/handover/2026-07-26-codex-association-f3r-handover.md` — this handover.

## Next Immediate Steps

1. Run `tools/lane_preflight.sh . --hours 36`, inspect `git status --short
   --branch`, and classify this handover against current state.
2. Verify the handover branch is clean and `66752968a719d5a178bb4095b194e7ccb45f767e`
   is a reachable ancestor. If the branch was unpushed, push it before relying
   on a fresh checkout.
3. Stop unless the owner supplies this exact approval:

   > I approve exactly one local Arc 6 F3 Bernoulli × ordinary-NB2 provenance
   > smoke at source SHA `66752968a719d5a178bb4095b194e7ccb45f767e`, using
   > `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R` and its immutable
   > output directory. This approves no retry, F4, public inference, or API
   > exposure.

4. If approved, create a clean detached worktree at `66752968`, verify that
   worktree's `HEAD` and cleanliness, then run the frozen CLI from
   `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md` exactly once there.
   Inspect only the immutable receipt, rerun the focused tests, then convene
   the narrow D-43 panel for the claim “one full-refit provenance smoke
   completed.”
5. If F3 succeeds, prepare—but do not run—the F4 approval packet. If it fails,
   write a negative receipt and stop for a new repair decision.

## Blockers / Open Questions

- The owner has not yet supplied the F3 execution approval.
- No F4 grid, outer/inner counts, interval procedure, or Totoro/DRAC runbook
  has been approved.
- `handoff_gate.sh` reported unpushed local work at authoring time; verify and
  push before starting a new remote/worktree session.

## Gotchas & Failed Approaches

- Do not run the legacy `tools/run-arc6-association-smokes.R`; it covers old
  Arc 6.1/6.2 smokes and is not the B×NB2 provenance runner.
- Do not treat an `eta_delta_unstable` case as alpha availability: the private
  helper does not retain a partial alpha object, so both availability flags are
  false.
- Do not replace unavailable output with a retry, changed seed, different start,
  tolerance change, or a conditional association-only refit.
- Do not use direct `biv_lognormal()` `rho12` coverage as staged-alpha evidence.

## How to Resume

You are Codex. From the repository root, use the live R/TMB toolchain:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "associate-pairs-(staged-sandwich|bernoulli-nb2)")'
```

Then read `AGENTS.md`, this handover, the F3 packet, and the F3R after-task
report. `.codex/agents/` supplies the review roster; Rose is mandatory before
any claim beyond the private deterministic/preparation boundary. Codex may run
the approved live F3 refit and later approved Totoro/DRAC work; planning-only
or review work remains portable, but no session may silently widen the approval.

Paste into a fresh Codex task:

```text
Rehydrate from docs/dev-log/handover/2026-07-26-codex-association-f3r-handover.md
and the AGENTS.md association-lane snapshot. Run lane preflight and verify the
clean SHA. Do not execute F3 unless I provide the exact written approval in the
handover; then continue only the Next Immediate Steps.
```

## Mission Control

| Lane | State | Next leverage step |
| --- | --- | --- |
| Arc 6 B×NB2 association | F3R complete, F3 gated | Fresh owner F3 approval, then one smoke only |
| Arc 6 F4 calibration | Not started | F3 receipt, then separate pre-registration/compute approval |
| Arc 6 F5/public inference | Locked | Wait for F4 evidence and public-product decision |
| Arc D/F5 scale/interval | Foreign Claude lane | Leave untouched |
| Direct `biv_lognormal()` `rho12` | Separate completed route | Do not transfer its evidence |
