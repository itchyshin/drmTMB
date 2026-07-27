# Arc 6 F4R DRAC execution receipt — high-information alpha Wald screen

**Authorization:** the owner authorized this one F4R campaign on 2026-07-27.
It authorizes the private runner and one fixed 16-shard / 16,000-attempt
submission only. It does not authorize a retry, resubmission, F5, public API,
capability movement, or public inference claim.

## Immutable source and scope

| Item | Receipt |
| --- | --- |
| source SHA | `18c37bbc8e472e79272056ce90e12a18f2379ff4` |
| source snapshot | `/home/snakagaw/arc6-f4r-18c37bbc8/source` |
| private F4R manifest adapter | `tools/run-arc6-bernoulli-nbinom2-f4r-private.R` |
| private shard worker | `tools/run-arc6-bernoulli-nbinom2-f4r-worker.R` |
| sandwich blob | `d090f67b74bf5dfee6baa4396a8f45a3c977d6fd` |
| fixture blob | `d36b02b2ad470e641843d4f751ee1c998e6922bf` |
| design contract | `docs/dev-log/2026-07-27-arc6-f4r-high-information-design.md` |

The source snapshot is a clean `git archive` of the named SHA. The packet
writes `F4R-SOURCE-SHA.txt` and `F4R-SOURCE-BLOBS.tsv` into that snapshot before
any package build or refit. Each worker checks these receipts, the frozen
manifest, and the packet library path before its first attempt.

## Host, resources, and fixed submission

| Item | Receipt |
| --- | --- |
| DRAC cluster | Rorqual |
| account | `def-snakagaw_cpu` |
| array | exactly `1-16` (one cell per task) |
| time per task | 12 hours |
| CPUs per task | 1 |
| memory per task | 8 GB |
| scratch shards | `/scratch/snakagaw/arc6-f4r-18c37bbc8/shards` |
| durable results | `/home/snakagaw/arc6-f4r-18c37bbc8/results` |
| packet/log root | `/home/snakagaw/arc6-f4r-18c37bbc8/packet`, `/home/snakagaw/arc6-f4r-18c37bbc8/logs` |

This resource choice is anchored to the authenticated F4 Rorqual array
`17508492`: 1 CPU and 8 GB per shard, with the slowest completed shard taking
9 h 16 m. The 12-hour F4R limit leaves ordinary execution margin without the
former 48-hour reservation. `OPENBLAS_NUM_THREADS` and `OMP_NUM_THREADS` are
both one.

Before submission, the packet must prove that all 16 persistent shard paths
are absent. The wrapper copies a scratch shard to its corresponding durable
path after the worker exits; it never overwrites a durable shard. A terminal
attempt status is retained and the next assigned seed continues. Any protocol
quarantine, malformed all-attempt table, infrastructure interruption, or
resource exhaustion retains evidence and ends the authorized campaign: no
retry, top-up, or replacement submission is permitted.

## Launch and post-launch boundary

The wrapper uses `module load r/4.4.0`, the packet-local R library, and
`sbatch --account=def-snakagaw_cpu --array=1-16 --time=12:00:00
--cpus-per-task=1 --mem=8G`. It records the returned job ID and writes it into
the packet before monitoring begins.

After all shards finish, retain the raw all-attempt records, manifests, source
and blob receipts, session information, scheduler logs, and `RUN-COMPLETE.txt`
receipts. F4R is then reviewed as a fresh PASS/FAIL calibration screen. A PASS
would still require separate F5 approval before any public `vcov()` or
`confint()` exposure.
