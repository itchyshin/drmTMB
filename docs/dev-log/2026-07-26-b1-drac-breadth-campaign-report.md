# B1 DRAC breadth validation — campaign report and receipt

**Status:** execution-only campaign complete; independent review withholds all
capability, ledger, public, default, recovery, and inference claims.

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

## DRAC receipt state and execution result

Fir was reachable through the existing authenticated ControlMaster. The
campaign directory is isolated at
`/project/def-snakagaw/snakagaw/drmTMB-b1-breadth-399cba13/`. Several
contained preflight repairs were retained in job logs. The final
preflight passed for source `061c2891cdc617113334d128425228f4b4145753`, a
clean source tree, installed-DLL SHA
`fe8af02215b4f96491dbe0b0675659f778e48fdf84635502782ae09e8d4abc03`, R 4.4.0,
and TMB 1.9.21. A B1-local R-4.4 `ape` 5.8.1 install repaired four
phylogenetic fixture routes without modifying the read-only dependency base.

The final array used 960 single-CPU tasks (`51292149`) after a 16-shard
benchmark observed 7--15 seconds and about 198--269 MB RSS per full-size task.
All 960 tasks completed with exit code zero. The original full result root is
retained. A multiline Beta error in task 41 was caught by the structural audit,
then a repaired worker replayed only that task in a complete copied
`full-replay` root. The final replay has 960 shards of ten rows each:
9,600 attempts = 9,599 completed fits + one retained Beta response-boundary
fit error. Aggregated raw and per-cell/rung evidence live at
`/project/def-snakagaw/snakagaw/drmTMB-b1-breadth-399cba13/full-replay/summary/`.

The exact Fir source is also banked locally as the incremental bundle
`/private/tmp/b1-fir-061c2891.bundle` (SHA-256
`96cf716801512b2cb24493e741fa32b137862e6a555b11e69e6badf306ae89ff`). It
requires the recorded `origin/main` base `03e19ba54801bbc0d9aa611f81a66800fb77c062`
and contains the final source tag `061c2891cdc617113334d128425228f4b4145753`.

## Next gate

Independent inference review found no truth, bias, interval, coverage,
comparator, or Monte Carlo uncertainty quantity in B1, so it withholds every
recovery or inference claim. Systems review initially identified missing
canonical-map and replay provenance checks. The final post-hoc gate passed:
manifest SHA
`08d92b25c03b58afbfe0281e9ab125c82f642cb812df430b7160bdeb5ac5b972`,
9,600 bound rows, 960 task provenance files, and exactly one permitted replay
difference—task 41's newline-normalization-only error serialization. The
campaign is therefore closed as execution evidence only.
