# B1 DRAC breadth validation — campaign report and receipt

**Status:** execution in progress; no capability, ledger, public, or default claim is authorized by this report.

## Scope and boundaries

B1 is an inferential-validation census of sixteen scalar `sd()`/fixed-parameter
routes across the fitted model surface.  It has three predeclared information
rungs (`low`, `medium`, `high`), 200 independently seeded replicates per
cell/rung, and ten replicates per immutable shard: 9,600 attempts in 960 full
array tasks.  The selected cells are `mc-0005`, `mc-0031`, `mc-0059`,
`mc-0074`, `mc-0229`, `mc-0251`, `mc-0270`, `mc-0364`, `mc-0388`, `mc-0423`,
`mc-0438`, `mc-0460`, `mc-0495`, `mc-0511`, `mc-0641`, and `mc-0667`.

This campaign does not modify bootstrap methods, association, missing-response
work, Arc D, the capability ledger, defaults, NEWS, or public documentation.
Each cell will retain its own evidence and diagnostic profile; `pdHess` is not
treated as a universal pass criterion for routes deliberately fitted with
`se = FALSE`.

## Frozen local receipt

- Worktree: `/private/tmp/drmtmb-b1-drac-breadth`
- Source commit: `399cba13d8d127c44283e72cadde282627700c29`
- Parent B1 manifest/adapter commit: `416f107c`
- Full manifest: 960 tasks and 9,600 attempts; seeds are deterministic and
  globally unique.
- Array policy: one CPU per task and a live throttle of at most
  `min(1000, benchmarked capacity, account/QoS allowance)`.
- Worker, dispatch planner, and aggregator are source-tree tools.  The
  aggregator fails closed on a missing or unexpected task file, duplicate
  replicate, malformed shard, or incomplete cell/rung denominator.

## Local smoke receipt

On 2026-07-26, one `low`-design fit was executed for each of the 16 selected
cells through the same worker used for DRAC.  All sixteen returned a retained
`fit_completed` row with optimizer convergence `0`.  This establishes runner
and fixture viability only; it is not a recovery, interval, or promotion
verdict.  Raw local smoke files are retained outside git at
`/tmp/b1-local-smoke-run/`.

## DRAC receipt state

Fir was reachable through the existing authenticated ControlMaster. The
campaign directory is isolated at
`/project/def-snakagaw/snakagaw/drmTMB-b1-breadth-399cba13/`.  A standalone
source checkout was materialized from a git bundle and verified clean at the
frozen source SHA. Compute-node preflight job `51289136` was submitted and is
pending scheduler priority. It performs no simulation task. The preflight must
certify the standalone source SHA, clean tree, R/TMB environment, and compiled
package before the smoke array or full array is eligible for submission.

## Next gate

When the standalone checkout is clean at `399cba13`, submit exactly one
compute-node preflight job.  Only after its receipt and the full B1 smoke
aggregation are verified should the resource benchmark determine the live
array throttle.  The subsequent full-array aggregator runs only after all
expected shard rows are present; individual task failures remain retained
evidence rather than being deleted or rerun silently.
