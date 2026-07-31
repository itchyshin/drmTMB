# Session Handoff: AOI-3R2 diagnostic smoke ready, not launched

Meta: 2026-07-31 · Codex · Association lane

## Critical Context

AOI-1’s full fixed-effect Bernoulli × ordinary-NB2 formula/newdata route is
merged through green PR #864. AOI-2 remains
`HOLD_NO_POINT_RECOVERY_CLAIM`. AOI-3 uncertainty is private and fail-closed:
there is no public `vcov()`, `confint()`, profile, standard-error, interval, or
capability claim.

AOI-3R1 retained output reduced to `AOI3R1_DIAGNOSTIC_INVALID` because valid
outer diagnostic payloads were absent from some `not_eligible` inner rows. It
must not be edited, reclassified, pooled, or treated as scientific evidence.

## What Was Accomplished

- Landed/pushed the class-wide AOI-3R payload-inheritance repair and a behavior
  test for valid-payload inheritance versus unknown outer failure.
- Froze the AOI-3R2 replacement manifest: 60 unique seeds, disjoint from
  AOI-3R1, with five formula classes, 15 outer and 45 scheduled inner attempts.
- Added a startup source-SHA gate that rejects mismatch before creating a result
  directory; a command-level negative control passed.
- Added explicit AOI-1 Bernoulli × ordinary-NB2 public-boundary tests showing
  `vcov()`, `confint()`, `profile()`, and prediction `se.fit` remain unavailable.

## Current Working State

- Working: plan-only AOI-3R2 execution preparation is complete.
- In progress: none.
- Waiting on owner decision: a fresh-seed local diagnostic smoke.

## Key Decisions & Rationale

- The replacement smoke is diagnostic completeness only, not a point-recovery,
  covariance, interval, coverage, or public inference gate.
- The manifest pins computational provenance to
  `4d2b1afac7c45bdef74b98487a16a69535db2b81`; the README requires a clean
  package/runner diff against that commit before any authorized invocation.
- Do not rebase, merge, or modify Lane B, Arc D, or foreign Association PR #854.
  `origin/main` is currently 34 commits ahead but has no overlap with the
  Association implementation, AOI runner, or Bernoulli × NB2 test files.

## Landing State

`handoff_gate.sh` was run. It reports the following declared carry-over and
foreign state.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| `codex/aoi2-drac-recovery` at `0e904c8d3` | yes | yes | none | CARRIED-OVER — awaiting the owner-approved AOI-3R2 local smoke |
| `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r1-local-diagnostic-smoke/` | no | no | none | CARRIED-OVER — immutable retained invalid output; do not change |
| `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r1-diagnostic-analysis/` | no | no | none | CARRIED-OVER — reducer analysis for retained invalid output; do not change |
| Other unpushed branches reported by `handoff_gate.sh` | foreign | foreign | foreign | PROTECTED — do not inspect, merge, clean, or attribute from this Association lane |

## Next Immediate Steps

1. Receive explicit owner authorization for AOI-3R2 local diagnostic smoke.
2. Run the preflight in the AOI-3R2 manifest README. It must pass before any
   result directory exists.
3. On a fresh immutable output root, run only the frozen manifest under the
   stated source SHA; retain all outer/inner rows and reduce with the AOI-3R1
   diagnostic reducer.
4. If the diagnostic completeness reducer fails, stop and write a receipt. If
   it passes, obtain separate authorization before any DRAC campaign or AOI-3
   calibration work.

## Blockers / Open Questions

The only action requiring new authority is the local AOI-3R2 smoke. Neither
the prior broad AOI approvals nor the failed AOI-3 smoke authorize this changed
diagnostic successor. DRAC remains unauthorized regardless of smoke outcome
until a later explicit approval.

## Gotchas & Failed Approaches

- Do not use `testthat::test_file()` without `devtools::load_all(".")`; it can
  exercise an older installed drmTMB package and produce stale parser errors.
- Do not invoke AOI-3R2 with the default current `HEAD` provenance. Follow the
  manifest README: verify the computational diff and set `AOI3_SOURCE_SHA` to
  the frozen code commit.
- An inner `not_eligible` row may inherit a valid outer payload, but a failure
  before a valid outer payload remains explicitly unknown and invalidates the
  diagnostic run.

## How to Resume

```sh
cd /Users/z3437171/.codex/worktrees/838f/drmTMB
git status --short
sed -n '1,220p' docs/dev-log/2026-07-31-aoi3r-revised-smoke-contract.md
sed -n '1,220p' docs/dev-log/simulation-artifacts/2026-07-31-aoi3r2-diagnostic-manifest/README.md
```

Then act only on a new owner authorization. Read the two AOI-3R1 retained
directories; do not alter their files.
