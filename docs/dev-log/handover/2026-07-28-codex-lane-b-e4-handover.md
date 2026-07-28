# Lane B E4 handover — source recovery complete; interval-feasibility roadmap parked

Meta: 2026-07-28 · from Codex · to a fresh Codex task · PLATFORM: Codex · LANE: B — `sd()` scale and intervals

## Critical context

E3 and E4 completed only source-recovery documentation. They recovered **zero** new canonical bindings and grant **no execution authority**. E0 remains the controlling readiness state: 158 target cells, 62 recovered targets, two retained K=12 negative targets, 97 unresolved cells, and `pregrid_authorized = FALSE`.

The owner has chosen the broader product direction: the useful capability funnel is 364 in-scope cells (330 `rejected_by_design` cells excluded), with interval feasibility as the near-term target and inference readiness as the later target. This is a roadmap, not approval to implement, smoke, profile, schedule, pregrid, or compute from this Lane B handover. It spans more than Lane B; association and other bivariate work remain separate.

## What was accomplished

- E3 recorded primary-source receipts for the count-q1 tranche; the sources did not yield sufficient immutable direct-target contracts to promote a binding.
- E4 created a complete 76-row structured-source atlas: q1 (26), q2/q4 (26), and high-q (24). Every row remains `source_receipt_only_not_recovered`.
- The six control cells remain outside the atlas and `source_found_not_direct`: `mc-0113`, `mc-0114`, `mc-0214`, `mc-0215`, `mc-0321`, `mc-0409`.
- The E0 verifier passed: 158 / 62 / 2 / 97 and false pregrid.
- Outside this repo, local-only Shinichi Mission Control derives the real 364-cell funnel from `capability-ledger/cells.tsv`: 40 not implemented, 70 diagnostic only, 3 no evidence, 180 point-fit recovery, 44 interval feasible, 23 inference ready, and 4 supported. Those changes are local vault commits `6f320f0` and `6935eaa`.

## Current working state

- **Working:** this branch was clean before this handover commit; E3/E4 documentation artefacts are pushed.
- **In progress:** none in Lane B. E1's eight count-q1 source-contract candidates are pending an owner-approved exact-binding review; E2's 97 cells remain unresolved.
- **Blocked by design:** no canonical binding, profile/smoke, schedule, pregrid, DRAC/Totoro, association, bootstrap, missing response, ledger/capability, or public/default/API work.

## Key decisions and rationale

1. A source receipt is not a recovered binding. A candidate requires exact DGP/version, formula, truth/reporting scale, namespaced direct target, information rung, source receipt, and unambiguous target cardinality. Provider/q labels never select intercept versus slope.
2. K=12 remains retained negative evidence. `clamp_limited`, `trace_incomplete`, nonfinite, missing, and failed outcomes are unavailable/non-covering; a finite K=12 interval is an error, not success.
3. The numerical-clamp approach was falsified: a finite endpoint caused by a clamp is not identified inference. Design 2's trace semantics are `tmbprofile()` trace-only.
4. The broader 364-cell programme should be staged: implementation and diagnostic cells must first reach point-fit recovery; shared interval mechanisms then move recovery cells to interval feasible; separate coverage/calibration arcs may later promote suitable cells to inference ready. Do not execute this roadmap without a fresh, owner-approved multi-lane plan.

## Mission-control summary

| Surface | State | What is covered | Next by leverage |
| --- | --- | --- | --- |
| `drmTMB` Lane B | docs-only E3/E4 on `codex/lane-b-e1-exact-binding-recovery` | source provenance only; E0 unchanged at 158/62/2/97 | owner-approved exact-binding review or fresh interval-feasibility plan |
| Mission Control (local Shinichi vault) | local commits `6f320f0`, `6935eaa` | 364 in-scope funnel, derived live | use interval-feasible count as the near-term portfolio metric |
| Lane A association | protected foreign lane | no Lane-B changes | do not touch or merge from this lane |

## Files created or modified

Already committed on this branch:

