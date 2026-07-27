# Session Handoff: Lane B E0 closeout → E1 exact-binding plan

Meta: 2026-07-27 · from Codex · to Codex · source branch
`codex/lane-b-e0-readiness` at `f718b8d74` before this handover commit.

## Critical Context

You are Codex, picking up **Lane B only**: `sd()` scale and interval work.
Do not touch Lane A association (`rho12`, staged eta, #844/#846), bootstrap,
missing response, the capability ledger, or public/default behavior. E0 is
closed as **local, fail-closed readiness**, not as an interval campaign and not
as compute authorization. Never treat a finite interval shaped by a clamp as
identification evidence.

## Goals / Mission

The immediate mission is to design the next Lane-B arc, E1: recover the
remaining exact cell × target × DGP/profile contracts needed for a future
pregrid, without launching remote compute. The broader mission remains an
honest profile-interval campaign: all-attempt denominators, target-specific
claims, and K=12 retained as negative evidence.

## Plans / Roadmap

Start E1 with `arc-creation`, then `$ultra-plan`; research and planning only
until Shinichi explicitly approves execution. The likely E1 work is a bounded
binding-recovery program, prioritized by exact existing fixtures/evidence,
followed by local technical-smoke design. Do not propose DRAC/Totoro until a
later reviewed packet has complete bindings and a separately approved
150-attempt pregrid request.

## What Was Accomplished

- Verified Arc D prerequisites: #856 (Design 1 overflow guard) and #857
  (Design 2 trace-first `clamp_limited`) are merged with green Ubuntu release
  checks; see `docs/dev-log/2026-07-27-lane-b-e0-prerequisite-receipt.md`.
- Built E0 campaign plumbing: an immutable 159-row model-surface manifest
  (158 frozen original rows plus approved `mc-0260m`), target strata, binding
  worklist/inventory, deterministic schedule gate, all-attempt reducer, packet
  writer, smoke receipt validation, and a local verifier.
- Recovered 62 exact target bindings; retained two `mc-0260m` K=12 target rows;
  97 cells remain unbound. Six local smoke receipts retain both finite and
  failed outcomes. Every one of the 21 exact-estimand strata remains
  `pregrid_eligible = FALSE`.
- Hardened provenance: a successful smoke receipt must exactly match a reviewed
  cell × target × DGP binding; bindings require a non-empty source; the packet
  writer validates raw partial bindings; status vocabulary/reasons/trace
  completeness are checked.
- Fisher and Rose review both passed after fixes. The complete closeout is
  `docs/dev-log/after-task/2026-07-27-lane-b-e0-readiness.md`.

## Current Working State

- Working: branch is clean and pushed. E0 does not run compute and the verifier
  reports `pregrid_authorized=FALSE`.
- In progress: no E1 implementation has started.
- Blocked: remote pregrid/array is intentionally blocked by incomplete exact
  bindings and requires Shinichi's explicit approval even after E1 planning.

## Key Decisions & Rationale

- The cohort is frozen by both cardinality and ID hash. Do not admit rows from
  B1 merely because their source fixture is convenient; `mc-0031` and
  `mc-0074` are outside the E0 cohort.
- K=12 is only `mc-0260m` meta-V; it is not a structured `q12` block. A finite
  K=12 profile is a fail-closed error, never a success.
- `clamp_limited`, `trace_incomplete`, nonfinite profiles, failed fits, and
  missing attempts are unavailable/non-covering in the scheduled denominator.
- E0 makes no coverage, capability, or public inference claim. It does NOT
  authorize DRAC/Totoro, GitHub Actions campaign compute, a ledger change, or a
  public/default change.

## Landing State

`/Users/z3437171/shinichi-brain/tools/handoff_gate.sh /private/tmp/drmtmb-e0-readiness`
reported the E0 branch itself clean and pushed, but nonzero because four
**foreign protected branches** have unpushed work. Do not repair, rebase, or
stage them from Lane B.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/lane-b-e0-readiness` E0 | yes | yes | none yet | LANDED on branch; handover travels with branch |
| `claude/arc-a-external-comparator-evidence` | foreign | no | unknown | PROTECTED — 12 unpushed |
| `codex/arc6-6-bernoulli-nb2-plan` | foreign | no | unknown | PROTECTED — 2 unpushed |
| `codex/sd-bootstrap-r999-diagnosis` | foreign | no | unknown | PROTECTED — 11 unpushed |
| `codex/staged-eta-godambe-se` | foreign | no | unknown | PROTECTED — 3 unpushed |

## Files Created / Modified

E0 branch diff against `origin/main`:

- `inst/sim/R/sim_interval_campaign_readiness.R`
- `tests/testthat/test-interval-campaign-readiness.R`
- `tools/verify-lane-b-e0-readiness.R`
- `docs/dev-log/interval-campaign-bindings/2026-07-27-b1-recovered-subset.tsv`
- `docs/dev-log/interval-campaign-bindings/2026-07-27-b1-local-smoke-receipts.tsv`
- `docs/dev-log/2026-07-27-lane-b-e0-binding-recovery.md`
- `docs/dev-log/2026-07-27-lane-b-e0-readiness-receipt.md`
- `docs/dev-log/2026-07-27-lane-b-e0-prerequisite-receipt.md`
- `docs/dev-log/after-task/2026-07-27-lane-b-e0-readiness.md`
- `AGENTS.md` and this handover document (this commit only).

## Next Immediate Steps

1. Run `tools/lane_preflight.sh` and inspect `git status`, `origin/main`, and
   open PRs before claiming E1.
2. Read `AGENTS.md`, this handover, the E0 after-task report, E0 readiness
   receipt, binding recovery narrative, and the Arc D Design 2 plan.
3. Use `arc-creation`, then `$ultra-plan`, to produce an E1 exact-binding
   recovery design. Consult Fisher and Rose during planning.
4. Stop for explicit approval before implementing E1 or running any
   Totoro/DRAC work.

## Blockers / Open Questions

- Which binding strata provide enough existing exact evidence to form a
  compact E1 tranche, rather than reopening all 97 cells at once?
- The 97 unresolved cells need an exact source/DGP/target review. This is a
  recovery/planning gap, not evidence of profile failure.
- No remote-compute authorization exists.

## Gotchas / Failed Approaches

- Do not use a B1 roster as the E0 cohort; it admitted out-of-cohort IDs.
- Do not infer a structured target from provider/q labels; one route may have
  intercept and slope targets. Bind each target independently.
- Do not replace failed direct profiles with Wald results or use a numerical
  clamp to obtain finite endpoints.
- The initial receipt validator accepted invented target/DGP strings, and the
  packet writer bypassed blank provenance. Both are regression-tested now;
  preserve those tests.

## How to Resume

From `/private/tmp/drmtmb-e0-readiness`, start a fresh Codex task and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-27-codex-lane-b-e1-handover.md
and the AGENTS.md Active Lane Split. You are Lane B only. Run lane preflight,
then use arc-creation followed by $ultra-plan to research and plan E1 exact
binding recovery. Do not implement E1, launch compute, modify association,
bootstrap, missing-response, ledger, public/default behavior, or make a
pregrid request without Shinichi's explicit approval.
```

For live local checks, Codex owns the R/TMB toolchain:

```sh
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
Rscript tools/verify-lane-b-e0-readiness.R
Rscript -e 'devtools::test(filter = "(interval-campaign-readiness|arc-d-profile-trace|arc-d-sd-overflow-guard)", reporter = "summary")'
```

## Mission Control

| Lane / item | Branch / main state | What shipped | Next leverage step |
| --- | --- | --- | --- |
| Lane B E0 readiness | `codex/lane-b-e0-readiness`; pushed | fail-closed no-compute campaign packet; no public claim | fresh E1 arc creation + ultra-plan |
| Lane A association | independent | protected | do not touch from E1 |
| Remote compute | not authorized | none | only after later E1 plan and explicit approval |
