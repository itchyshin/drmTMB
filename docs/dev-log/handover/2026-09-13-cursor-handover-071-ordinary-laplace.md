# Session Handoff: 0.7.1 ordinary-RI Laplace parity repair

Meta: 2026-09-13 · from Codex · to Cursor

## Critical Context

You are Cursor, picking up the final CI repair for draft PR #1304, not restarting
the 0.7.1 parity programme. The scientific evidence, frozen source pins,
manifests, fixtures, targets, campaign denominators, and coverage receipts are
protected. The only OWED work is to make the existing branch pass its current
GitHub checks without weakening those boundaries.

## What Was Accomplished

- Added and evidenced the scalar `marginal = :Laplace` R-to-Julia route and the
  coupled NB2 location-scale bridge route.
- Completed the bounded four-fixture, 500-seed-per-fixture evidence programme;
  retained results and claim limits are in
  `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/`.
- Recertified the model-15 C17 compatibility receipt at commit `81e080176`.
- Separately, DRM.jl branding PR #768 was merged as `cdcbcfea`; its main
  Documenter deployment passed and the public full hero mark and compact
  navigation icon were byte-verified. This is DONE and is not work for this PR.

## Current Working State

- Working: PR #1304 is pushed at `81e080176ddf3d944e5dcf686fe2acaa127a7e28`.
- Blocked: its R-CMD-check run `34734561536` fails `source-tree tests (blind
  spot)` and all four Ubuntu release shards.
- Protected: no campaign rerun; do not alter source pins, manifests, fixtures,
  declared targets, caps, denominator, or coverage interpretation.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `codex/071-ordinary-laplace-bridge` at `81e080176` | yes | yes | #1304 draft/open | CARRIED-OVER: CI repair required |
| DRM.jl `cdcbcfea` | yes | yes | #768 merged | LANDED |

FINDINGS-OF-RECORD: none beyond the branch receipts already linked above.

## Exact CI Findings

- `source-tree tests (blind spot)`: failed in run `34734561536`.
- Release shard 1 failures are concentrated in
  `tests/testthat/test-071-four-fixture-summary.R`, including its fail-closed
  fixture-absence, source-staging, denominator, deterministic factory, attempt,
  worker, reconciliation, and coverage-summary checks.
- Release shard 2 also fails the Julia capability comparison artifact registry
  check in `test-julia-gate-vs-engine.R:176`.
- The C17 compatibility check itself passed in shard 1: `C17 current-source
  compatibility PASS`. Do not relabel this as a C17 failure.

## Next Immediate Steps

1. Run lane preflight, inspect `git status`, and classify this handoff against
   current origin state as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`.
2. Fetch the failed-run logs and reproduce the smallest failing source-tree or
   registry test locally. Start with:
   `gh run view 34734561536 --repo itchyshin/drmTMB --log-failed`.
3. Repair the staged-source assumptions or generated registry artifact, not the
   frozen evidence contract; rerun the affected tests and then the project gate.
4. Commit and push only the scoped repair to `codex/071-ordinary-laplace-bridge`.
   Keep PR #1304 draft until CI is green. Do not merge or release.

## Gotchas

- The direct drmTMB checkout contains foreign untracked `graft/`; do not stage,
  remove, or use it.
- The repository has many active unrelated branches and worktrees. Do not use
  broad `git add`, cleanup, reset, or worktree removal.
- A previous local docs build for DRM.jl had a missing asset because
  DocumenterVitepress only publishes filenames containing `logo` or `favicon`.
  That is resolved on DRM.jl main and unrelated to drmTMB CI.

## How to Resume

Working directory:
`/Users/z3437171/local-scratch/lanes/drmTMB-071-ordinary-laplace-bridge`

Run:

```sh
/Users/z3437171/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/Dropbox/Github\ Local/drmTMB
git status --short
gh run view 34734561536 --repo itchyshin/drmTMB --log-failed
```

Use Cursor for the bounded CI/source-artifact repair. Use the live R/TMB and
Julia toolchain only when the failing test demands it; do not resubmit the
campaign.