- E3: `docs/dev-log/2026-07-27-lane-b-e3-primary-source-recovery.md`, `docs/dev-log/2026-07-27-lane-b-e3-validation-receipt.md`, `docs/dev-log/after-task/2026-07-27-lane-b-e3-primary-source-recovery.md`, `docs/dev-log/handover/2026-07-27-codex-lane-b-e3-handover.md`, `docs/dev-log/interval-campaign-bindings/2026-07-27-e3-primary-source-receipts.tsv`, and `docs/dev-log/plan-actual/2026-07-27-lane-b-e3.md`.
- E4: `docs/dev-log/2026-07-27-lane-b-e4-structured-source-atlas.md`, `docs/dev-log/2026-07-27-lane-b-e4-validation-receipt.md`, `docs/dev-log/after-task/2026-07-27-lane-b-e4-structured-source-atlas.md`, `docs/dev-log/handover/2026-07-27-codex-lane-b-e4-handover.md`, `docs/dev-log/interval-campaign-bindings/2026-07-27-e4-atlas-q1.tsv`, `docs/dev-log/interval-campaign-bindings/2026-07-27-e4-atlas-q2-q4.tsv`, `docs/dev-log/interval-campaign-bindings/2026-07-27-e4-atlas-highq.tsv`, `docs/dev-log/interval-campaign-bindings/2026-07-27-e4-structured-atlas-manifest.tsv`, and `docs/dev-log/plan-actual/2026-07-27-lane-b-e4.md`.
- This handover: `AGENTS.md` and `docs/dev-log/handover/2026-07-28-codex-lane-b-e4-handover.md`.

## Landing state

`tools/handoff_gate.sh .` was run before this handover. Its only failures are declared protected, unpushed work on other branches; do not repair, stage, merge, or rebase them here.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/lane-b-e1-exact-binding-recovery` (this handover) | yes | yes after this handover commit | none | LANDED |
| `claude/arc-a-external-comparator-evidence` (12 commits) | yes | no | foreign | CARRIED-OVER — protected; owner must resume |
| `codex/arc-d-design1-overflow-guard` (3 commits) | yes | no | foreign/protected | CARRIED-OVER — do not resume from Lane B |
| `codex/arc6-6-bernoulli-nb2-plan` (2 commits) | yes | no | foreign/protected | CARRIED-OVER — do not resume from Lane B |
| `codex/sd-bootstrap-r999-diagnosis` (11 commits) | yes | no | foreign/protected | CARRIED-OVER — owner decision required |
| `codex/staged-eta-godambe-se` (3 commits) | yes | no | foreign/protected | CARRIED-OVER — association lane only |
| Shinichi Mission Control `master` (`6f320f0`, `6935eaa`) | yes | local-only vault | no remote by design | LANDED locally (D-37) |

## Next immediate steps

1. Start fresh and read `AGENTS.md`, then this handover and the E4 atlas/validation receipt.
2. Run Lane B preflight and the E0 verifier before claiming work.
3. Ask the owner whether the next approved task is (a) a narrowly scoped exact-binding review for a cardinality-one source cluster, or (b) a fresh multi-lane interval-feasibility programme. Do not infer approval from the roadmap.
4. If (b) is approved, begin with the programme's foundation arc: map the 180 `point_fit_recovery` cells into shared interval mechanisms. Keep Lane B restricted to scale/`sd()` and structured interval cohorts; issue explicit handoffs for association and other bivariate cohorts.

## Blockers and open questions

- Which exact source cluster, if any, should receive the next binding review?
- How should ownership be split across the 12 interval-feasibility and 4–6 later inference-ready arcs? This is an owner decision, not Lane B's unilateral expansion.
- Any profile/smoke/pregrid/compute action still needs its own approval packet. Heavy coverage would run on Totoro or DRAC, never GitHub Actions, only after a green toy smoke.

## Gotchas and failed approaches

- Do not cite Design 246 for Design 2: #857 (`f6cc6fe5`) is the actual Design-2 source.
- Do not reinterpret a finite, clamp-shaped interval as inferential success.
- Do not co-opt DRM.jl as an exact drmTMB `cell × target × DGP` contract.
- Do not use 694 as the capability progress denominator: 330 cells are deliberately rejected by design. Mission Control's derived 364-cell funnel is the useful portfolio view.
- Do not use bare `tools/handoff_gate.sh drmTMB`; it can false-pass. Pass `.` or an absolute path.

## How to resume

From `/Users/z3437171/.codex/worktrees/fcc2/drmTMB`, start Codex and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-28-codex-lane-b-e4-handover.md and the AGENTS.md Active Lane Split. You are Lane B only. Run $HOME/shinichi-brain/tools/lane_preflight.sh . and Rscript tools/verify-lane-b-e0-readiness.R before claiming work. Do not execute profiles/smokes, binding edits, schedules, pregrid, compute, association, bootstrap, missing response, ledger/capability, or public/default/API work without Shinichi's explicit approval.
```

Codex owns the live R/TMB toolchain if a later approved task requires it: use the repository's normal R environment; set `NOT_CRAN=true` only for the source-suite gate when the approved plan specifies it, never to make a claim-bearing `R CMD check` green. Before any future heavy campaign, run a local toy smoke and obtain explicit approval for Totoro or DRAC.
