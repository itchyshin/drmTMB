# Session Handoff: Arc 1a closeout to Claude mirror

Meta: 2026-07-13 · from Codex to Claude · PR #780

You are Claude, picking up a completed, Rose-signed Arc 1a branch. Your narrow
next job is to mirror the tracked capability HTML into external artifact
`a1bf21a1` and verify exact read-back. Do not reopen implementation or merge the
pull request.

## Critical Context

Arc 1a is complete on `feature/arc1a-gaussian-reml-providers`; PR #780 is open,
ready, and mergeable but requires separate human approval before merge. Rose
returned DONE for exact implementation/sign-off SHA `9f18b8ba`. The external
Claude artifact mirror was explicitly waived as Gate 0 and remains pending; it
is the only cross-tool handoff item.

Canonical mirror input:

- HTML: `docs/dev-log/dashboard/capability-surface.html`
- absolute path: `/Users/z3437171/.codex/worktrees/arc1a-gaussian-reml-providers/docs/dev-log/dashboard/capability-surface.html`
- generator: `python3 tools/capability_ledger.py --write`
- verified HTML SHA-256: `58d786abe86cadc038020957d76fd386d6e245e99c87d62cd8581f28aa6d5d12`
- external target: `https://claude.ai/code/artifact/a1bf21a1-8c5a-495e-b0ee-1b91608a5ca2`

Do not report the external artifact as refreshed until Claude compares the
mirrored content or exported file against that exact hash.

## Goals / Mission

Keep the capability surface ledger-derived and honest. Arc 1a admits native
exact-Gaussian REML only for pure-`mu`, univariate `spatial()`, `animal()`, and
`relmat()` routes with an unlabelled intercept or independent one-slope shape,
constant `sigma ~ 1`, and no sigma random effect. The three promoted cells stop
at `inference_ready_with_caveats` over exact tested discrete domains.

## What Was Accomplished

- Added the bounded REML admission guard and all-provider rejection guards.
- Proved independent dense restricted-likelihood and representation parity.
- Retained 11,200 Totoro recovery fits and 14,000 coverage fits, with 21,000
  profiles and zero fit/profile failures.
- Promoted `mc-0287`, `mc-0299`, and `mc-0311` only after fresh
  Noether/Fisher/Pat D-43 review.
- Repaired REML boards, neighbouring documentation, ledger-derived outputs,
  Mission Control evidence links, and the tracked Markdown/HTML surface.
- Passed full `devtools::test()`, genuine `--as-cran` at 0 errors / 0 warnings /
  1 expected NOTE, pkgdown checks, ledger/board/runtime checks, hash read-back,
  and final Rose audit.
- Opened PR #780. No merge was performed.

Full evidence and exact claim boundaries are in
`docs/dev-log/after-task/2026-07-13-arc1a-gaussian-reml-providers.md`.

## Current Working State

- Working: branch is clean, committed, pushed, and represented by PR #780.
- In progress: the GitHub Ubuntu package check was still running at handoff
  preparation; local full package, `--as-cran`, and pkgdown gates are green.
- Blocked externally: only Claude can update/read back the external `a1bf21a1`
  artifact in the intended workflow.

## Key Decisions and Rationale

- `tau` is the structured covariance multiplier, not generally a node-level
  marginal SD when `diag(K) != 1`.
- Campaign evidence is discrete: spatial/relmat `M={8,16,32}`, animal fixed
  `M=8`, all with `n_each=20`; never rewrite these as inequality domains.
- Coverage is mildly non-nominal with upper-tail miss asymmetry and frequent
  zero-lower-bound slope profiles; `supported` is withheld.
- Ainv/pedigree/Q equivalence is deterministic-fixture evidence only; the
  campaign used coordinates/A/K.
- This arc does **not** cover sigma random/structured effects, labelled or
  multiple slopes, matched mean-plus-scale blocks, bivariate/non-Gaussian REML,
  fixed-effect REML profiles, estimated spatial range, or broad sparse-matrix
  geometries.

## Mission Control

| Repository | Branch / PR | State | What shipped | Next by leverage |
|---|---|---|---|---|
| drmTMB | `feature/arc1a-gaussian-reml-providers` / #780 | Rose DONE; pushed; no merge | Exact-Gaussian REML provider parity plus discrete-domain evidence | Claude mirrors tracked HTML and verifies exact hash |
| external capability artifact | `a1bf21a1` | PENDING, nonblocking under waiver | Nothing claimed refreshed yet | Import HTML, read back, compare SHA-256 |

## Landing State

