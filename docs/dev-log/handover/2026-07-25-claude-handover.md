# Session Handoff: Arc 7B/8 cleanup and next-days transfer to Claude

Meta: 2026-07-25 · from Codex · target Claude · multi-lane transfer

## Critical Context

This is a multi-lane repository. Do not collapse the lanes into one “latest”
task, and do not modify the dirty root checkout. The durable overview is
`docs/dev-log/2026-07-25-next-days-overview.md` on draft PR #835; it is not
yet in `main`. The only active merge candidate that changes method plumbing is
draft PR #832, whose final Ubuntu package check was running when this handover
was written.

Never merge PR #828. PR #829 belongs to the separate eta/bivariate lane and
is currently conflict-dirty against `main`; do not resolve it in parallel.

## Goals and mission

Finish the already-built, reviewable cleanup without widening statistical
claims: preserve the known-sampling-covariance `meta_V(V = V)` contract,
maintain the Arc 7B/8 negative-evidence and engineering-feasibility boundary,
and restore a trustworthy test baseline before choosing another substantive
method arc. `drmTMB` remains a univariate/bivariate TMB package; higher
dimensional work belongs elsewhere.

## What Was Accomplished

- PR #833, “Julia xfam extractors,” merged to `main` at `2e5e224a`. It makes
  the fixed-only (`u = 0`) fitted/residual boundary explicit and leaves
  coefficient/variance-covariance extraction unsupported.
- PR #831, the staged eta bootstrap handoff document, merged to `main` at
  `e4f392f3`. It changes no eta/bivariate implementation.
- Arc 8 PR #832 received a one-line semantic repair in `a19911fe`: the generic
  all-attempt merge no longer overwrites the caller-owned
  `meta_v_lss_arc8` surface label. The focused
  `test-phase18-meta-v-lss-runner.R` test passed locally.
- Draft PR #835 records the near-term cleanup order: Arc 8 merge when green,
  a separate seven-test estimator-surface-anchor hygiene PR, then one
  independent substantive lane.
- The seven failures in `test-estimator-surface-conformance.R` were reproduced
  on untouched `origin/main`. They are stale line-anchor baseline debt, not a
  regression from the Julia extractor work.

## Current Working State

- **Working:** this handover branch is documentation-only, based on
  `origin/main` at `e4f392f3`.
- **In progress:** PR #832 is draft, has no comments or review blockers, and
  has passed `os-matrix`; `ubuntu-latest (release)` is running. Do not mark it
  ready or merge until that check succeeds and the live merge state is clean.
- **In progress:** PR #835 is draft, has no comments or review blockers, and
  its Ubuntu package check is running.
- **Blocked / parked:** PR #829 is conflict-dirty. Leave it to the eta/bivariate
  owner. PR #828 remains explicitly excluded.
- **Foreign carried state:** the root checkout on
  `claude/handover-freshness-0718` has 65 uncommitted files; the legacy
  `codex/arc6-6-bernoulli-nb2-plan` branch has two unpushed commits. Neither
  belongs to this cleanup. Do not reset, clean, merge, or amend either lane.

## Key Decisions and Rationale

- Arc 8 is limited to target-wise direct-SD profile/bootstrapping engineering
  feasibility. It does not establish recovery, coverage, calibrated inference,
  a capability tier, or authority for Totoro/DRAC work.
- The baseline anchor repair must be isolated from method work: it should
  compare the seven current source locations with their TSV fixture, change no
  estimator behaviour, test the exact file first, then run the full suite.
- Eta/bivariate work has a distinct owner. A documentation handoff may merge
  when clean, but no parallel implementation or conflict resolution is allowed
  from this lane.
- Any future recovery/coverage/type-I campaign needs a written design and
  explicit compute approval; run it on Totoro or DRAC, never GitHub Actions.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `main` `e4f392f3` | yes | yes | #831 merged | LANDED |
| Julia xfam `2e5e224a` | yes | yes | #833 merged | LANDED |
| `codex/arc8-meta-v-finite-intervals` `a19911fe` | yes | yes | #832 draft, Ubuntu CI running | CARRIED-OVER: wait for two green required checks, clean merge state, and no blocking review/comment; then follow the standing merge instruction. |
| `codex/next-days-overview` `90dd40cd` | yes | yes | #835 draft, Ubuntu CI running | CARRIED-OVER: documentation-only overview; review and land separately after its checks are green. |
| `codex/fix-bivariate-nav-dup` `33b25407` | yes | yes | #829 ready but dirty | CARRIED-OVER: eta/bivariate owner resolves or parks it; do not edit here. |
| `claude/handover-freshness-0718` | partial | no | none | CARRIED-OVER FOREIGN: 65 uncommitted files; resume only in its original checkout after inspecting its own handover. |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | no (2 commits) | none | CARRIED-OVER FOREIGN: do not modify; resume only on that branch after explicit scope confirmation. |
| `handover/2026-07-25-claude` | pending this PR | pending this PR | to be opened | CARRIED-OVER: the transfer itself; merge only after human review. |

