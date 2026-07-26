# Prepare-only Totoro approval packet — scalar A1 ML versus REML

## Request that will require fresh written approval

Run a future paired scalar-A1 ML-versus-REML profile/Wald coverage study on
Totoro only.  This file is a packet, not authorization and not a launcher.

## Frozen run contract

| Field | Contract |
| --- | --- |
| Scope | Gaussian iid scalar random-intercept SD only; three frozen A1 cells |
| Attempt unit | one generated outer dataset with both ML and REML retained |
| Maximum workers | 100 total live workers |
| Threads | `OPENBLAS_NUM_THREADS=1` |
| Output | unique run root, per-attempt shards, all failures retained |
| Provenance | immutable source snapshot, runner/helper/oracle hashes, installed tarball SHA-256 |
| Safety | atomic run lock, cleanup trap, worker-count check, append-safe merge |
| CI policy | never GitHub Actions and never GitHub artifacts |

## Required pre-launch evidence

1. Oracle receipt passes for ML and REML at every group count.
2. The six-arm local smoke is non-empty, paired, target-correct, and retains all
   statuses.
3. Source snapshot, installed package tarball, runner, helper, and oracle script
   hashes are recorded in the manifest.
4. The exact command, worker count, output root, expected wall time, and storage
   estimate are presented to Shinichi and approved in writing.

## Stop conditions

Do not launch if a lock already exists, the worker count exceeds 100, any
provenance hash is missing, an output root already contains campaign shards, the
first completed shard lacks both estimator rows, or the initial merged output
has duplicated `(cell_id, seed, attempt_id, estimator)` keys.

## Explicitly excluded

This packet does not authorize Arc D, endpoint-clamp interpretation, bootstrap
correction, public interval guidance, capability promotion, association work, or
any non-Gaussian or structured random-effect study.