The handoff gate found the active Arc 1a branch fully pushed, but also reported
358 pre-existing local branches with commits absent from their configured
upstreams. Those branches predate and are unrelated to Arc 1a; they are
protected user state and were not staged, pushed, deleted, or rewritten.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| drmTMB `feature/arc1a-gaussian-reml-providers` at signed implementation tip `9f18b8ba` | yes | yes | #780 open | LANDED on remote; merge requires separate approval |
| external Claude artifact `a1bf21a1` | n/a | no | n/a | CARRIED-OVER: Claude must mirror and verify; resume command below |
| 358 unrelated pre-existing local branches reported by `handoff_gate.sh` | mixed | no | mixed | CARRIED-OVER protected user state; out of Arc 1a scope; do not touch |

To reproduce the protected-branch inventory only, run
`/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh /Users/z3437171/.codex/worktrees/arc1a-gaussian-reml-providers`.

## Files Created / Modified

The Arc 1a branch changes these paths relative to `origin/main` (plus this
handoff and its `AGENTS.md` pointer):

```text
.gitattributes
AGENTS.md
NEWS.md
R/drmTMB.R
README.md
docs/design/168-gaussian-reml-first-slice.md
docs/design/199-native-reml-phylo-asymmetry-gap.md
docs/design/211-structured-reml-status.md
docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md
docs/dev-log/2026-07-13-next-arcs-codex-campaign-plan.md
docs/dev-log/after-task/2026-07-13-arc1a-gaussian-reml-providers.md
docs/dev-log/check-log.md
docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv
docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv
docs/dev-log/dashboard/capability-census/_master.tsv
docs/dev-log/dashboard/capability-census/_widget_data.json
docs/dev-log/dashboard/capability-census/gaussian.tsv
docs/dev-log/dashboard/capability-ledger/cells.tsv
docs/dev-log/dashboard/capability-ledger/evidence.tsv
docs/dev-log/dashboard/capability-ledger/transitions.tsv
docs/dev-log/dashboard/capability-surface.html
docs/dev-log/dashboard/capability-surface.md
docs/dev-log/dashboard/estimator-surface-conformance.tsv
docs/dev-log/dashboard/structured-re-ayumi-closeout-status.tsv
docs/dev-log/dashboard/structured-re-closeout-package.tsv
docs/dev-log/dashboard/structured-re-conversion-200-slices.tsv
docs/dev-log/dashboard/structured-re-finish-100-slices.tsv
docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv
docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv
docs/dev-log/dashboard/structured-re-scope-gate-status.tsv
docs/dev-log/handover/2026-07-13-arc1a-claude-handover.md
docs/dev-log/known-limitations.md
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/README.md
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/arc1a-cells.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/arc1a-seed-pool.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-artifact-hashes.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-campaign.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-fit-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-launch.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-raw.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-run-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-seed-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/profile-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-artifact-hashes.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-campaign.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-fit-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-launch.log
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-paired-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-raw.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-run-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-seed-manifest.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/recovery-summary.tsv
docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-providers/session-info.txt
docs/dev-log/team-improvements.md
man/drmTMB.Rd
tests/testthat/test-estimator-surface-conformance.R
tests/testthat/test-reml-scale-structured.R
tests/testthat/test-reml-structured-location.R
tests/testthat/test-structured-re-conversion-contracts.R
tools/capability_ledger.py
tools/run-arc1a-gaussian-reml-provider-campaign.R
tools/summarize-arc1a-gaussian-reml-provider-campaign.R
tools/tests/test_capability_ledger.py
tools/validate-mission-control.py
vignettes/includes/capability-ledger-family-map.md
```

## Next Immediate Steps

1. Read `AGENTS.md`, this handoff, and the after-task report. Do not rerun or
   reinterpret the completed campaign.
2. Open the canonical HTML at the absolute path above and import its exact
   contents into external artifact `a1bf21a1`.
3. Export/read back the mirrored artifact and compare its SHA-256 with
   `58d786abe86cadc038020957d76fd386d6e245e99c87d62cd8581f28aa6d5d12`.
4. Only after an exact match, update the external mirror status from PENDING and
   report the read-back evidence. Do not merge PR #780.

## Blockers / Open Questions

- Claude artifact write/read-back authority is external to this Codex session.
- PR #780 merge remains a separate Shinichi decision.

## Gotchas and Failed Approaches

- Do not use the HTML in the original main checkout; use the Arc 1a worktree
  path above or fetch PR #780 first.
- Do not infer a refreshed artifact merely because the local HTML opens.
- Do not broaden exact tested `M` sets into `M >= ...` claims.
- `profile-raw.tsv` has a schema-valid empty final `profile_warnings` field;
  the path-scoped `.gitattributes` rule preserves exact bytes.
- Issues #33, #714, #555, and #59 remain broader open work. Issue #147 closes
  only when PR #780 merges.

## How to Resume

From `/Users/z3437171/.codex/worktrees/arc1a-gaussian-reml-providers`, paste:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-13-arc1a-claude-handover.md + the AGENTS.md snapshot, then mirror capability-surface.html into artifact a1bf21a1 and verify the exact SHA-256. Do not merge PR #780."
```