## Files Created or Modified

This handover branch changes exactly:

- `AGENTS.md` — prepended multi-lane snapshot pointer.
- `docs/dev-log/handover/2026-07-25-claude-handover.md` — this durable transfer.

Related committed/pushed work to read, but not present on this branch:

- PR #832: `inst/sim/run/sim_run_meta_v_lss_smoke.R` and
  `docs/dev-log/check-log.md`.
- PR #835: `docs/dev-log/2026-07-25-next-days-overview.md`.
- Merged PR #833: `R/julia-bridge.R`, its tests/docs, and
  `docs/dev-log/after-task/2026-07-24-arc9-julia-xfam-extractor-repair.md`.

## Mission Control

| Lane | Current state | Evidence / boundary | Next by leverage |
| --- | --- | --- | --- |
| Arc 8 meta-`V` (#832) | Draft; macOS green, Ubuntu release running | local runner test green; feasibility only | Recheck live CI/review/merge state; merge only if clean and all required checks pass. |
| Baseline hygiene | Not started | Seven stale line-anchor failures reproduced on untouched main | Small dedicated fixture/anchor PR, then full suite. |
| Next-days overview (#835) | Draft; macOS green, Ubuntu release running | Documentation only | Review/land separately after CI; use it as the planning source. |
| Eta/bivariate (#829) | Ready but dirty | Separate owner and scope | Do not resolve here. |
| Julia xfam (#833) | Merged | Fixed-only fitted/residuals defined; `coef()`/`vcov()` unsupported | Design DRM.jl parity only after baseline hygiene and fresh approval. |
| Foreign AGHQ/REML | Dirty local root | 65 uncommitted files | Do not touch; resume in its own lane only. |

## Next Immediate Steps

1. In a fresh clean checkout, read this handover, the `AGENTS.md` snapshot,
   [Arc 8 handover](2026-07-24-arc7b-meta-v-heterogeneity-ladder.md),
   [staged eta handover](2026-07-24-codex-staged-eta-handover.md), and the
   overview on PR #835.
2. Query PR #832 live. If both required checks are successful, merge state is
   `CLEAN`, and there are no blocking reviews/comments, convert it from draft
   and merge it. If a check fails, inspect the exact failure and report it;
   do not merge.
3. Query #835 separately; keep its merge decision separate from Arc 8.
4. Open the isolated baseline-hygiene work only after the merge state is
   settled. Do not bundle it with Arc 8, #829, or DRAC work.
5. Before any future method claim or compute request, ask Rose for a bounded
   audit/review. For a new model or estimand, write symbolic alignment first.

## Plans / Roadmap Beyond the Immediate Steps

1. Restore the baseline test signal (seven stale anchors).
2. Select one independent substantive lane after that: a design-only DRM.jl
   counterpart to the fixed-only Julia xfam contract is the clean candidate
   while eta/bivariate remains owned elsewhere.
3. Keep meta-`V` at its explicit boundary until a pre-registered calibration or
   recovery design is reviewed and compute approval is explicit.

## Blockers and Open Questions

- PR #832 and #835 cannot be merged yet because their Linux release checks were
  still running at handover time.
- The seven estimator-surface failures need a source-vs-fixture audit before
  asserting they are all purely stale anchors.
- A future DRM.jl parity task is cross-repository and needs a fresh goal; it is
  not authorized by this cleanup handover.

## Gotchas and Failed Approaches

- Do not infer interval validity from Arc 8's finite engineering fixtures.
- Do not use GitHub Actions for a simulation/recovery/coverage campaign.
- Do not “fix” the red baseline by skipping or weakening the seven tests.
- Do not trust the root checkout as a clean starting point; use a new worktree.
- Do not merge #828, and do not resolve #829 as a side effect of this transfer.

## How to Resume

Claude should read `AGENTS.md` first, then this handover and the linked
documents. Claude may plan, refactor, write, and run logic/CI checks; use a
live-toolchain-capable session for real R/TMB fits, package checks, rendering,
or any approved compute campaign. Before making a public claim, spawn Rose for
a bounded systems audit.

Run this from the drmTMB repository root in an authenticated terminal:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-25-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```
