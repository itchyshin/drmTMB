> [!goal] 🎯 GOAL
> **PLATFORM: Codex.** Deliver Arc 4c as a two-PR, evidence-first certification campaign for the three remaining ordinary `mu` random-slope cells: skew-normal `mc-0464`, Tweedie `mc-0539`, and zero-one Beta `mc-0575`. **HEADLINE:** determine independently whether standard ML-Laplace profile intervals support `inference_ready_with_caveats`, defining where the package's ordinary engine suffices versus where a later AGHQ/Cox-Reid arc is needed. **IN PARALLEL:** Curie owns the runner/aggregation contract while Grace owns the Fir dispatch/provenance package; after results, Fisher, Rose, and Noether run fresh memo-blind D-43 reviews. **DEFER:** O3/REML expansion, `supported`, new DGPs/families/structures, capability-surface estimator redesign, DRM.jl, CRAN. **DISCIPLINE:** preserve the dirty root; start from fresh `origin/main`; keep estimator `ML`; never run the campaign on GitHub Actions; merge and verify PR A; stop for explicit compute approval; smoke first on Fir; retain all attempts; promote cells independently; close PR B with verification, reconciliation, after-task, and handoff.

# Arc 4c ultra-plan: three-family `mu` random-slope coverage

## Outcome and authority

This arc adds no public API or model grammar. It tests the existing `mu` independent-random-slope profile interval for `mc-0464`, `mc-0539`, and `mc-0575`, all currently `point_fit_recovery` with `estimator=ML`. Each cell can promote independently or retain its tier with negative evidence. The frozen estimand, DGPs, gate, smoke-selection rule, array bijection, and claim boundary are in `docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md`.

The repo and live GitHub state are technical truth. The controlling brain decisions are D-50 (Totoro/DRAC, never Actions campaign artifacts), D-62 (tier-consistent coverage and Fir thread pins), D-43 (fresh completion adversary), D-63 (model-routing receipt), and D-64 (reuse a live DRAC ControlMaster socket).

## Dependency slices

| Slice | Owner and route | Deliverable | Dependency |
| --- | --- | --- | --- |
| S0 recon | Ebbinghaus; Luna-low, tiered CLI | live SHA, ledger, worktree, and stale-artifact receipt | none |
| S1 freeze | Ada; Sol-high parent | fresh infra worktree, S0, plan-review receipt | S0 |
| S2 runner | Curie; Terra-high explicit | sourceable contract, runner, aggregator, pure-logic tests | S1 |
| S3 Fir package | Grace; Terra-high explicit | smoke/array/aggregate Slurm pack, manifest and provenance guards | S1; parallel with S2 |
| S4 verify | mechanical Luna-low then Ada integration | focused/full checks and routing receipt | S2-S3 |
| S5 PR A | Ada and Rose | check log, after-task, handoff, green PR, verified merge SHA | S4 |
| Gate A | Shinichi | explicit approval for frozen smoke plus mechanically selected array | merged S5 |
| S6-S8 compute | Ada, Grace, Curie | fresh-clone build, smoke, array, aggregation, shared-seed replay | Gate A |
| S9 D-43 | fresh Fisher, Rose, Noether | per-cell PROMOTE/WITHHOLD verdicts | S8 |
| S10-S13 close | Terra ledger writer, Luna verifier, Melissa, Rose | PR B evidence, ledger, surfaces, reconciliation, after-task, handoff | S9 |

S2 and S3 own disjoint files and run in parallel. D-43 reviewers run in parallel from fresh contexts. Ledger and generated surfaces have one serial writer. Every delegated slice records model, effort, artifact, and any escalation.

## Two-PR delivery

### PR A — auditable infrastructure

Branch from fetched `origin/main` in a new worktree. Explicitly recreate only the reviewed S0; never broadly copy, stage, clean, or cherry-pick the dirty root. Land the sourceable pure-logic contract, exact three-DGP runner, all-attempt aggregation, deterministic smoke/array manifests, atomic shard/checksum/resume guards, Fir Slurm scripts, contract tests, review receipt, check log, after-task report, and handoff. Ordinary package checks are allowed; no Arc 4c model fit is allowed. Merge through maintainer review, verify `origin/main` at the merge SHA, then stop at Gate A.

### PR B — evidence and independent verdicts

Only after Gate A: run the exact 12-cell N=1 smoke from a fresh `/project` clone at the PR-A merge SHA, apply the frozen M-specific selection rule, and submit at most 1,440 one-CPU ten-seed shards. Aggregate only complete schema/hash-valid shards; verify expected denominators and shared-seed replay. Run fresh memo-blind Fisher/Rose/Noether D-43 reviews. A single writer keeps `estimator=ML`, promotes only passing cells, decrements the current `point_fit_recovery` expectation once per promotion, regenerates every derived surface, and records negative evidence for every withheld cell. Close with checks, pkgdown, reconciliation, after-task, handoff, green CI, and synchronized `origin/main`.

## Approval and defers

Implementation authorization covers PR A only. It does not authorize a DRAC allocation, package compilation on a compute node, an Arc 4c smoke/model fit, the full array, ledger mutation, or a promotion. Those begin only after Shinichi approves Gate A against the verified PR-A merge SHA. A failed family does not trigger O3 inside this arc; its estimator-depth diagnosis becomes a separately approved successor.
